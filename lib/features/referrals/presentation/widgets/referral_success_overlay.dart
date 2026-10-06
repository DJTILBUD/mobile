import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// A brief, self-dismissing "sent!" celebration shown right after a referral is created —
/// a plain toast disappears too fast to register as a real reward moment, and the tab switches
/// to "Mine henvisninger" right after, so this is the one beat that says "that worked" before
/// the view changes under the user. Pure Flutter tweens, no animation package needed.
class ReferralSuccessOverlay extends StatefulWidget {
  const ReferralSuccessOverlay({super.key});

  @override
  State<ReferralSuccessOverlay> createState() => _ReferralSuccessOverlayState();
}

class _ReferralSuccessOverlayState extends State<ReferralSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s8,
              vertical: DSSpacing.s6,
            ),
            decoration: BoxDecoration(
              color: c.bg.surface,
              borderRadius: BorderRadius.circular(DSRadius.lg),
              boxShadow: DSShadow.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.brand.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 36,
                      color: c.brand.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: DSSpacing.s4),
                Text(
                  'Henvisning sendt!',
                  style: DSTextStyle.headingMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.text.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the overlay and resolves once it has auto-dismissed (~1.1s total), so callers can
/// `await` it before doing whatever comes next (e.g. switching tabs).
Future<void> showReferralSuccessOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (dialogContext, animation1, animation2) {
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });
      return const ReferralSuccessOverlay();
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
