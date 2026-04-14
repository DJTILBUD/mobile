import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.events,
    required this.selectedDay,
    required this.onDaySelected,
    this.unavailableDays = const {},
    this.onDayLongPress,
  });

  final DateTime month;
  final List<CalendarEvent> events;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// Set of 'yyyy-MM-dd' strings for days the DJ marked as unavailable.
  final Set<String> unavailableDays;

  /// Optional long-press callback for toggling unavailability.
  final ValueChanged<DateTime>? onDayLongPress;

  static const _weekDays = ['Ma', 'Ti', 'On', 'To', 'Fr', 'Lø', 'Sø'];

  @override
  Widget build(BuildContext context) {
    const c = lightColors;
    final today = DateTime.now();
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    // day-of-month → set of CalendarEventKind
    final kindsByDay = <int, Set<CalendarEventKind>>{};
    for (final event in events) {
      if (event.date.year == month.year && event.date.month == month.month) {
        kindsByDay
            .putIfAbsent(event.date.day, () => <CalendarEventKind>{})
            .add(event.kind);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Column(
        children: [
          Row(
            children: _weekDays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: DSTextStyle.labelSm
                                .copyWith(color: c.text.secondary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: DSSpacing.s1),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.9,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();

              final day = index - leadingBlanks + 1;
              final date = DateTime(month.year, month.month, day);
              final dateStr =
                  DateFormat('yyyy-MM-dd').format(date);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = selectedDay != null &&
                  date.year == selectedDay!.year &&
                  date.month == selectedDay!.month &&
                  date.day == selectedDay!.day;
              final isUnavailable = unavailableDays.contains(dateStr);
              final kinds = kindsByDay[day];

              return GestureDetector(
                onTap: () => onDaySelected(date),
                onLongPress: onDayLongPress != null
                    ? () => onDayLongPress!(date)
                    : null,
                child: _DayCell(
                  day: day,
                  isToday: isToday,
                  isSelected: isSelected,
                  isUnavailable: isUnavailable,
                  eventKinds: kinds,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isUnavailable,
    this.eventKinds,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isUnavailable;
  final Set<CalendarEventKind>? eventKinds;

  @override
  Widget build(BuildContext context) {
    const c = lightColors;
    final hasEvents = eventKinds != null && eventKinds!.isNotEmpty;

    Color? bgColor;
    if (isSelected) {
      bgColor = c.brand.primary;
    } else if (isUnavailable) {
      bgColor = c.state.danger.withValues(alpha: 0.12);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: isToday && !isSelected
            ? Border.all(color: c.brand.primaryActive, width: 1.5)
            : isUnavailable && !isSelected
                ? Border.all(
                    color: c.state.danger.withValues(alpha: 0.35), width: 1)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: DSTextStyle.bodyMd.copyWith(
              fontWeight:
                  isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? c.brand.onPrimary
                  : isUnavailable
                      ? c.state.danger
                      : c.text.primary,
            ),
          ),
          if (isUnavailable && !isSelected) ...[
            const SizedBox(height: 2),
            Text(
              'Optaget',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: c.state.danger,
                letterSpacing: -0.2,
              ),
            ),
          ],
          if (hasEvents) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: eventKinds!.map((kind) {
                final dotColor = _kindColor(c, kind);
                final resolvedColor =
                    isSelected ? c.brand.onPrimary : dotColor;
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: resolvedColor,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static Color _kindColor(DSColors c, CalendarEventKind kind) {
    return switch (kind) {
      CalendarEventKind.newJob => c.state.info,
      CalendarEventKind.sent   => c.state.warning,
      CalendarEventKind.won    => c.state.success,
    };
  }
}
