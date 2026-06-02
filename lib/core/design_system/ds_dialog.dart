import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';
import 'package:dj_tilbud_app/core/design_system/ds_button.dart';

/// Design-system dialog. Themed surface (bg, radius, border, shadow) with a
/// title, an optional message or custom [content], and a right-aligned row of
/// action buttons (use [DSButton]s). Prefer [showDSConfirm] for yes/no prompts
/// and [showDSDialog] for everything else, instead of bare Material AlertDialogs.
class DSDialog extends StatelessWidget {
  const DSDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  final String title;

  /// Simple text body. Ignored when [content] is provided.
  final String? message;

  /// Custom body widget (takes precedence over [message]).
  final Widget? content;

  /// Action buttons, rendered right-aligned. Use [DSButton]s.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6, vertical: DSSpacing.s6),
      child: Container(
        // Elevated surface treatment (distinct from a flat DSSurface card):
        // bg.elevated + the md "floating" shadow, since a dialog sits above
        // everything. In dark mode bg.elevated is lighter than the canvas.
        decoration: BoxDecoration(
          color: c.bg.elevated,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(color: c.border.subtle),
          boxShadow: DSShadow.md,
        ),
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: DSTextStyle.headingSm.copyWith(color: c.text.primary)),
            if (content != null || message != null) ...[
              const SizedBox(height: DSSpacing.s3),
              content ?? Text(message!, style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary)),
            ],
            const SizedBox(height: DSSpacing.s4),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: DSSpacing.s2,
                runSpacing: DSSpacing.s2,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a [DSDialog]. [actions] is a builder so action buttons can pop the
/// dialog via the provided dialog context (`Navigator.of(ctx).pop(value)`).
Future<T?> showDSDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required List<Widget> Function(BuildContext ctx) actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => DSDialog(
      title: title,
      message: message,
      content: content,
      actions: actions(ctx),
    ),
  );
}

/// Yes/no confirmation built on [DSDialog]. Returns true when confirmed.
/// Set [destructive] for delete-style actions (uses the tertiary/destructive
/// button style).
Future<bool> showDSConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Bekræft',
  String cancelLabel = 'Annuller',
  bool destructive = false,
}) async {
  final result = await showDSDialog<bool>(
    context,
    title: title,
    message: message,
    actions: (ctx) => [
      DSButton(
        label: cancelLabel,
        variant: DSButtonVariant.ghost,
        size: DSButtonSize.sm,
        onTap: () => Navigator.of(ctx).pop(false),
      ),
      DSButton(
        label: confirmLabel,
        variant: destructive ? DSButtonVariant.tertiary : DSButtonVariant.primary,
        size: DSButtonSize.sm,
        onTap: () => Navigator.of(ctx).pop(true),
      ),
    ],
  );
  return result ?? false;
}
