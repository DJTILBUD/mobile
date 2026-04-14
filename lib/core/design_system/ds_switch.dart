import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system switch — matches web marketplace `Switch`.
/// Custom track+thumb, not Material Switch.
class DSSwitch extends StatelessWidget {
  const DSSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  bool get _disabled => onChanged == null;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Opacity(
      opacity: _disabled ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.s1),
        child: Row(children: [
          if (label != null)
            Expanded(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _disabled ? c.text.muted : c.text.primary,
                ),
              ),
            ),
          GestureDetector(
            onTap: _disabled ? null : () => onChanged!(!value),
            child: AnimatedContainer(
              duration: DSMotion.normal,
              width: 56,                          // w-14 = 56px
              height: 32,                         // h-8 = 32px
              padding: const EdgeInsets.all(4),   // left-1 top-1 = 4px inset
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DSRadius.pill),
                color: value ? c.brand.primary : c.border.subtle,
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,                        // h-6 w-6 = 24px
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: DSShadow.sm,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
