import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/job_link.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/admin_support_provider.dart';
import 'package:dj_tilbud_app/features/chat/presentation/widgets/chat_message_input.dart';

const _kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// The admin-side view of a single DJTILBUD support thread (mobile Support tab). Reads/sends via the
/// web-app admin endpoints. Own-ness is by sender_type — the admin ('admin') is "us" (right side).
class AdminSupportThreadScreen extends ConsumerStatefulWidget {
  const AdminSupportThreadScreen({super.key, required this.thread});

  final AdminSupportThread thread;

  @override
  ConsumerState<AdminSupportThreadScreen> createState() =>
      _AdminSupportThreadScreenState();
}

class _AdminSupportThreadScreenState
    extends ConsumerState<AdminSupportThreadScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;
  XFile? _pendingImage;

  // Composer "@" job picker: the active query + the index of its "@".
  String? _mentionQuery;
  int _mentionStart = -1;
  String _mentionSearchQuery = '';
  Timer? _mentionDebounce;

  int get _conversationId => widget.thread.id;
  String get _recipientUserId => widget.thread.userId ?? '';
  String get _myUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    // Also detected via the TextField's onChanged (hot-reload-proof), but the
    // listener additionally catches caret moves.
    _controller.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminThreadMessagesProvider(_conversationId).notifier)
          .markRead();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onComposerChanged);
    _mentionDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _pendingImage = picked);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pendingImage;
    if ((text.isEmpty && image == null) || _sending) return;
    setState(() => _sending = true);

    final notifier = ref.read(
      adminThreadMessagesProvider(_conversationId).notifier,
    );

    String? attachmentUrl;
    if (image != null) {
      try {
        attachmentUrl = await notifier.uploadImage(
          userId: _myUserId,
          filePath: image.path,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billedet kunne ikke uploades. Prøv igen.'),
          ),
        );
        return;
      }
    }

    final err = await notifier.send(text, attachmentUrl: attachmentUrl);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _controller.clear();
      setState(() {
        _mentionQuery = null;
        _mentionStart = -1;
        _pendingImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  // Updates the "@" mention query from the composer's text + caret.
  void _onComposerChanged() {
    final sel = _controller.selection;
    final text = _controller.text;
    // Fall back to end-of-text when the selection isn't reported yet (can happen
    // when this runs from TextField.onChanged before the caret settles), so "@"
    // typed at the end is still detected.
    final caret =
        (sel.isValid && sel.baseOffset >= 0)
            ? sel.baseOffset.clamp(0, text.length)
            : text.length;
    final upto = text.substring(0, caret);
    final at = upto.lastIndexOf('@');
    if (at == -1) return _setMention(null, -1);
    final between = upto.substring(at + 1);
    if (between.contains(RegExp(r'\s'))) return _setMention(null, -1);
    if (RegExp(r'^(job|extjob):\d+$').hasMatch(between)) {
      return _setMention(null, -1);
    }
    _setMention(between, at);
  }

  void _setMention(String? query, int start) {
    if (query == _mentionQuery && start == _mentionStart) return;
    setState(() {
      _mentionQuery = query;
      _mentionStart = start;
    });
    // Debounce the actual search so we don't fire one request per keystroke.
    _mentionDebounce?.cancel();
    if (query == null) {
      setState(() => _mentionSearchQuery = '');
      return;
    }
    _mentionDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _mentionSearchQuery = query);
    });
  }

  void _insertJobToken(LinkableJob job) {
    final text = _controller.text;
    final caret = _controller.selection.baseOffset.clamp(0, text.length);
    if (_mentionStart < 0 || _mentionStart > text.length) return;
    // Never let the prefix/suffix slices overlap if the caret moved before "@".
    final start = _mentionStart < caret ? _mentionStart : caret;
    final newText =
        '${text.substring(0, start)}@${job.ref} ${text.substring(caret)}';
    final newCaret = start + job.ref.length + 2; // "@" + ref + trailing space
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    setState(() {
      _mentionQuery = null;
      _mentionStart = -1;
    });
  }

  void _showFullImage(String url) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              alignment: Alignment.center,
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }

  void _copyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.message));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Besked kopieret'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReactionBar(ChatMessage msg) {
    final _c = DSTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DSSpacing.s3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        _kQuickReactions
                            .map(
                              (e) => InkWell(
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  ref
                                      .read(
                                        adminThreadMessagesProvider(
                                          _conversationId,
                                        ).notifier,
                                      )
                                      .toggleReaction(msg.id, e);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                if (msg.message.isNotEmpty) ...[
                  Divider(height: 1, color: _c.border.subtle),
                  ListTile(
                    leading: Icon(Icons.copy, color: _c.text.secondary),
                    title: const Text('Kopiér besked'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _copyMessage(msg);
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final async = ref.watch(adminThreadMessagesProvider(_conversationId));

    // Resolve the job-ref tokens across the (non-system) messages so bubbles
    // render chips instead of raw "@job:123".
    final refs = <String>{};
    for (final m in async.valueOrNull?.messages ?? const <ChatMessage>[]) {
      if (m.isSystemMessage) continue;
      refs.addAll(extractJobRefs(m.message));
    }
    final refsCsv = (refs.toList()..sort()).join(',');
    final jobLinks =
        refsCsv.isEmpty
            ? const <String, JobLinkResolution>{}
            : ref.watch(adminJobLinkResolutionsProvider(refsCsv)).valueOrNull ??
                const {};

    return Scaffold(
      backgroundColor: _c.bg.surface,
      appBar: AppBar(
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread.userName,
                    style: DSTextStyle.headingSm.copyWith(
                      color: _c.text.primary,
                    ),
                  ),
                  Text(
                    'Support',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => Center(
                    child: Text(
                      'Kunne ikke hente beskeder',
                      style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
                    ),
                  ),
              data:
                  (data) => _MessageList(
                    data: data,
                    myId: myId,
                    jobLinks: jobLinks,
                    onReact: _showReactionBar,
                    onImageTap: _showFullImage,
                  ),
            ),
          ),
          if (_mentionQuery != null)
            _AdminMentionPicker(
              results:
                  ref
                      .watch(
                        adminLinkableJobsProvider(
                          '$_recipientUserId|$_mentionSearchQuery',
                        ),
                      )
                      .valueOrNull ??
                  const [],
              recipientName: widget.thread.userName,
              onSelect: _insertJobToken,
            ),
          if (_pendingImage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4,
                DSSpacing.s2,
                DSSpacing.s2,
                0,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    child: Image.file(
                      File(_pendingImage!.path),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s2),
                  Expanded(
                    child: Text(
                      'Billede vedhæftet',
                      style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: _c.text.muted),
                    onPressed:
                        _sending
                            ? null
                            : () => setState(() => _pendingImage = null),
                  ),
                ],
              ),
            ),
          ChatMessageInput(
            controller: _controller,
            focusNode: _focusNode,
            isSending: _sending,
            onSend: _send,
            onAttach: _pickImage,
            onChanged: (_) => _onComposerChanged(),
            hint: 'Svar som DJTILBUD…',
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.data,
    required this.myId,
    required this.jobLinks,
    required this.onReact,
    required this.onImageTap,
  });

  final AdminThreadData data;
  final String? myId;
  final Map<String, JobLinkResolution> jobLinks;
  final void Function(ChatMessage) onReact;
  final void Function(String) onImageTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    // Hide system messages (the auto "Velkommen til DJTILBUD" greeting): the admin
    // IS the team, so a musician-facing welcome shouldn't appear on the admin side.
    final messages = data.messages.where((m) => !m.isSystemMessage).toList();
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Ingen beskeder endnu',
          style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s3,
      ),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[messages.length - 1 - i];
        // The admin (this side) is 'admin'; the user's messages are 'dj'/'musician'.
        final isOwn = msg.senderType == 'admin';
        final reactions =
            data.reactionsByMessage[msg.id] ?? const <AdminReaction>[];
        return _Bubble(
          message: msg,
          isOwn: isOwn,
          reactions: reactions,
          jobLinks: jobLinks,
          onLongPress: () => onReact(msg),
          onImageTap: onImageTap,
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isOwn,
    required this.reactions,
    required this.jobLinks,
    required this.onLongPress,
    required this.onImageTap,
  });

  final ChatMessage message;
  final bool isOwn;
  final List<AdminReaction> reactions;
  final Map<String, JobLinkResolution> jobLinks;
  final VoidCallback onLongPress;
  final void Function(String) onImageTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final bg = isOwn ? _c.brand.primary : _c.bg.inputBg;
    final fg = isOwn ? _c.brand.onPrimary : _c.text.primary;
    final hasImage = message.attachmentUrl != null;
    final hasText = message.message.isNotEmpty;
    return Column(
      crossAxisAlignment:
          isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  Padding(
                    padding: EdgeInsets.only(bottom: hasText ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => onImageTap(message.attachmentUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 220,
                            maxHeight: 260,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: message.attachmentUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, __) => Container(
                                  width: 180,
                                  height: 180,
                                  color: _c.bg.canvas,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasText)
                  _AdminFormattedText(
                    text: message.message,
                    baseStyle: DSTextStyle.bodyMd.copyWith(color: fg),
                    jobLinks: jobLinks,
                  ),
              ],
            ),
          ),
        ),
        if (reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 4,
              children:
                  _summarize(reactions).entries
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _c.bg.inputBg,
                            borderRadius: BorderRadius.circular(DSRadius.pill),
                            border: Border.all(color: _c.border.subtle),
                          ),
                          child: Text(
                            '${e.key} ${e.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
      ],
    );
  }

  Map<String, int> _summarize(List<AdminReaction> reactions) {
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return counts;
  }
}

