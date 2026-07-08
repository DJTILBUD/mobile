import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/calendar_header.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/ical_export_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/widgets/unavailable_dates_panel.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/providers/calendar_reminder_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  DateTime? _selectedDay;
  bool _showNew = true;
  bool _showSent = true;
  bool _showWon = true;
  bool _isEditingUnavailable = false;

  static const _monthNames = [
    'Januar',
    'Februar',
    'Marts',
    'April',
    'Maj',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<CalendarEvent> _buildEvents({
    required List<Job> newJobs,
    required List<CalendarEvent> sentEvents,
    required List<CalendarEvent> wonEvents,
  }) {
    return [
      if (_showNew) ...newJobs.map(_jobToEvent),
      if (_showSent) ...sentEvents,
      if (_showWon) ...wonEvents,
    ];
  }

  /// In edit mode a tap toggles the date's availability; otherwise it selects
  /// the day to filter the event list below (existing behaviour).
  void _onDayTapped(DateTime day, Map<String, int> unavailableMap, bool isDj) {
    if (_isEditingUnavailable) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final wasUnavailable = unavailableMap.containsKey(dateStr);
      if (isDj) {
        ref.read(djUnavailableDatesProvider.notifier).toggle(dateStr);
      } else {
        ref.read(musicianUnavailableDatesProvider.notifier).toggle(dateStr);
      }
      if (wasUnavailable) {
        AnalyticsService.logDateUnmarkedUnavailable();
      } else {
        AnalyticsService.logDateMarkedUnavailable();
        ref.read(calendarReminderProvider.notifier).markHandled();
      }
    } else {
      setState(() {
        _selectedDay =
            (_selectedDay != null &&
                    _selectedDay!.year == day.year &&
                    _selectedDay!.month == day.month &&
                    _selectedDay!.day == day.day)
                ? null
                : day;
      });
    }
  }

  List<CalendarEvent> _eventsForView(List<CalendarEvent> all) {
    if (_selectedDay != null && !_isEditingUnavailable) {
      return all
          .where(
            (e) =>
                e.date.year == _selectedDay!.year &&
                e.date.month == _selectedDay!.month &&
                e.date.day == _selectedDay!.day,
          )
          .toList();
    }
    return all
        .where(
          (e) => e.date.year == _month.year && e.date.month == _month.month,
        )
        .toList();
  }

  void _navigateDj(
    BuildContext context,
    CalendarEvent event,
    Map<int, Job> jobById,
    Map<int, DjQuote> pendingById,
    Map<int, DjQuote> wonByJobId,
    Map<int, ExtJob> extJobById,
  ) {
    switch (event.kind) {
      case CalendarEventKind.newJob:
        final job = jobById[event.jobId ?? event.id];
        if (job != null) context.pushNamed(AppRoutes.djQuoteForm, extra: job);
      case CalendarEventKind.sent:
        final quote = pendingById[event.id];
        if (quote != null)
          context.pushNamed(AppRoutes.quoteDetail, extra: quote);
      case CalendarEventKind.won:
        if (event.type == CalendarEventType.internal && event.jobId != null) {
          final quote = wonByJobId[event.jobId!];
          if (quote != null)
            context.pushNamed(AppRoutes.quoteDetail, extra: quote);
        } else if (event.type == CalendarEventType.external &&
            event.extJobId != null) {
          final extJob = extJobById[event.extJobId!];
          if (extJob != null)
            context.pushNamed(AppRoutes.extJobDetail, extra: extJob);
        }
    }
  }

  void _navigateInstrumentalist(
    BuildContext context,
    CalendarEvent event,
    Map<int, Job> jobById,
    Map<int, ServiceOffer> sentById,
    Map<int, ServiceOffer> wonById,
  ) {
    switch (event.kind) {
      case CalendarEventKind.newJob:
        final job = jobById[event.id];
        if (job != null)
          context.pushNamed(AppRoutes.instrumentalistOfferForm, extra: job);
      case CalendarEventKind.sent:
        final offer = sentById[event.id];
        if (offer != null)
          context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
      case CalendarEventKind.won:
        final offer = wonById[event.id];
        if (offer != null)
          context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final isDj = widget.role == MusicianRole.dj;

    // Manually-marked unavailable ("optaget") dates for the current user.
    final unavailableAsync =
        isDj
            ? ref.watch(djUnavailableDatesProvider)
            : ref.watch(musicianUnavailableDatesProvider);
    final unavailableMap = unavailableAsync.valueOrNull ?? <String, int>{};
    final unavailableDays = unavailableMap.keys.toSet();

    // ── Data ──
    final newJobs =
        isDj
            ? (ref.watch(filteredDjJobsProvider).valueOrNull ?? <Job>[])
            : (ref.watch(combinedInstrumentalistJobsProvider).valueOrNull ??
                <Job>[]);

    final sentEvents =
        isDj
            ? (ref.watch(pendingDjQuotesProvider).valueOrNull ?? <DjQuote>[])
                .map(_quoteToEvent)
                .toList()
            : (ref.watch(sentServiceOffersProvider).valueOrNull ??
                    <ServiceOffer>[])
                .map(_offerToEvent)
                .toList();

    final wonEvents =
        ref.watch(calendarEventsProvider(widget.role)).valueOrNull ??
        <CalendarEvent>[];

    // Navigation lookup maps
    final jobById = {for (final j in newJobs) j.id: j};
    final pendingDjById =
        isDj
            ? {
              for (final q
                  in ref.watch(pendingDjQuotesProvider).valueOrNull ??
                      <DjQuote>[])
                q.id: q,
            }
            : <int, DjQuote>{};
    final wonDjByJobId =
        isDj
            ? {
              for (final q
                  in ref.watch(wonDjQuotesProvider).valueOrNull ?? <DjQuote>[])
                q.jobId: q,
            }
            : <int, DjQuote>{};
    final extJobById =
        isDj
            ? {
              for (final e
                  in ref.watch(djExtJobsProvider).valueOrNull ?? <ExtJob>[])
                e.id: e,
            }
            : <int, ExtJob>{};
    final sentMusicianById =
        !isDj
            ? {
              for (final o
                  in ref.watch(sentServiceOffersProvider).valueOrNull ??
                      <ServiceOffer>[])
                o.id: o,
            }
            : <int, ServiceOffer>{};
    final wonMusicianById =
        !isDj
            ? {
              for (final o
                  in ref.watch(wonServiceOffersProvider).valueOrNull ??
                      <ServiceOffer>[])
                o.id: o,
            }
            : <int, ServiceOffer>{};

    final allEvents = _buildEvents(
      newJobs: newJobs,
      sentEvents: sentEvents,
      wonEvents: wonEvents,
    );
    final visibleEvents = _eventsForView(allEvents);

    final selectedLabel =
        _selectedDay != null
            ? '${_selectedDay!.day}. ${_monthNames[_selectedDay!.month - 1]}'
            : '${_monthNames[_month.month - 1]} ${_month.year}';

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        title: Text(
          'Kalender',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        iconTheme: IconThemeData(color: c.text.primary),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: DSSpacing.s2),
                CalendarHeader(
                  month: _month,
                  onMonthChanged:
                      (m) => setState(() {
                        _month = m;
                        _selectedDay = null;
                      }),
                  onTodayTapped: () {
                    final now = DateTime.now();
                    setState(() {
                      _month = DateTime(now.year, now.month);
                      _selectedDay = null;
                    });
                  },
                  onShare:
                      wonEvents.isNotEmpty
                          ? () => showIcalExportBottomSheet(
                            context,
                            events: wonEvents,
                            isDj: isDj,
                          )
                          : null,
                ),
                const SizedBox(height: DSSpacing.s2),
                // ── Filter chips ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CalFilterChip(
                          label: 'Nye jobs',
                          active: _showNew,
                          activeColor: c.state.info,
                          onTap: () => setState(() => _showNew = !_showNew),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Expanded(
                        child: _CalFilterChip(
                          label: isDj ? 'Bud afgivet' : 'Tilbud afgivet',
                          active: _showSent,
                          activeColor: c.state.warning,
                          onTap: () => setState(() => _showSent = !_showSent),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Expanded(
                        child: _CalFilterChip(
                          label: 'Vundet',
                          active: _showWon,
                          activeColor: c.state.success,
                          onTap: () => setState(() => _showWon = !_showWon),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.s2),
                // ── Mark-unavailable panel ──
                UnavailableDatesPanel(
                  isEditing: _isEditingUnavailable,
                  onToggleEdit:
                      () => setState(() {
                        _isEditingUnavailable = !_isEditingUnavailable;
                        if (_isEditingUnavailable) _selectedDay = null;
                      }),
                ),
                const SizedBox(height: DSSpacing.s2),
                // ── Calendar grid ──
                CalendarGrid(
                  month: _month,
                  events: allEvents,
                  selectedDay: _isEditingUnavailable ? null : _selectedDay,
                  unavailableDays: unavailableDays,
                  onDaySelected:
                      (day) => _onDayTapped(day, unavailableMap, isDj),
                  onMonthChanged:
                      (m) => setState(() {
                        _month = m;
                        _selectedDay = null;
                      }),
                ),
                const SizedBox(height: DSSpacing.s4),
                Divider(height: 1, color: c.border.subtle),
                const SizedBox(height: DSSpacing.s2),
                // ── Section label ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                  child: Row(
                    children: [
                      Text(
                        selectedLabel,
                        style: DSTextStyle.labelLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.text.primary,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                        ),
                        child: Text(
                          '${visibleEvents.length}',
                          style: DSTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.brand.primaryActive,
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendar, size: 40, color: c.text.muted),
                    const SizedBox(height: DSSpacing.s3),
                    Text(
                      _isEditingUnavailable
                          ? 'Tryk på datoer for at markere dem som optaget'
                          : (_selectedDay != null
                              ? 'Ingen jobs denne dag'
                              : 'Ingen jobs denne måned'),
                      style: DSTextStyle.labelMd.copyWith(
                        fontSize: 15,
                        color: c.text.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final event = visibleEvents[index];
                return CalendarEventCard(
                  event: event,
                  showTypeTag: true,
                  onTap:
                      () =>
                          isDj
                              ? _navigateDj(
                                context,
                                event,
                                jobById,
                                pendingDjById,
                                wonDjByJobId,
                                extJobById,
                              )
                              : _navigateInstrumentalist(
                                context,
                                event,
                                jobById,
                                sentMusicianById,
                                wonMusicianById,
                              ),
                );
              }, childCount: visibleEvents.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.s8)),
        ],
      ),
    );
  }
}

