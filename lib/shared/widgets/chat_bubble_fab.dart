import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// Floating "Beskeder" chat bubble pinned to the bottom-right, mirroring the
/// web app's `FloatingChatButton`: a white pill with a paper-plane icon, the
/// partner + current-user avatars and an unread badge. Opens the conversation
/// on tap. Renders nothing when no conversation exists for the given job, so
/// it is safe to drop into a [Stack] unconditionally.
///
/// Provide exactly one of [jobId] (internal job) or [extJobId] (ext job).
class ChatBubbleFab extends ConsumerWidget {
  const ChatBubbleFab({super.key, this.jobId, this.extJobId})
      : assert(jobId != null || extJobId != null,
            'Provide either jobId or extJobId');

  final int? jobId;
  final int? extJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];

    final matches = conversations.where((conv) =>
        (jobId != null && conv.jobId == jobId) ||
        (extJobId != null && conv.extJobId == extJobId));
    if (matches.isEmpty) return const SizedBox.shrink();
    final conv = matches.first;

    final currentUserId = supabase.auth.currentUser?.id;
    final currentUserImage = currentUserId == null
        ? null
        : ref.watch(userProfileImageProvider(currentUserId)).valueOrNull;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => context.pushNamed(AppRoutes.conversationDetail,
                extra: conv),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
              decoration: BoxDecoration(
                color: c.bg.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.border.subtle),
                boxShadow: DSShadow.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.send, size: 18, color: c.brand.accent),
                  const SizedBox(width: DSSpacing.s2),
                  Text(
                    'Beskeder',
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.text.primary,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s3),
                  _AvatarStack(
                    c: c,
                    partnerName: conv.partnerName,
                    partnerImageUrl: conv.partnerAvatarUrl,
                    currentUserImageUrl: currentUserImage,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (conv.unreadCount > 0)
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.state.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.bg.surface, width: 2),
              ),
              child: Text(
                conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                textAlign: TextAlign.center,
                style: DSTextStyle.labelSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Two overlapping circular avatars (current user behind, partner in front),
/// each ringed with the surface colour — the mobile equivalent of the web
/// app's `AvatarGroup`.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.c,
    required this.partnerName,
    this.partnerImageUrl,
    this.currentUserImageUrl,
  });

  final DSColors c;
  final String partnerName;
  final String? partnerImageUrl;
  final String? currentUserImageUrl;

  static const double _size = 26;
  static const double _overlap = 16;

  @override
  Widget build(BuildContext context) {
    final hasCurrentUser = currentUserImageUrl != null;
    return SizedBox(
      width: hasCurrentUser ? _size + _overlap : _size,
      height: _size,
      child: Stack(
        children: [
          if (hasCurrentUser)
            _avatar(imageUrl: currentUserImageUrl, name: null),
          Positioned(
            left: hasCurrentUser ? _overlap : 0,
            child: _avatar(imageUrl: partnerImageUrl, name: partnerName),
          ),
        ],
      ),
    );
  }

  Widget _avatar({String? imageUrl, String? name}) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.brand.primary.withValues(alpha: 0.12),
        border: Border.all(color: c.bg.surface, width: 2),
      ),
      // ClipOval guarantees a perfectly round image — relying on the
      // Container's circle decoration + clipBehavior lets image corners poke
      // past the circle, so the avatars read as rounded squares.
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: _size,
                height: _size,
                errorWidget: (_, __, ___) => _fallback(name),
              )
            : _fallback(name),
      ),
    );
  }

  Widget _fallback(String? name) {
    final initial =
        (name != null && name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : null;
    return Center(
      child: initial != null
          ? Text(
              initial,
              style: DSTextStyle.labelSm.copyWith(
                color: c.brand.primaryActive,
                fontWeight: FontWeight.w700,
              ),
            )
          : Icon(LucideIcons.user, size: 14, color: c.brand.primaryActive),
    );
  }
}
