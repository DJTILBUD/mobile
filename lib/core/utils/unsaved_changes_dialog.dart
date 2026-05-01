import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Shows a confirmation dialog when the user tries to leave a screen with
/// unsaved changes. Returns `true` if the user confirms they want to leave.
Future<bool?> showUnsavedChangesDialog(BuildContext context) {
  final c = DSTheme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.bg.surface,
      surfaceTintColor: c.bg.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      title: Text(
        'Ugemte ændringer',
        style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
      ),
      content: Text(
        'Du har ændringer der ikke er gemt. Vil du forlade siden alligevel?',
        style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Bliv på siden',
            style: DSTextStyle.labelMd.copyWith(
              color: c.text.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Forlad',
            style: DSTextStyle.labelMd.copyWith(
              color: c.state.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
