import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system radio button — matches web marketplace `Radio`.
class DSRadio extends StatelessWidget {
  const DSRadio({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.hint,
    this.disabled = false,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final bool disabled;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged?.call(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DSSpacing.s1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selected ? c.brand.primary : c.border.strong,
                  width: 2,
                ),
              ),
              child: _selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.brand.primary,
                        ),
                      ),
                    )
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
