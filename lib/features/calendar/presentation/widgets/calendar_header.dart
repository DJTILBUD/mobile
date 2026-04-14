import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.month,
    required this.onMonthChanged,
    required this.onTodayTapped,
  });

  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onTodayTapped;

  static const _monthNames = [
    'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    const c = lightColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s2),
      child: Row(
        children: [
          DSIconButton(
            icon: LucideIcons.chevronLeft,
            onTap: () => onMonthChanged(
              DateTime(month.year, month.month - 1),
            ),
          ),
          Expanded(
            child: Text(
              '${_monthNames[month.month - 1]} ${month.year}',
              textAlign: TextAlign.center,
              style: DSTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
                color: c.text.primary,
              ),
            ),
          ),
          DSIconButton(
            icon: LucideIcons.chevronRight,
            onTap: () => onMonthChanged(
              DateTime(month.year, month.month + 1),
            ),
          ),
          const SizedBox(width: DSSpacing.s2),
          GestureDetector(
            onTap: onTodayTapped,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s3, vertical: 6),
              decoration: BoxDecoration(
                color: c.bg.inputBg,
                borderRadius: BorderRadius.circular(DSRadius.sm),
              ),
              child: Text(
                'I dag',
                style: DSTextStyle.labelMd.copyWith(color: c.text.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
