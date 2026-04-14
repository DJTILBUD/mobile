import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/chat_message.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
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
  static const _c = lightColors;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  String? _errorMsg;

  String get _currentUserId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  @override
  void dispose() {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.partnerName,
              style: DSTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
                color: _c.text.primary,
              ),
            ),
            Text(
              widget.conversation.jobInfo,
              style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
              color: _c.state.danger.withValues(alpha: 0.1),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;
  static const _avatarSize = 28.0;

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    message.message,
                    style: DSTextStyle.bodyMd.copyWith(
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// Small initials avatar using DS tokens
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name});

  final String name;

  static const _c = lightColors;
  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
