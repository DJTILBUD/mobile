import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Inline panel with an edit-mode toggle for marking calendar dates as
/// "optaget" (unavailable). Shared by the Jobs-tab calendar and the profile
/// Calendar screen so the availability UX stays identical in both places.
class UnavailableDatesPanel extends StatelessWidget {
  const UnavailableDatesPanel({
    super.key,
    required this.isEditing,
    required this.onToggleEdit,
  });

  final bool isEditing;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s2,
        ),
        decoration: BoxDecoration(
          color:
              isEditing
                  ? _c.state.danger.withValues(alpha: 0.06)
                  : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color:
                isEditing
                    ? _c.state.danger.withValues(alpha: 0.3)
                    : _c.border.subtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isEditing ? LucideIcons.calendarDays : LucideIcons.ban,
              size: 16,
              color: isEditing ? _c.state.danger : _c.text.muted,
            ),
            const SizedBox(width: DSSpacing.s2),
            Expanded(
              child: Text(
                isEditing
                    ? 'Tryk på en dato for at markere/fjerne den som optaget'
                    : 'Marker datoer som optaget for at skjule jobs på de dage',
                style: DSTextStyle.labelSm.copyWith(
                  color: isEditing ? _c.state.danger : _c.text.secondary,
                ),
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            GestureDetector(
              onTap: onToggleEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEditing ? _c.state.danger : _c.border.subtle,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(
                  isEditing ? 'Luk' : 'Rediger',
                  style: DSTextStyle.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isEditing ? _c.text.onDark : _c.text.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