/// Renders a message body, turning `@job:`/`@extjob:` tokens into chips. Admin
/// chips are display-only (the mobile app has no admin job-detail screen), so
/// they're not tappable — they just show the reference clearly instead of the
/// raw token.
class _AdminFormattedText extends StatelessWidget {
  const _AdminFormattedText({
    required this.text,
    required this.baseStyle,
    required this.jobLinks,
  });

  final String text;
  final TextStyle baseStyle;
  final Map<String, JobLinkResolution> jobLinks;

  @override
  Widget build(BuildContext context) {
    if (!jobRefRegExp.hasMatch(text)) {
      return Text(text, style: baseStyle);
    }
    final spans = <InlineSpan>[];
    int i = 0;
    for (final m in jobRefRegExp.allMatches(text)) {
      if (m.start > i) {
        spans.add(TextSpan(text: text.substring(i, m.start)));
      }
      final ref = '${m.group(1)}:${m.group(2)}';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AdminJobChip(
            ref: ref,
            resolution: jobLinks[ref],
            baseColor: baseStyle.color,
          ),
        ),
      );
      i = m.end;
    }
    if (i < text.length) {
      spans.add(TextSpan(text: text.substring(i)));
    }
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

class _AdminJobChip extends StatelessWidget {
  const _AdminJobChip({
    required this.ref,
    required this.resolution,
    this.baseColor,
  });

