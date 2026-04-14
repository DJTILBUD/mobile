import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Animated top banner shown when a foreground FCM notification arrives.
/// Slides in from above, auto-dismisses after 4 seconds.
/// Tap → navigates to the relevant screen. Swipe up → dismisses.
class InAppNotificationBanner extends ConsumerStatefulWidget {
  const InAppNotificationBanner({super.key});

  @override
  ConsumerState<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState
    extends ConsumerState<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  Timer? _dismissTimer;
  RemoteMessage? _current;

  static const _autoDismissDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DSMotion.slow,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: DSMotion.ease));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _show(RemoteMessage message) {
    _dismissTimer?.cancel();
    setState(() => _current = message);
    _controller.forward(from: 0);
    _dismissTimer = Timer(_autoDismissDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) {
      setState(() => _current = null);
      ref.read(inAppNotificationProvider.notifier).state = null;
    }
  }

  Future<void> _onTap() async {
    _dismissTimer?.cancel();
    final message = _current;
    await _controller.reverse();
    if (!mounted) return;
    setState(() => _current = null);
    ref.read(inAppNotificationProvider.notifier).state = null;
    if (message != null && mounted) {
      final router = GoRouter.of(context);
      await NotificationsService.navigateTo(message.data, router);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RemoteMessage?>(inAppNotificationProvider, (prev, next) {
      if (next != null && next != prev) _show(next);
    });

    if (_current == null) return const SizedBox.shrink();

    final c = DSTheme.of(context);
    final msg = _current!;
    final type = msg.data['type'] as String? ?? '';
    final title = msg.notification?.title ?? _labelForType(type);
    final body = msg.notification?.body;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.s4,
                vertical: DSSpacing.s2,
              ),
              child: GestureDetector(
                onTap: _onTap,
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < -80) _dismiss();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bg.surface,
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                    border: Border.all(color: c.border.subtle),
                    boxShadow: DSShadow.md,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s3,
                    vertical: DSSpacing.s3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _iconBg(c, type),
                          borderRadius: BorderRadius.circular(DSRadius.md),
                        ),
                        child: Icon(
                          _iconForType(type),
                          size: 20,
                          color: _iconFg(c, type),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s3),
                      // Title + body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: DSTextStyle.labelLg
                                  .copyWith(color: c.text.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (body != null && body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                body,
                                style: DSTextStyle.bodySm
                                    .copyWith(color: c.text.secondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      // Dismiss button
                      GestureDetector(
                        onTap: _dismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(DSSpacing.s1),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: c.text.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  IconData _iconForType(String type) => switch (type) {
        'new_job' || 'another_round' => LucideIcons.listMusic,
        'quote_won' || 'offer_won' => LucideIcons.checkCircle,
        'quote_lost' || 'offer_lost' => LucideIcons.xCircle,
        'chat_message' => LucideIcons.messageCircle,
        'ext_job_assigned' => LucideIcons.star,
        'ready_reminder' => LucideIcons.alarmClock,
        _ => LucideIcons.bell,
      };

  Color _iconBg(DSColors c, String type) => switch (type) {
        'quote_won' || 'offer_won' =>
          c.state.success.withValues(alpha: 0.15),
        'quote_lost' || 'offer_lost' =>
          c.state.danger.withValues(alpha: 0.12),
        'chat_message' => c.brand.accent.withValues(alpha: 0.15),
        'new_job' || 'another_round' || 'ext_job_assigned' =>
          c.brand.primary.withValues(alpha: 0.35),
        'ready_reminder' => c.state.warning.withValues(alpha: 0.20),
        _ => c.bg.inputBg,
      };

  Color _iconFg(DSColors c, String type) => switch (type) {
        'quote_won' || 'offer_won' => c.state.success,
        'quote_lost' || 'offer_lost' => c.state.danger,
        'chat_message' => c.brand.accent,
        'new_job' || 'another_round' || 'ext_job_assigned' =>
          c.brand.primaryActive,
        'ready_reminder' => c.state.warning,
        _ => c.text.secondary,
      };

  String _labelForType(String type) => switch (type) {
        'new_job' => 'Ny opgave',
        'another_round' => 'Ny runde',
        'quote_won' => 'Tillykke! Tilbud vundet',
        'quote_lost' => 'Tilbud ikke valgt',
        'offer_won' => 'Tillykke! Tilbud vundet',
        'offer_lost' => 'Tilbud ikke valgt',
        'chat_message' => 'Ny besked',
        'ext_job_assigned' => 'Ny opgave tildelt',
        'ready_reminder' => 'Påmindelse',
        _ => 'Notifikation',
      };
}
