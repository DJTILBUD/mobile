import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  String? _errorMsg;

  // Captured in initState so they can be safely called from dispose()
  late final StateController<int?> _activeConvNotifier;
  late final StateController<bool> _suppressDismissBarNotifier;

  String get _currentUserId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _activeConvNotifier = ref.read(activeConversationIdProvider.notifier);
    _suppressDismissBarNotifier =
        ref.read(suppressKeyboardDismissBarProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Mark this conversation as active so foreground FCM banners are suppressed
      _activeConvNotifier.state = widget.conversation.id;
      // Hide the global keyboard dismiss bar — the chat input is already at the
      // bottom of the screen, and the bar would overlay it.
      _suppressDismissBarNotifier.state = true;
      _markAsRead();
      // Force a fresh message fetch: the provider may be reused from a previous
      // visit (autoDispose can keep it alive across same-frame navigation), so
      // stale state would be shown without this refresh.
      ref
          .read(conversationMessagesProvider(widget.conversation.id).notifier)
          .refresh();
    });
  }

  @override
  void dispose() {
    // Defer state writes — Riverpod disallows provider mutations during
    // widget tree finalization (dispose is called while the tree is unmounting).
    Future.microtask(() {
      _activeConvNotifier.state = null;
      _suppressDismissBarNotifier.state = false;
    });
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    await ref
        .read(conversationMessagesProvider(widget.conversation.id).notifier)
        .markAsRead(_currentUserId);
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    _textController.clear();

    final success = await ref
        .read(conversationMessagesProvider(widget.conversation.id).notifier)
        .sendMessage(
          senderId: _currentUserId,
          senderType: widget.conversation.senderType,
          message: text,
        );

    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        setState(() => _errorMsg = 'Beskeden kunne ikke sendes. Prøv igen.');
        _textController.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final messagesAsync =
        ref.watch(conversationMessagesProvider(widget.conversation.id));

    ref.listen(
      conversationMessagesProvider(widget.conversation.id),
      (previous, next) {
        final prevCount = previous?.valueOrNull?.length ?? 0;
        final nextCount = next.valueOrNull?.length ?? 0;
        if (nextCount > prevCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
            _markAsRead();
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: _c.bg.surface,
      appBar: AppBar(
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        titleSpacing: 0,
        title: Text(
          widget.conversation.partnerName,
          style: DSTextStyle.headingSm.copyWith(
            fontWeight: FontWeight.w700,
            color: _c.text.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          _JobBanner(conversation: widget.conversation),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Kunne ikke hente beskeder',
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send en besked for at starte samtalen',
                      style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(animate: false);
                });
                return _MessageList(
                  messages: messages,
                  currentUserId: _currentUserId,
                  partnerName: widget.conversation.partnerName,
                  scrollController: _scrollController,
                );
              },
            ),
          ),

          if (_errorMsg != null)
            Container(
              width: double.infinity,
              color: _c.state.danger.withValues(alpha: 0.16),
              padding:
                  const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s2),
              child: Text(
                _errorMsg!,
                style: DSTextStyle.labelMd.copyWith(color: _c.state.danger),
              ),
            ),

          _MessageInput(
            controller: _textController,
            focusNode: _focusNode,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─── Job navigation banner ────────────────────────────────────────────────────

class _JobBanner extends ConsumerWidget {
  const _JobBanner({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final _c = DSTheme.of(context);
    final conv = conversation;
    VoidCallback? onTap;

    if (conv.senderType == 'dj') {
      if (conv.extJobId != null) {
        final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
        final matches = extJobs.where((e) => e.id == conv.extJobId).toList();
        if (matches.isNotEmpty) {
          final extJob = matches.first;
          onTap = () => context.pushNamed(AppRoutes.extJobDetail, extra: extJob);
        }
      } else if (conv.jobId != null) {
        final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
        final matches = quotes.where((q) => q.jobId == conv.jobId).toList();
        if (matches.isNotEmpty) {
          final quote = matches.first;
          onTap = () => context.pushNamed(AppRoutes.quoteDetail, extra: quote);
        }
      }
    } else if (conv.senderType == 'musician') {
      final offers = ref.watch(serviceOffersProvider).valueOrNull ?? [];
      final matches = offers.where(
        (o) => (conv.jobId != null && o.jobId == conv.jobId) ||
            (conv.extJobId != null && o.extJobId == conv.extJobId),
      ).toList();
      if (matches.isNotEmpty) {
        final offer = matches.first;
        onTap = () => context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _c.bg.canvas,
          border: Border(bottom: BorderSide(color: _c.border.subtle)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s4, vertical: DSSpacing.s3 + 2),
        child: Row(
          children: [
            Icon(LucideIcons.briefcase, size: 14, color: _c.text.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                conv.jobInfo,
                style: DSTextStyle.labelMd.copyWith(
                  color: _c.text.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 15, color: _c.text.secondary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.partnerName,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final String currentUserId;
  final String partnerName;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    // Group messages by calendar date
    final groups = <({DateTime date, List<ChatMessage> messages})>[];
    DateTime? currentDate;

    for (final msg in messages) {
      final msgDate = DateTime(
          msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (currentDate == null || msgDate != currentDate) {
        currentDate = msgDate;
        groups.add((date: msgDate, messages: [msg]));
      } else {
        groups.last.messages.add(msg);
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateDivider(date: group.date),
            ...List.generate(group.messages.length, (i) {
              final msg = group.messages[i];
              final next = i < group.messages.length - 1
                  ? group.messages[i + 1]
                  : null;
              final showTimestamp = next == null ||
                  next.senderId != msg.senderId ||
                  next.createdAt.difference(msg.createdAt).inMinutes >= 1;

              return _MessageBubble(
                message: msg,
                isOwn: msg.senderId == currentUserId,
                partnerName: partnerName,
                showTimestamp: showTimestamp,
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'I dag';
    } else if (date == yesterday) {
      label = 'I går';
    } else {
      const months = [
        'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
        'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
      ];
      label = '${date.day}. ${months[date.month - 1]} ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.s3, horizontal: DSSpacing.s4),
      child: Row(
        children: [
          Expanded(child: Divider(color: _c.border.subtle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s3),
            child: Text(
              label,
              style: DSTextStyle.labelSm.copyWith(
                color: _c.text.muted,
              ),
            ),
          ),
          Expanded(child: Divider(color: _c.border.subtle)),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.partnerName,
    required this.showTimestamp,
  });

  final ChatMessage message;
  final bool isOwn;
  final String partnerName;
  final bool showTimestamp;

  static const _avatarSize = 28.0;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.s1, horizontal: DSSpacing.s4),
        child: Center(
          child: Text(
            message.message,
            style: DSTextStyle.bodySm.copyWith(
              color: _c.text.muted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final timeString = _formatTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        left: isOwn ? 56 : 8,
        right: isOwn ? 8 : 56,
        top: 2,
        bottom: showTimestamp ? 2 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar — only for partner messages
          if (!isOwn) ...[
            _ChatAvatar(name: partnerName),
            const SizedBox(width: 6),
          ],

          // Bubble + optional timestamp
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOwn ? _c.brand.primary : _c.bg.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(DSRadius.lg),
                      topRight: const Radius.circular(DSRadius.lg),
                      bottomLeft: isOwn
                          ? const Radius.circular(DSRadius.lg)
                          : const Radius.circular(DSRadius.sm),
                      bottomRight: isOwn
                          ? const Radius.circular(DSRadius.sm)
                          : const Radius.circular(DSRadius.lg),
                    ),
                    border: isOwn
                        ? null
                        : Border.all(color: _c.border.subtle, width: 1),
                  ),
                  child: _FormattedText(
                    text: message.message,
                    baseStyle: DSTextStyle.bodyMd.copyWith(
                      color: isOwn ? _c.brand.onPrimary : _c.text.primary,
                      height: 1.4,
                    ),
                  ),
                ),
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: DSSpacing.s1, bottom: DSSpacing.s1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeString,
                          style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.muted),
                        ),
                        if (isOwn && message.readAt != null) ...[
                          Text(
                            ' • Set kl ${_formatTime(message.readAt!)}',
                            style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Keep spacing symmetrical on own-message side
          if (isOwn)
            const SizedBox(width: _avatarSize + 6),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// Small initials avatar using DS tokens
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name});

  final String name;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _c.brand.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial,
          style: DSTextStyle.labelSm.copyWith(
            color: _c.brand.primaryActive,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Formatted text (bold + bullets + paragraphs) ────────────────────────────

class _FormattedText extends StatelessWidget {
  const _FormattedText({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  static final _boldRegex = RegExp(r'\*\*(.*?)\*\*');

  List<InlineSpan> _parseInline(String raw) {
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final match in _boldRegex.allMatches(raw)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: raw.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      cursor = match.end;
    }
    if (cursor < raw.length) spans.add(TextSpan(text: raw.substring(cursor)));
    if (spans.isEmpty) spans.add(TextSpan(text: raw));
    return spans;
  }

  Widget _buildLine(String line) {
    final isBullet = line.startsWith('- ');
    final content = isBullet ? line.substring(2) : line;
    final inlineSpans = _parseInline(content);

    if (isBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: baseStyle),
          Flexible(
            child: RichText(
              text: TextSpan(style: baseStyle, children: inlineSpans),
            ),
          ),
        ],
      );
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: inlineSpans),
    );
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final paragraphs = text.split(RegExp(r'\n\n+'));
    final blocks = <Widget>[];

    for (int p = 0; p < paragraphs.length; p++) {
      if (p > 0) blocks.add(const SizedBox(height: 8));
      final lines = paragraphs[p].split('\n');
      for (int l = 0; l < lines.length; l++) {
        if (l > 0) blocks.add(const SizedBox(height: 3));
        blocks.add(_buildLine(lines[l]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }
}

// ─── Message input ────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        border: Border(top: BorderSide(color: _c.border.subtle)),
      ),
      padding: const EdgeInsets.fromLTRB(DSSpacing.s3, DSSpacing.s2, DSSpacing.s2, DSSpacing.s2),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Input — DSInput with no label, multi-line
            Expanded(
              child: DSInput(
                controller: controller,
                focusNode: focusNode,
                hint: 'Skriv en besked...',
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(width: DSSpacing.s2),

            // Send button
            DSIconButton(
              icon: LucideIcons.send,
              variant: DSIconButtonVariant.primary,
              isLoading: isSending,
              onTap: isSending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
