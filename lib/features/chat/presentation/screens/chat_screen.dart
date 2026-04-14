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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final lastMsgTime = conversation.lastMessageAt;
    final timeLabel = lastMsgTime != null ? _formatTime(lastMsgTime) : '';

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.conversationDetail,
        extra: conversation,
      ),
      child: Padding(
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
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w800
                                : FontWeight.w500,
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
                            color: conversation.hasUnread
                                ? _c.brand.primary
                                : _c.text.muted,
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.jobInfo,
                    style: DSTextStyle.bodySm.copyWith(
                      color: _c.text.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (conversation.lastMessageText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _buildPreview(conversation),
                            style: DSTextStyle.labelMd.copyWith(
                              color: conversation.hasUnread
                                  ? _c.text.primary
                                  : _c.text.muted,
                              fontWeight: conversation.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontStyle: conversation.lastMessageIsSystem
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _c.brand.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                conversation.unreadCount > 9
                                    ? '9+'
                                    : '${conversation.unreadCount}',
                                style: DSTextStyle.bodySm.copyWith(
                                  fontSize: 11,
                                  color: _c.brand.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
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
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      // Today — show time
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'I går';
    } else if (diff.inDays < 7) {
      const days = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

// ─── Conversation Avatar ──────────────────────────────────────────────────────

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  static const _c = lightColors;
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
