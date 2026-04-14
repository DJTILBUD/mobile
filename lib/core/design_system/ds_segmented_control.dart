import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system segmented control — matches web marketplace `SegmentedControl`.
/// Pill-shaped track with a sliding selected pill.
class DSSegmentedControl extends StatelessWidget {
  const DSSegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      height: 48,                              // h-12 (md size)
      padding: const EdgeInsets.all(6),        // p-1.5
      decoration: BoxDecoration(
        color: c.bg.inputBg,                   // bg-ds-input-bg (#F1F5F9)
        borderRadius: BorderRadius.circular(DSRadius.pill),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: DSMotion.normal,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? c.bg.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                  boxShadow: isSelected ? DSShadow.sm : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? c.text.primary : c.text.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
