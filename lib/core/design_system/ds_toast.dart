import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum DSToastVariant { success, info, warning, error }

/// Design-system toast — matches web marketplace toast notifications.
class DSToast {
  const DSToast._();

  static void show(
    BuildContext context, {
    required DSToastVariant variant,
    required String title,
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    final c = DSTheme.of(context);
    final (color, icon) = switch (variant) {
      DSToastVariant.success => (c.state.success, LucideIcons.checkCircle),
      DSToastVariant.info => (c.state.info, LucideIcons.info),
      DSToastVariant.warning => (c.state.warning, LucideIcons.alertTriangle),
      DSToastVariant.error => (c.state.danger, LucideIcons.alertCircle),
    };
    // Yellow is too light for white text; every other variant keeps white.
    final fg =
        variant == DSToastVariant.warning ? dsContentOn(color) : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: fg,
                      fontSize: 14,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontSize: 12,
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
