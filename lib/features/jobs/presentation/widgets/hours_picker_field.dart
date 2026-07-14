import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/utils/extra_hours_options.dart';

/// Field for picking the number of extra hours. Tapping it opens a compact,
/// dismissible bottom sheet (swipe down / tap the scrim to close) instead of the
/// native full-screen dropdown menu, which was awkward with 40 options. Styled to
/// match [DSDropdown] / [DSInput] (label above, pill-shaped filled field).
class HoursPickerField extends StatelessWidget {
  const HoursPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Antal timer',
    this.hint = 'Vælg antal timer...',
  });

  final double? value;
  final ValueChanged<double?> onChanged;
  final String label;
  final String hint;

  Future<void> _openSheet(BuildContext context) async {
    final c = DSTheme.of(context);
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: c.bg.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder: (ctx) {
        final cc = DSTheme.of(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DSSpacing.s4,
                    0,
                    DSSpacing.s4,
                    DSSpacing.s2,
                  ),
                  child: Text(
                    label,
                    style: DSTextStyle.headingSm.copyWith(
                      color: cc.text.primary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: DSSpacing.s2),
                    itemCount: extraHoursOptions.length,
                    itemBuilder: (context, i) {
                      final item = extraHoursOptions[i];
                      final isSelected = item.value == value;
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.label,
                          style: DSTextStyle.bodyMd.copyWith(
                            color: cc.text.primary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: cc.brand.primaryActive,
                                )
                                : null,
                        onTap: () => Navigator.of(ctx).pop(item.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final selectedLabel = value != null ? extraHoursLabel(value!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.text.primary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(DSRadius.pill),
          onTap: () => _openSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s4,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: c.bg.inputBg,
              borderRadius: BorderRadius.circular(DSRadius.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          selectedLabel != null ? c.text.primary : c.text.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(LucideIcons.chevronDown, color: c.text.muted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
