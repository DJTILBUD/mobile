import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Design-system checkbox — matches web marketplace `Checkbox`.
class DSCheckbox extends StatelessWidget {
  const DSCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.disabled = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? hint;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DSSpacing.s1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DSRadius.sm), // 8px
                color: value ? c.brand.primary : Colors.transparent,
                border: Border.all(
                  color: value ? c.brand.primary : c.border.strong,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text.primary)),
                  if (hint != null)
                    Text(hint!, style: TextStyle(fontSize: 12, color: c.text.muted)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
