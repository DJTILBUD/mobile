import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.month,
    required this.onMonthChanged,
    required this.onTodayTapped,
    this.onShare,
  });

  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onTodayTapped;
  final VoidCallback? onShare;

  static const _monthNamesShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Maj', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec',
  ];

  void _pickYear(BuildContext context) {
    final currentYear = DateTime.now().year;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final c = DSTheme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...List.generate(7, (i) {
                final year = currentYear - 1 + i;
                final isSelected = year == month.year;
                return ListTile(
                  title: Text(
                    '$year',
                    textAlign: TextAlign.center,
                    style: DSTextStyle.labelLg.copyWith(
                      color: isSelected
                          ? c.brand.primaryActive
                          : c.text.primary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onMonthChanged(DateTime(year, month.month));
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s2),
      child: Column(
        children: [
          // ── Year row (tappable → year picker) ──────────────────────────
          GestureDetector(
            onTap: () => _pickYear(context),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${month.year}',
                    style: DSTextStyle.labelSm.copyWith(
                      color: c.text.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(LucideIcons.chevronDown,
                      size: 12, color: c.text.secondary),
                ],
              ),
            ),
          ),
          // ── Month nav row ──────────────────────────────────────────────
          Row(
            children: [
              DSIconButton(
                icon: LucideIcons.chevronLeft,
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
              ),
              Flexible(
                child: Text(
                  _monthNamesShort[month.month - 1],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: DSTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.text.primary,
                  ),
                ),
              ),
              DSIconButton(
                icon: LucideIcons.chevronRight,
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
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
              if (onShare != null) ...[
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: GestureDetector(
                    onTap: onShare,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.s3, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.bg.inputBg,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.share2,
                              size: 14, color: c.text.primary),
                          const SizedBox(width: DSSpacing.s1),
                          Flexible(
                            child: Text(
                              'Eksporter',
                              style: DSTextStyle.labelMd
                                  .copyWith(color: c.text.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
