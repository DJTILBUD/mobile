import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_header.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _month = month;
      _selectedDay = null;
    });
  }

  void _onTodayTapped() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selectedDay = null;
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      // Deselect if tapping the same day again
      if (_selectedDay != null &&
          _selectedDay!.year == day.year &&
          _selectedDay!.month == day.month &&
          _selectedDay!.day == day.day) {
        _selectedDay = null;
      } else {
        _selectedDay = day;
      }
    });
  }

  List<CalendarEvent> _eventsForView(List<CalendarEvent> all) {
    if (_selectedDay != null) {
      return all
          .where((e) =>
              e.date.year == _selectedDay!.year &&
              e.date.month == _selectedDay!.month &&
              e.date.day == _selectedDay!.day)
          .toList();
    }
    return all
        .where((e) => e.date.year == _month.year && e.date.month == _month.month)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(widget.role));
    final isDj = widget.role == MusicianRole.dj;

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Kalender', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        iconTheme: IconThemeData(color: _c.text.primary),
        actions: [
          if (eventsAsync.valueOrNull != null)
            DSIconButton(
              icon: LucideIcons.share2,
              variant: DSIconButtonVariant.ghost,
              onTap: () => showIcalExportBottomSheet(
                context,
                events: eventsAsync.value!,
                isDj: isDj,
              ),
            ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          onRetry: () =>
              ref.read(calendarEventsProvider(widget.role).notifier).refresh(),
        ),
        data: (events) => _CalendarBody(
          month: _month,
          selectedDay: _selectedDay,
          events: events,
          visibleEvents: _eventsForView(events),
          onMonthChanged: _onMonthChanged,
          onTodayTapped: _onTodayTapped,
          onDaySelected: _onDaySelected,
        ),
      ),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.month,
    required this.selectedDay,
    required this.events,
    required this.visibleEvents,
    required this.onMonthChanged,
    required this.onTodayTapped,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final List<CalendarEvent> events;
  final List<CalendarEvent> visibleEvents;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onTodayTapped;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: DSSpacing.s2),
              CalendarHeader(
                month: month,
                onMonthChanged: onMonthChanged,
                onTodayTapped: onTodayTapped,
              ),
              const SizedBox(height: DSSpacing.s2),
              CalendarGrid(
                month: month,
                events: events,
                selectedDay: selectedDay,
                onDaySelected: onDaySelected,
              ),
              const SizedBox(height: DSSpacing.s4),
              Divider(height: 1, color: _c.border.subtle),
              const SizedBox(height: DSSpacing.s2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Text(
                      selectedDay != null
                          ? _formatSelectedDay(selectedDay!)
                          : _formatMonth(month),
                      style: DSTextStyle.labelLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _c.text.primary,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _c.brand.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(DSRadius.pill),
                      ),
                      child: Text(
                        '${visibleEvents.length}',
                        style: DSTextStyle.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _c.brand.primaryActive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
            ],
          ),
        ),
        if (visibleEvents.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => CalendarEventCard(
                event: visibleEvents[index],
                showTypeTag: true,
              ),
              childCount: visibleEvents.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.s8)),
      ],
    );
  }

  static const _monthNames = [
    'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'December',
  ];

  String _formatMonth(DateTime m) =>
      '${_monthNames[m.month - 1]} ${m.year}';

  String _formatSelectedDay(DateTime d) =>
      '${d.day}. ${_monthNames[d.month - 1]}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar,
              size: 40, color: _c.text.muted),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Ingen jobs denne periode',
            style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.secondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 40, color: _c.state.danger),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Kunne ikke indlæse kalender',
            style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Prøv igen',
            onTap: onRetry,
            variant: DSButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
