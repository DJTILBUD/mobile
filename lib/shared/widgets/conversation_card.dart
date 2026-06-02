import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';

/// Shows a tappable chat card when a conversation exists for the given [jobId]
/// (regular job) or [extJobId] (ext job). Renders nothing when no matching
/// conversation is found.
///
/// [title] overrides the card heading (default "Chat med instrumentalist" for
/// the DJ side; pass e.g. "Skriv til DJ'en" on the musician side).
/// [showPartnerName] toggles the partner-name subtitle — set false to keep the
/// card compact when the name is already shown elsewhere.
/// [compact] reduces the icon size and padding for inline use.
class ConversationCard extends ConsumerWidget {
  const ConversationCard({
    super.key,
    this.jobId,
    this.extJobId,
    this.title = 'Chat med instrumentalist',
    this.showPartnerName = true,
    this.compact = false,
  }) : assert(jobId != null || extJobId != null,
            'Provide either jobId or extJobId');

  final int? jobId;
  final int? extJobId;
  final String title;
  final bool showPartnerName;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final _c = DSTheme.of(context);
    final conversations =
        ref.watch(conversationsProvider).valueOrNull ?? [];

    final conv = conversations.firstWhere(
      (c) =>
          (jobId != null && c.jobId == jobId) ||
          (extJobId != null && c.extJobId == extJobId),
      orElse: () => _sentinel,
    );

    if (identical(conv, _sentinel)) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoutes.conversationDetail,
        extra: conv,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _c.brand.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: _c.brand.accent.withValues(alpha: 0.35),
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: DSSpacing.s4,
            vertical: compact ? DSSpacing.s2 : DSSpacing.s3),
        child: Row(
          children: [
            Container(
              width: compact ? 30 : 36,
              height: compact ? 30 : 36,
              decoration: BoxDecoration(
                color: _c.brand.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.messageSquare,
                  size: compact ? 15 : 18, color: _c.brand.accent),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (compact ? DSTextStyle.labelMd : DSTextStyle.labelLg)
                        .copyWith(
                      color: _c.text.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showPartnerName)
                    Text(
                      conv.partnerName,
                      style:
                          DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                    ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: _c.text.muted),
          ],
        ),
      ),
    );
  }
}

// Sentinel to distinguish "not found" from a nullable list result.
final _sentinel = Conversation(
  id: -1,
  senderType: '',
  partnerName: '',
  jobInfo: '',
  createdAt: DateTime(0),
  unreadCount: 0,
  isLastMessageFromMe: false,
  lastMessageIsSystem: false,
);