// ── Event converters ──

bool _isZeroTime(String t) => t.isEmpty || t.startsWith('00:00');

CalendarEvent _jobToEvent(Job job) => CalendarEvent(
  id: job.id,
  date: job.date,
  label: job.eventType,
  type: CalendarEventType.internal,
  kind: CalendarEventKind.newJob,
  startTime: _isZeroTime(job.timeStart) ? null : job.timeStart,
  endTime: _isZeroTime(job.timeEnd) ? null : job.timeEnd,
  location: job.city.isEmpty ? null : job.city,
  region: job.region.isEmpty ? null : job.region,
  guestsAmount: job.guestsAmount,
  budgetDisplay: job.budgetDisplay == 'Ikke angivet' ? null : job.budgetDisplay,
  jobId: job.id,
);

CalendarEvent _quoteToEvent(DjQuote quote) => CalendarEvent(
  id: quote.id,
  date: quote.job.date,
  label: quote.job.eventType,
  type: CalendarEventType.internal,
  kind: CalendarEventKind.sent,
  startTime: _isZeroTime(quote.job.timeStart) ? null : quote.job.timeStart,
  endTime: _isZeroTime(quote.job.timeEnd) ? null : quote.job.timeEnd,
  location: quote.job.city.isEmpty ? null : quote.job.city,
  region: quote.job.region.isEmpty ? null : quote.job.region,
  guestsAmount: quote.job.guestsAmount,
  budgetDisplay:
      quote.job.budgetDisplay == 'Ikke angivet'
          ? null
          : quote.job.budgetDisplay,
  jobId: quote.jobId,
);

