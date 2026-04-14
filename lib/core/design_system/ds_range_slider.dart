import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system range slider (two thumbs) — companion to [DSSlider].
class DSRangeSlider extends StatelessWidget {
  const DSRangeSlider({
    super.key,
    required this.values,
    this.label,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.labelBuilder,
    this.noFilterLabel,
    this.onChanged,
  });

  final RangeValues values;
  final String? label;
  final double min;
  final double max;
  final int? divisions;

  /// Converts a thumb value to a display string. Defaults to the integer value.
  final String Function(double)? labelBuilder;

  /// Shown centred below the slider when both thumbs are at their extremes.
  final String? noFilterLabel;

  final ValueChanged<RangeValues>? onChanged;

  bool get _isFullRange => values.start <= min && values.end >= max;

  String _format(double v) => labelBuilder != null ? labelBuilder!(v) : v.toInt().toString();

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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: c.brand.primary,
            inactiveTrackColor: c.border.subtle,
            thumbColor: c.brand.primaryActive,
            overlayColor: c.brand.primary.withValues(alpha: 0.15),
            valueIndicatorColor: c.brand.primaryActive,
            valueIndicatorTextStyle: TextStyle(
              color: c.brand.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            trackHeight: 4,
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(_format(values.start), _format(values.end)),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _isFullRange && noFilterLabel != null
              ? Center(
                  child: Text(
                    noFilterLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.text.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(values.start),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text.primary,
                      ),
                    ),
                    Text(
                      _format(values.end),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