  final String ref;
  final JobLinkResolution? resolution;
  final Color? baseColor;

  String _label() {
    final parts = ref.split(':');
    final id = parts.length > 1 ? parts[1] : '';
    return ref.startsWith('extjob:') ? '#E$id' : '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final res = resolution;
    final pending = res == null;
    // Admins can open any existing job; a resolved-but-missing row reads muted.
    final exists = res?.accessible == true;
    final color =
        pending
            ? (baseColor ?? _c.text.primary)
            : exists
            ? _c.brand.primaryActive
            : _c.text.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        _label(),
        style: DSTextStyle.bodyMd.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// The composer "@" job picker for the admin thread, shown above the input.
/// Each option warns when the DJ/musician in the thread can't see that job.
class _AdminMentionPicker extends StatelessWidget {
  const _AdminMentionPicker({
    required this.results,
    required this.recipientName,
    required this.onSelect,
  });

  final List<LinkableJob> results;
  final String recipientName;
  final void Function(LinkableJob) onSelect;

  static const _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'maj',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  String _label(LinkableJob job) {
    final fallback = job.kind == 'extjob' ? 'Opgave' : 'Job';
    final ev =
        (job.eventType != null && job.eventType!.isNotEmpty)
            ? job.eventType!
            : fallback;
    if (job.date != null) {
      final d = DateTime.tryParse(job.date!);
      if (d != null) return '$ev · ${d.day}. ${_months[d.month - 1]}';
    }
    return ev;
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final decoration = BoxDecoration(
      color: _c.bg.surface,
      border: Border(top: BorderSide(color: _c.border.subtle)),
    );
    // Always render the container while "@" is active so it's clear the picker is
    // alive — even when a query matches no jobs.
    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Ingen jobs matcher — skriv et event eller job-id efter @',
          style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: decoration,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: results.length,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: _c.border.subtle),
        itemBuilder: (context, i) {
          final job = results[i];
          final notVisible = job.visibleToRecipient == false;
          return InkWell(
            onTap: () => onSelect(job),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(job),
                    style: DSTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${job.ref}',
                    style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
                  ),
                  if (notVisible) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⚠ Ikke synlig for $recipientName',
                      style: DSTextStyle.labelSm.copyWith(
                        color: _c.state.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