CalendarEvent _offerToEvent(ServiceOffer offer) => CalendarEvent(
  id: offer.id,
  date: offer.job.date,
  label: offer.job.eventType,
  type:
      offer.isExtJob ? CalendarEventType.external : CalendarEventType.internal,
  kind: CalendarEventKind.sent,
  startTime: _isZeroTime(offer.job.timeStart) ? null : offer.job.timeStart,
  endTime: _isZeroTime(offer.job.timeEnd) ? null : offer.job.timeEnd,
  location: offer.job.city.isEmpty ? null : offer.job.city,
  region: offer.job.region.isEmpty ? null : offer.job.region,
  guestsAmount: offer.job.guestsAmount > 0 ? offer.job.guestsAmount : null,
  budgetDisplay:
      offer.job.budgetDisplay == 'Ikke angivet'
          ? null
          : offer.job.budgetDisplay,
  jobId: offer.isExtJob ? null : offer.jobId,
  extJobId: offer.isExtJob ? offer.extJobId : null,
);

// ── Filter chip ──

class _CalFilterChip extends StatelessWidget {
  const _CalFilterChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.12) : c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(
            color: active ? activeColor : c.border.subtle,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: DSTextStyle.labelSm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : c.text.secondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              active ? LucideIcons.check : LucideIcons.x,
              size: 11,
              color: active ? activeColor : c.text.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
