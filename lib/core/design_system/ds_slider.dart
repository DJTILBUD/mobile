import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system slider — matches web marketplace `Slider`.
class DSSlider extends StatelessWidget {
  const DSSlider({
    super.key,
    required this.value,
    this.label,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChanged,
  });

  final double value;
  final String? label;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.text.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.s1),
        ],
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: c.brand.primary,
          inactiveColor: c.border.subtle,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
