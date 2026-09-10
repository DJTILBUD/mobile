import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Muted "you cannot do this yet, and here is why" strip shown directly above the
/// action it explains.
///
/// Used wherever a step in the DJ/musician process is gated: waiting for the 5-day
/// ready window, or waiting for the winning musician to contact the customer. Pairing
/// it with a disabled button is the point — a disabled button on its own reads as a
/// bug, which is what sent DJs to support.
class LockedInfoBanner extends StatelessWidget {
  const LockedInfoBanner({
    super.key,
    required this.label,
    this.icon = LucideIcons.alarmClock,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s4,
        vertical: DSSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.bg.canvas,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.text.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
            ),
          ),
        ],
      ),
    );
  }
}
