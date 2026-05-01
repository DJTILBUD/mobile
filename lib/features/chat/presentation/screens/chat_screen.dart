import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final _c = DSTheme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: _c.bg.surface,
      appBar: AppBar(
        title: const Text('Beskeder'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: conversationsAsync.when(
        loading: () => const _ConversationListSkeleton(),
        error: (e, _) => _ErrorView(
          onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
        ),
        data: (conversations) => conversations.isEmpty
            ? const _EmptyConversationsView()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: _c.border.subtle,
                    indent: 72,
                  ),
                  itemBuilder: (context, i) => _ConversationTile(
                    conversation: conversations[i],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final lastMsgTime = conversation.lastMessageAt;
    final timeLabel = lastMsgTime != null ? _formatTime(lastMsgTime) : '';

    final hasUnread = conversation.hasUnread;
    final unreadCount = conversation.unreadCount;

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.conversationDetail,
        extra: conversation,
      ),
      child: Container(
        color: hasUnread ? _c.brand.primary.withValues(alpha: 0.06) : null,
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _ConversationAvatar(
              name: conversation.partnerName,
              imageUrl: conversation.partnerAvatarUrl,
            ),
            const SizedBox(width: DSSpacing.s3),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.partnerName,
                          style: DSTextStyle.headingSm.copyWith(
                            fontSize: 15,
                            color: _c.text.primary,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: DSTextStyle.bodySm.copyWith(
                            color: hasUnread ? _c.brand.primaryActive : _c.text.muted,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.jobInfo,
                    style: DSTextStyle.bodySm.copyWith(
                      color: hasUnread ? _c.text.secondary : _c.text.muted,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (conversation.lastMessageText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _buildPreview(conversation),
                            style: DSTextStyle.labelMd.copyWith(
                              color: hasUnread ? _c.text.primary : _c.text.muted,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                              fontStyle: conversation.lastMessageIsSystem
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: DSSpacing.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _c.brand.primaryActive,
                              borderRadius: BorderRadius.circular(DSRadius.pill),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreview(Conversation c) {
    final text = c.lastMessageText ?? '';
    if (c.lastMessageIsSystem) return text;
    final prefix = c.isLastMessageFromMe ? 'Du: ' : '';
    return '$prefix$text';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);

    if (msgDay == today) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    const months = [
      'januar', 'februar', 'marts', 'april', 'maj', 'juni',
      'juli', 'august', 'september', 'oktober', 'november', 'december',
    ];
    return '${local.day}. ${months[local.month - 1]}';
  }
}

// ─── Conversation Avatar ──────────────────────────────────────────────────────

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _InitialsAvatar(name: name, c: _c),
          placeholder: (_, __) => _InitialsAvatar(name: name, c: _c),
        ),
      );
    }
    return _InitialsAvatar(name: name, c: _c);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.c});

  final String name;
  final DSColors c;
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: c.bg.inputBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.text.secondary,
          ),
        ),
      ),
    );
  }
}

class _ConversationListSkeleton extends StatelessWidget {
  const _ConversationListSkeleton();

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: _c.border.subtle,
        indent: 72,
      ),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _c.border.subtle,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: _c.border.subtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 100,
                    decoration: BoxDecoration(
                      color: _c.border.subtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: _c.border.subtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversationsView extends StatelessWidget {
  const _EmptyConversationsView();

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.messageCircle, size: 64, color: _c.border.strong),
          const SizedBox(height: DSSpacing.s4),
          Text(
            'Ingen beskeder endnu',
            style: DSTextStyle.headingMd.copyWith(color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Dine samtaler med kunder vises her.',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: _c.state.danger),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Kunne ikke hente beskeder',
            style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Prøv igen',
            variant: DSButtonVariant.secondary,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
