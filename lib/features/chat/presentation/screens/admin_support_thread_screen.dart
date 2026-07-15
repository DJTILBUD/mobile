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
import 'package:dj_tilbud_app/shared/widgets/conversation_avatar.dart';

const _kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Route args: the thread plus an optional message to jump to (set when the admin tapped a search
/// result in the support list). The router accepts a bare [AdminSupportThread] too, for back-compat.
class AdminSupportThreadArgs {
  const AdminSupportThreadArgs({required this.thread, this.initialMessageId});
  final AdminSupportThread thread;
  final int? initialMessageId;
}

/// The admin-side view of a single DJTILBUD support thread (mobile Support tab). Reads/sends via the
/// web-app admin endpoints. Own-ness is by sender_type — the admin ('admin') is "us" (right side).
class AdminSupportThreadScreen extends ConsumerStatefulWidget {
  const AdminSupportThreadScreen({
    super.key,
    required this.thread,
    this.initialMessageId,
  });

  final AdminSupportThread thread;

  /// A message to scroll to + flash on open (from a tapped search result).
  final int? initialMessageId;

  @override
  ConsumerState<AdminSupportThreadScreen> createState() =>
      _AdminSupportThreadScreenState();
}

class _AdminSupportThreadScreenState
    extends ConsumerState<AdminSupportThreadScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  /// The admin message being edited; the composer rewrites it instead of sending.
  ChatMessage? _editing;
  XFile? _pendingImage;

  // Composer "@" job picker: the active query + the index of its "@".
  String? _mentionQuery;
  int _mentionStart = -1;
  String _mentionSearchQuery = '';
  Timer? _mentionDebounce;

  // In-thread search.
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  List<int> _matchIds = const []; // matching message ids, chronological
  int _matchCursor = 0;

  // Jump-to-message (search hits + the tapped-from-list target).
  int? _flashId;
  final Map<int, GlobalKey> _msgKeys = {};
  bool _didInitialJump = false;

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
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _searchTerm = '';
        _matchIds = const [];
        _flashId = null;
      }
    });
  }

  void _onSearchChanged(String v) {
    final term = v.trim();
    final msgs =
        ref
            .read(adminThreadMessagesProvider(_conversationId))
            .valueOrNull
            ?.messages ??
        const <ChatMessage>[];
    final lower = term.toLowerCase();
    final ids =
        term.isEmpty
            ? const <int>[]
            : msgs
                .where(
                  (m) =>
                      !m.isSystemMessage &&
                      m.message.toLowerCase().contains(lower),
                )
                .map((m) => m.id)
                .toList();
    setState(() {
      _searchTerm = term;
      _matchIds = ids;
      // Land on the newest hit first; up/down step from there.
      _matchCursor = ids.isEmpty ? 0 : ids.length - 1;
    });
    if (ids.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpTo(ids[_matchCursor]),
      );
    }
  }

  // delta -1 = older hit, +1 = newer hit (wraps).
  void _gotoMatch(int delta) {
    if (_matchIds.isEmpty) return;
    setState(() => _matchCursor = (_matchCursor + delta) % _matchIds.length);
    _jumpTo(_matchIds[_matchCursor]);
  }

  void _jumpTo(int messageId) {
    final ctx = _msgKeys[messageId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() => _flashId = messageId);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _flashId == messageId) setState(() => _flashId = null);
    });
  }

  // On first data load, jump to the message the admin tapped in the search list.
  void _maybeInitialJump(List<ChatMessage> visible) {
    if (_didInitialJump || widget.initialMessageId == null) return;
    if (!visible.any((m) => m.id == widget.initialMessageId)) return;
    _didInitialJump = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpTo(widget.initialMessageId!),
    );
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

    // Edit mode: rewrite instead of sending. Text-only (the DB pins attachment_url), so an
    // empty text is a no-op rather than a delete.
    final editing = _editing;
    if (editing != null) {
      if (text.isEmpty || _sending) return;
      setState(() => _sending = true);
      final err = await ref
          .read(adminThreadMessagesProvider(_conversationId).notifier)
          .editMessage(messageId: editing.id, message: text);
      if (!mounted) return;
      setState(() {
        _sending = false;
        if (err == null) {
          _editing = null;
          _controller.clear();
        }
      });
      if (err != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

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

  /// Puts the composer into edit mode, seeded with the existing text.
  void _startEdit(ChatMessage msg) {
    setState(() {
      _editing = msg;
      _controller.text = msg.message;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _controller.clear();
    });
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
                // Admin messages only. The DJTILBUD side is one shared voice, so any admin may
                // edit any admin reply — but never the musician's own words (the web-app route
                // scopes the update to sender_type='admin').
                if (msg.isAdmin &&
                    !msg.isSystemMessage &&
                    msg.message.isNotEmpty) ...[
                  Divider(height: 1, color: _c.border.subtle),
                  ListTile(
                    leading: Icon(
                      Icons.edit_outlined,
                      color: _c.text.secondary,
                    ),
                    title: const Text('Rediger besked'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _startEdit(msg);
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
      appBar:
          _searchOpen
              ? AppBar(
                backgroundColor: _c.bg.surface,
                surfaceTintColor: _c.bg.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSearch,
                ),
                titleSpacing: 0,
                title: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary),
                  decoration: InputDecoration(
                    hintText: 'Søg i samtalen',
                    border: InputBorder.none,
                    hintStyle: DSTextStyle.bodyMd.copyWith(
                      color: _c.text.muted,
                    ),
                  ),
                ),
                actions: [
                  if (_searchTerm.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _matchIds.isEmpty
                              ? '0/0'
                              : '${_matchCursor + 1}/${_matchIds.length}',
                          style: DSTextStyle.labelMd.copyWith(
                            color: _c.text.muted,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: _matchIds.isEmpty ? null : () => _gotoMatch(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: _matchIds.isEmpty ? null : () => _gotoMatch(1),
                  ),
                ],
              )
              : AppBar(
                backgroundColor: _c.bg.surface,
                surfaceTintColor: _c.bg.surface,
                // Tighter leading so the avatar sits close to the back chevron rather than being
                // pushed in by the default 16pt title gap.
                titleSpacing: 0,
                title: Row(
                  children: [
                    // The person you're writing with. Same widget (and so the same image/initials
                    // fallback) as the conversation list, so one person reads identically in both.
                    ConversationAvatar(
                      name: widget.thread.userName,
                      imageUrl: widget.thread.userAvatarUrl,
                      size: 36,
                    ),
                    const SizedBox(width: DSSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.thread.userName,
                            style: DSTextStyle.headingSm.copyWith(
                              color: _c.text.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Subtitle doubles as the status line: inside the thread there is no
                          // row tint to lean on, so say it. Reads live off the threads list, so
                          // replying (which handles it via the DB trigger) clears it without
                          // leaving the screen.
                          Consumer(
                            builder: (context, ref, _) {
                              final live =
                                  ref
                                      .watch(adminSupportThreadsProvider)
                                      .valueOrNull
                                      ?.where((t) => t.id == _conversationId)
                                      .firstOrNull;
                              final needsHandling =
                                  !(live?.handled ?? widget.thread.handled);
                              return Text(
                                needsHandling
                                    ? 'Support · Mangler svar'
                                    : 'Support',
                                style: DSTextStyle.bodySm.copyWith(
                                  color:
                                      needsHandling
                                          ? _c.state.warning
                                          : _c.text.muted,
                                  fontWeight:
                                      needsHandling
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // No handled toggle here: it lives in the conversation's long-press menu on the
                // Support list, above "Marker som ulæst/læst".
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _toggleSearch,
                  ),
                ],
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
              data: (data) {
                final visible =
                    data.messages.where((m) => !m.isSystemMessage).toList();
                for (final m in visible) {
                  _msgKeys.putIfAbsent(m.id, () => GlobalKey());
                }
                _maybeInitialJump(visible);
                return _MessageList(
                  messages: visible,
                  reactionsByMessage: data.reactionsByMessage,
                  myId: myId,
                  jobLinks: jobLinks,
                  onReact: _showReactionBar,
                  onImageTap: _showFullImage,
                  messageKeys: _msgKeys,
                  searchTerm: _searchOpen ? _searchTerm : null,
                  flashId: _flashId,
                );
              },
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
          if (_editing != null)
            Container(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4,
                DSSpacing.s2,
                DSSpacing.s2,
                0,
              ),
              child: Row(
                children: [
                  Container(width: 3, height: 32, color: _c.state.warning),
                  const SizedBox(width: DSSpacing.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Redigerer besked',
                          style: DSTextStyle.labelSm.copyWith(
                            color: _c.text.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _editing!.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DSTextStyle.bodySm.copyWith(
                            color: _c.text.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: _c.text.muted),
                    onPressed: _cancelEdit,
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
            hint: _editing != null ? 'Rediger besked…' : 'Svar som DJTILBUD…',
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.reactionsByMessage,
    required this.myId,
    required this.jobLinks,
    required this.onReact,
    required this.onImageTap,
    required this.messageKeys,
    this.searchTerm,
    this.flashId,
  });

  // Already filtered to non-system messages, chronological (oldest first).
  final List<ChatMessage> messages;
  final Map<int, List<AdminReaction>> reactionsByMessage;
  final String? myId;
  final Map<String, JobLinkResolution> jobLinks;
  final void Function(ChatMessage) onReact;
  final void Function(String) onImageTap;
  final Map<int, GlobalKey> messageKeys;
  final String? searchTerm;
  final int? flashId;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Ingen beskeder endnu',
          style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
        ),
      );
    }
    // Non-lazy (reverse) list so each bubble carries a GlobalKey that is always laid out —
    // `Scrollable.ensureVisible` can then reliably jump to any message (search hits, tapped
    // list results). Support threads are small, so building all bubbles is fine.
    return ListView(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s3,
      ),
      children: [
        for (int i = messages.length - 1; i >= 0; i--)
          _Bubble(
            key: messageKeys[messages[i].id],
            message: messages[i],
            // The admin (this side) is 'admin'; the user's messages are 'dj'/'musician'.
            isOwn: messages[i].senderType == 'admin',
            reactions:
                reactionsByMessage[messages[i].id] ?? const <AdminReaction>[],
            jobLinks: jobLinks,
            searchTerm: searchTerm,
            isFlashing: flashId == messages[i].id,
            onLongPress: () => onReact(messages[i]),
            onImageTap: onImageTap,
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.reactions,
    required this.jobLinks,
    required this.onLongPress,
    required this.onImageTap,
    this.searchTerm,
    this.isFlashing = false,
  });

  final ChatMessage message;
  final bool isOwn;
  final List<AdminReaction> reactions;
  final Map<String, JobLinkResolution> jobLinks;
  final VoidCallback onLongPress;
  final void Function(String) onImageTap;
  final String? searchTerm;
  final bool isFlashing;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border:
                  isFlashing
                      ? Border.all(color: const Color(0xFFFFB300), width: 2)
                      : null,
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
                    highlight: searchTerm,
                  ),
                // "Redigeret" marker, mirroring the musician-side bubble in
                // conversation_detail_screen (the two bubble widgets are independent, so this has
                // to be kept in sync by hand). edited_at is DB-stamped, so it cannot be hidden.
                if (message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Redigeret',
                      textAlign: TextAlign.right,
                      style: DSTextStyle.labelSm.copyWith(
                        fontSize: 10,
                        color: fg.withValues(alpha: 0.7),
                      ),
                    ),
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
    this.highlight,
  });

  final String text;
  final TextStyle baseStyle;
  final Map<String, JobLinkResolution> jobLinks;

  /// Search term to highlight (amber) within the text; null/empty = no highlight.
  final String? highlight;

  // Splits a plain-text segment into spans, wrapping every case-insensitive
  // occurrence of the search term with an amber highlight.
  List<InlineSpan> _textSpans(String s) {
    final hl = highlight?.trim().toLowerCase() ?? '';
    if (hl.isEmpty) return [TextSpan(text: s)];
    final lower = s.toLowerCase();
    final out = <InlineSpan>[];
    int i = 0;
    while (i < s.length) {
      final hit = lower.indexOf(hl, i);
      if (hit < 0) {
        out.add(TextSpan(text: s.substring(i)));
        break;
      }
      if (hit > i) out.add(TextSpan(text: s.substring(i, hit)));
      out.add(
        TextSpan(
          text: s.substring(hit, hit + hl.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE082),
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      i = hit + hl.length;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!jobRefRegExp.hasMatch(text)) {
      return Text.rich(TextSpan(style: baseStyle, children: _textSpans(text)));
    }
    final spans = <InlineSpan>[];
    int i = 0;
    for (final m in jobRefRegExp.allMatches(text)) {
      if (m.start > i) {
        spans.addAll(_textSpans(text.substring(i, m.start)));
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
      spans.addAll(_textSpans(text.substring(i)));
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
          'Ingen jobs matcher — skriv fx 491 (internt job) eller E491 (eksternt) efter @',
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
