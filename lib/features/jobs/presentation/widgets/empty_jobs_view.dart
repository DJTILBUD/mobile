import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyJobsView extends StatelessWidget {
  const EmptyJobsView({
    super.key,
    required this.message,
    this.icon,
    this.title,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final IconData? icon;

  /// Optional bold heading shown above [message].
  final String? title;

  /// Optional primary CTA (e.g. "Justér filtre"). Hidden when null.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional secondary/ghost CTA (e.g. "Slå filtre fra"). Hidden when null.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? LucideIcons.inbox, size: 56, color: c.border.strong),
            const SizedBox(height: DSSpacing.s4),
            if (title != null) ...[
              Text(
                title!,
                style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DSSpacing.s2),
            ],
            Text(
              message,
              style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: DSSpacing.s6),
              DSButton(
                label: actionLabel!,
                variant: DSButtonVariant.primary,
                onTap: onAction,
              ),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: DSSpacing.s2),
              DSButton(
                label: secondaryLabel!,
                variant: DSButtonVariant.ghost,
                size: DSButtonSize.sm,
                onTap: onSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
