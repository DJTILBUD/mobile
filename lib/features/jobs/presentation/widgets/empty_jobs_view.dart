import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyJobsView extends StatelessWidget {
  const EmptyJobsView({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? LucideIcons.inbox,
              size: 56,
              color: _c.border.strong,
            ),
            const SizedBox(height: DSSpacing.s4),
            Text(
              message,
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
