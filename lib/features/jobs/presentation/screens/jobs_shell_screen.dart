import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/widgets/animated_card.dart';
import 'package:dj_tilbud_app/core/widgets/skeleton_loading.dart';
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
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/quote_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/service_offer_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/empty_jobs_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class JobsShellScreen extends ConsumerStatefulWidget {
  const JobsShellScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<JobsShellScreen> createState() => _JobsShellScreenState();
}

class _JobsShellScreenState extends ConsumerState<JobsShellScreen> {
  bool _calendarMode = false;

  @override
  Widget build(BuildContext context) {
    final isDj = widget.role == MusicianRole.dj;

    if (_calendarMode) {
      if (isDj) {
        final wonEvents =
            ref.watch(calendarEventsProvider(MusicianRole.dj)).valueOrNull ?? [];

        return Scaffold(
          backgroundColor: _c.bg.canvas,
          appBar: AppBar(
            title: const Text('DJ Tilbud'),
            backgroundColor: _c.bg.surface,
            surfaceTintColor: _c.bg.surface,
            actions: [
              if (wonEvents.isNotEmpty)
                IconButton(
                  icon: Icon(LucideIcons.share2, color: _c.text.primary),
                  tooltip: 'Eksporter kalender',
                  onPressed: () => showIcalExportBottomSheet(
                    context,
                    events: wonEvents,
                    isDj: true,
                  ),
                ),
              _ModeToggleButton(
                isCalendarMode: true,
                onToggle: () => setState(() => _calendarMode = false),
              ),
            ],
          ),
          body: const _DjCalendarView(),
        );
      } else {
        final wonEvents =
            ref.watch(calendarEventsProvider(MusicianRole.instrumentalist)).valueOrNull ?? [];

        return Scaffold(
          backgroundColor: _c.bg.canvas,
          appBar: AppBar(
            title: const Text('Mine jobs'),
            backgroundColor: _c.bg.surface,
            surfaceTintColor: _c.bg.surface,
            actions: [
              if (wonEvents.isNotEmpty)
                IconButton(
                  icon: Icon(LucideIcons.share2, color: _c.text.primary),
                  tooltip: 'Eksporter kalender',
                  onPressed: () => showIcalExportBottomSheet(
                    context,
                    events: wonEvents,
                    isDj: false,
                  ),
                ),
              _ModeToggleButton(
                isCalendarMode: true,
                onToggle: () => setState(() => _calendarMode = false),
              ),
            ],
          ),
          body: const _InstrumentalistCalendarView(),
        );
      }
    }

    final wonActionCount = isDj
        ? ref.watch(djWonActionCountProvider)
        : ref.watch(musicianWonActionCountProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DJ Tilbud'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          actions: [
            if (isDj) _FilterToggleButton(),
            _ModeToggleButton(
              isCalendarMode: false,
              onToggle: () => setState(() => _calendarMode = true),
            ),
          ],
          bottom: DSTabBar(
            isScrollable: true,
            coloredIndicatorOnly: true,
            tabs: [
              DSTabItem(
                label: 'Nye jobs',
                icon: LucideIcons.listMusic,
                activeIcon: LucideIcons.listMusic,
                activeColor: _c.brand.accent,
              ),
              DSTabItem(
                label: widget.role == MusicianRole.dj
                    ? 'Bud afgivet'
                    : 'Tilbud afgivet',
                icon: LucideIcons.send,
                activeIcon: LucideIcons.send,
                activeColor: _c.state.warning,
              ),
              DSTabItem(
                label: widget.role == MusicianRole.dj
                    ? 'Du har vundet'
                    : 'Jobs accepteret',
                icon: LucideIcons.calendarCheck,
                activeIcon: LucideIcons.calendarCheck,
                activeColor: _c.state.success,
                badgeCount: wonActionCount,
              ),
              DSTabItem(
                label: 'Udgået',
                icon: LucideIcons.archive,
                activeIcon: LucideIcons.archive,
                activeColor: _c.text.muted,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: isDj
              ? [
                  _DjNewJobsTab(),
                  _DjQuotesTab(filter: QuoteStatus.pending),
                  _DjQuotesTab(filter: QuoteStatus.won),
                  _DjExpiredTab(),
                ]
              : [
                  _InstrumentalistNewJobsTab(),
                  _InstrumentalistOffersTab(filter: ServiceOfferStatus.sent),
                  _InstrumentalistOffersTab(filter: ServiceOfferStatus.won),
                  _InstrumentalistOffersTab(filter: ServiceOfferStatus.lost),
                ],
        ),
      ),
    );
  }
}

// ── Shared AppBar buttons ──

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton(
      {required this.isCalendarMode, required this.onToggle});

  final bool isCalendarMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isCalendarMode ? LucideIcons.layoutList : LucideIcons.calendarDays,
        color: _c.text.primary,
      ),
      tooltip: isCalendarMode ? 'Standard visning' : 'Kalender',
      onPressed: onToggle,
    );
  }
}

/// Jobfiltre toggle button shown in AppBar for DJs in standard mode.
class _FilterToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(djFiltersEnabledProvider);
    return IconButton(
      icon: Icon(
        enabled ? LucideIcons.sliders : LucideIcons.filterX,
        color: enabled ? _c.brand.primaryActive : _c.text.muted,
      ),
      tooltip: enabled ? 'Jobfiltre: Til' : 'Jobfiltre: Fra',
      onPressed: () =>
          ref.read(djFiltersEnabledProvider.notifier).state = !enabled,
    );
  }
}

// ── DJ Jobs Calendar View ──

class _DjCalendarView extends ConsumerStatefulWidget {
  const _DjCalendarView();

  @override
  ConsumerState<_DjCalendarView> createState() => _DjCalendarViewState();
}

class _DjCalendarViewState extends ConsumerState<_DjCalendarView> {
  late DateTime _month;
  DateTime? _selectedDay;
  bool _showNew = true;
  bool _showSent = true;
  bool _showWon = true;
  bool _isEditingUnavailable = false;

  static const _monthNames = [
    'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<CalendarEvent> _buildEvents({
    required List<Job> newJobs,
    required List<DjQuote> pendingQuotes,
    required List<CalendarEvent> wonEvents,
  }) {
    final events = <CalendarEvent>[];
    if (_showNew) events.addAll(newJobs.map(_jobToEvent));
    if (_showSent) events.addAll(pendingQuotes.map(_quoteToEvent));
    if (_showWon) events.addAll(wonEvents);
    return events;
  }

  List<CalendarEvent> _eventsForView(List<CalendarEvent> all) {
    if (_selectedDay != null && !_isEditingUnavailable) {
      return all
          .where((e) =>
              e.date.year == _selectedDay!.year &&
              e.date.month == _selectedDay!.month &&
              e.date.day == _selectedDay!.day)
          .toList();
    }
    return all
        .where((e) =>
            e.date.year == _month.year && e.date.month == _month.month)
        .toList();
  }

  void _onDayTapped(
    DateTime day,
    Map<String, int> unavailableMap,
  ) {
    if (_isEditingUnavailable) {
      // In edit mode: tap toggles unavailability
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      ref.read(djUnavailableDatesProvider.notifier).toggle(dateStr);
    } else {
      // Normal mode: tap selects day
      setState(() {
        _selectedDay = (_selectedDay != null &&
                _selectedDay!.year == day.year &&
                _selectedDay!.month == day.month &&
                _selectedDay!.day == day.day)
            ? null
            : day;
      });
    }
  }

  void _navigate(
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
        if (job != null) {
          context.pushNamed(AppRoutes.djQuoteForm, extra: job);
        }
      case CalendarEventKind.sent:
        final quote = pendingById[event.id];
        if (quote != null) {
          context.pushNamed(AppRoutes.quoteDetail, extra: quote);
        }
      case CalendarEventKind.won:
        if (event.type == CalendarEventType.internal && event.jobId != null) {
          final quote = wonByJobId[event.jobId!];
          if (quote != null) {
            context.pushNamed(AppRoutes.quoteDetail, extra: quote);
          }
        } else if (event.type == CalendarEventType.external &&
            event.extJobId != null) {
          final extJob = extJobById[event.extJobId!];
          if (extJob != null) {
            context.pushNamed(AppRoutes.extJobDetail, extra: extJob);
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newJobsAsync = ref.watch(filteredDjJobsProvider);
    final pendingAsync = ref.watch(pendingDjQuotesProvider);
    final wonAsync = ref.watch(calendarEventsProvider(MusicianRole.dj));
    final unavailableAsync = ref.watch(djUnavailableDatesProvider);
    final wonQuotesAsync = ref.watch(wonDjQuotesProvider);
    final extJobsAsync = ref.watch(djExtJobsProvider);
    final filtersEnabled = ref.watch(djFiltersEnabledProvider);

    final newJobs = newJobsAsync.valueOrNull ?? [];
    final pending = pendingAsync.valueOrNull ?? [];
    final won = wonAsync.valueOrNull ?? [];
    final unavailableMap = unavailableAsync.valueOrNull ?? {};
    final unavailableDates = Set<String>.from(unavailableMap.keys);

    // Navigation lookup maps
    final jobById = {for (final j in newJobs) j.id: j};
    final pendingById = {for (final q in pending) q.id: q};
    final wonByJobId = {
      for (final q in wonQuotesAsync.valueOrNull ?? <DjQuote>[]) q.jobId: q
    };
    final extJobById = {
      for (final e in extJobsAsync.valueOrNull ?? <ExtJob>[]) e.id: e
    };

    final allEvents = _buildEvents(
      newJobs: newJobs,
      pendingQuotes: pending,
      wonEvents: won,
    );
    final visibleEvents = _eventsForView(allEvents);

    final selectedLabel = _selectedDay != null && !_isEditingUnavailable
        ? '${_selectedDay!.day}. ${_monthNames[_selectedDay!.month - 1]}'
        : '${_monthNames[_month.month - 1]} ${_month.year}';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: DSSpacing.s2),
              CalendarHeader(
                month: _month,
                onMonthChanged: (m) => setState(() {
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
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Filter row ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    _JobFilterChip(
                      enabled: filtersEnabled,
                      onToggle: () => ref
                          .read(djFiltersEnabledProvider.notifier)
                          .state = !filtersEnabled,
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    _KindChip(
                      label: 'Nye jobs',
                      active: _showNew,
                      activeColor: _c.state.info,
                      onTap: () => setState(() => _showNew = !_showNew),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    _KindChip(
                      label: 'Bud afgivet',
                      active: _showSent,
                      activeColor: _c.state.warning,
                      onTap: () =>
                          setState(() => _showSent = !_showSent),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    _KindChip(
                      label: 'Vundet',
                      active: _showWon,
                      activeColor: _c.state.success,
                      onTap: () => setState(() => _showWon = !_showWon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Unavailable dates panel ──
              _UnavailableDatesPanel(
                isEditing: _isEditingUnavailable,
                onToggleEdit: () => setState(() {
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
                unavailableDays: unavailableDates,
                onDaySelected: (day) =>
                    _onDayTapped(day, unavailableMap),
              ),
              const SizedBox(height: DSSpacing.s4),
              Divider(height: 1, color: _c.border.subtle),
              const SizedBox(height: DSSpacing.s2),
              // ── Section header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Text(
                      selectedLabel,
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
                        borderRadius:
                            BorderRadius.circular(DSRadius.pill),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendar,
                      size: 40, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    _isEditingUnavailable
                        ? 'Tryk på datoer for at markere dem'
                        : (_selectedDay != null
                            ? 'Ingen jobs denne dag'
                            : 'Ingen jobs denne måned'),
                    style: DSTextStyle.labelMd.copyWith(
                        fontSize: 15, color: _c.text.secondary),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = visibleEvents[index];
                return CalendarEventCard(
                  event: event,
                  showTypeTag: true,
                  onTap: () => _navigate(
                    context,
                    event,
                    jobById,
                    pendingById,
                    wonByJobId,
                    extJobById,
                  ),
                );
              },
              childCount: visibleEvents.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.s8)),
      ],
    );
  }
}

// ── Instrumentalist Jobs Calendar View ──

class _InstrumentalistCalendarView extends ConsumerStatefulWidget {
  const _InstrumentalistCalendarView();

  @override
  ConsumerState<_InstrumentalistCalendarView> createState() =>
      _InstrumentalistCalendarViewState();
}

class _InstrumentalistCalendarViewState
    extends ConsumerState<_InstrumentalistCalendarView> {
  late DateTime _month;
  DateTime? _selectedDay;
  bool _showNew = true;
  bool _showSent = true;
  bool _showWon = true;

  static const _monthNames = [
    'Januar', 'Februar', 'Marts', 'April', 'Maj', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<CalendarEvent> _buildEvents({
    required List<Job> newJobs,
    required List<ServiceOffer> sentOffers,
    required List<CalendarEvent> wonEvents,
  }) {
    final events = <CalendarEvent>[];
    if (_showNew) events.addAll(newJobs.map(_jobToEvent));
    if (_showSent) events.addAll(sentOffers.map(_offerToEvent));
    if (_showWon) events.addAll(wonEvents);
    return events;
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
        .where((e) =>
            e.date.year == _month.year && e.date.month == _month.month)
        .toList();
  }

  void _navigate(BuildContext context, CalendarEvent event,
      Map<int, Job> jobById, Map<int, ServiceOffer> sentById,
      Map<int, ServiceOffer> wonById) {
    switch (event.kind) {
      case CalendarEventKind.newJob:
        final job = jobById[event.id];
        if (job != null) {
          context.pushNamed(AppRoutes.instrumentalistOfferForm, extra: job);
        }
      case CalendarEventKind.sent:
        final offer = sentById[event.id];
        if (offer != null) {
          context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
        }
      case CalendarEventKind.won:
        final offer = wonById[event.id];
        if (offer != null) {
          context.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newJobsAsync = ref.watch(combinedInstrumentalistJobsProvider);
    final sentAsync = ref.watch(sentServiceOffersProvider);
    final wonEventsAsync = ref.watch(calendarEventsProvider(MusicianRole.instrumentalist));
    final wonOffersAsync = ref.watch(wonServiceOffersProvider);

    final newJobs = newJobsAsync.valueOrNull ?? [];
    final sent = sentAsync.valueOrNull ?? [];
    final wonEvents = wonEventsAsync.valueOrNull ?? [];
    final wonOffers = wonOffersAsync.valueOrNull ?? [];

    final jobById = {for (final j in newJobs) j.id: j};
    final sentById = {for (final o in sent) o.id: o};
    final wonById = {for (final o in wonOffers) o.id: o};

    final allEvents = _buildEvents(
      newJobs: newJobs,
      sentOffers: sent,
      wonEvents: wonEvents,
    );
    final visibleEvents = _eventsForView(allEvents);

    final selectedLabel = _selectedDay != null
        ? '${_selectedDay!.day}. ${_monthNames[_selectedDay!.month - 1]}'
        : '${_monthNames[_month.month - 1]} ${_month.year}';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: DSSpacing.s2),
              CalendarHeader(
                month: _month,
                onMonthChanged: (m) => setState(() {
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
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Filter chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    _KindChip(
                      label: 'Nye jobs',
                      active: _showNew,
                      activeColor: _c.state.info,
                      onTap: () => setState(() => _showNew = !_showNew),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    _KindChip(
                      label: 'Bud afgivet',
                      active: _showSent,
                      activeColor: _c.state.warning,
                      onTap: () => setState(() => _showSent = !_showSent),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    _KindChip(
                      label: 'Vundet',
                      active: _showWon,
                      activeColor: _c.state.success,
                      onTap: () => setState(() => _showWon = !_showWon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Calendar grid ──
              CalendarGrid(
                month: _month,
                events: allEvents,
                selectedDay: _selectedDay,
                onDaySelected: (day) => setState(() {
                  _selectedDay = (_selectedDay != null &&
                          _selectedDay!.year == day.year &&
                          _selectedDay!.month == day.month &&
                          _selectedDay!.day == day.day)
                      ? null
                      : day;
                }),
              ),
              const SizedBox(height: DSSpacing.s4),
              Divider(height: 1, color: _c.border.subtle),
              const SizedBox(height: DSSpacing.s2),
              // ── Section header ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Text(
                      selectedLabel,
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
                        borderRadius:
                            BorderRadius.circular(DSRadius.pill),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendar,
                      size: 40, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    _selectedDay != null
                        ? 'Ingen jobs denne dag'
                        : 'Ingen jobs denne måned',
                    style: DSTextStyle.labelMd
                        .copyWith(fontSize: 15, color: _c.text.secondary),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = visibleEvents[index];
                return CalendarEventCard(
                  event: event,
                  showTypeTag: true,
                  onTap: () => _navigate(
                      context, event, jobById, sentById, wonById),
                );
              },
              childCount: visibleEvents.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.s8)),
      ],
    );
  }
}

// ── Calendar helper converters ──

CalendarEvent _jobToEvent(Job job) => CalendarEvent(
      id: job.id,
      date: job.date,
      label: job.eventType,
      type: CalendarEventType.internal,
      kind: CalendarEventKind.newJob,
      startTime: job.timeStart.isEmpty ? null : job.timeStart,
      endTime: job.timeEnd.isEmpty ? null : job.timeEnd,
      location: job.city.isEmpty ? null : job.city,
      region: job.region.isEmpty ? null : job.region,
      guestsAmount: job.guestsAmount,
      jobId: job.id,
    );

CalendarEvent _quoteToEvent(DjQuote quote) => CalendarEvent(
      id: quote.id,
      date: quote.job.date,
      label: quote.job.eventType,
      type: CalendarEventType.internal,
      kind: CalendarEventKind.sent,
      startTime:
          quote.job.timeStart.isEmpty ? null : quote.job.timeStart,
      endTime: quote.job.timeEnd.isEmpty ? null : quote.job.timeEnd,
      location: quote.job.city.isEmpty ? null : quote.job.city,
      region: quote.job.region.isEmpty ? null : quote.job.region,
      guestsAmount: quote.job.guestsAmount,
      jobId: quote.jobId,
    );

CalendarEvent _offerToEvent(ServiceOffer offer) => CalendarEvent(
      id: offer.id,
      date: offer.job.date,
      label: offer.job.eventType,
      type: offer.isExtJob ? CalendarEventType.external : CalendarEventType.internal,
      kind: CalendarEventKind.sent,
      startTime: offer.job.timeStart.isEmpty ? null : offer.job.timeStart,
      endTime: offer.job.timeEnd.isEmpty ? null : offer.job.timeEnd,
      location: offer.job.city.isEmpty ? null : offer.job.city,
      region: offer.job.region.isEmpty ? null : offer.job.region,
      guestsAmount: offer.job.guestsAmount > 0 ? offer.job.guestsAmount : null,
      jobId: offer.isExtJob ? null : offer.jobId,
      extJobId: offer.isExtJob ? offer.extJobId : null,
    );

// ── Calendar filter chips ──

class _JobFilterChip extends StatelessWidget {
  const _JobFilterChip({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: DSSpacing.s2, vertical: 6),
        decoration: BoxDecoration(
          color: enabled
              ? _c.brand.primary.withValues(alpha: 0.12)
              : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(
            color: enabled ? _c.brand.primaryActive : _c.border.subtle,
            width: enabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? LucideIcons.sliders : LucideIcons.filterX,
              size: 13,
              color: enabled ? _c.brand.primaryActive : _c.text.muted,
            ),
            const SizedBox(width: 4),
            Text(
              'Jobfiltre',
              style: DSTextStyle.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? _c.brand.primaryActive : _c.text.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s3, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(
            color: active ? activeColor : _c.border.subtle,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: DSTextStyle.labelSm.copyWith(
            fontWeight: FontWeight.w600,
            color: active ? activeColor : _c.text.secondary,
          ),
        ),
      ),
    );
  }
}

class _UnavailableDatesPanel extends StatelessWidget {
  const _UnavailableDatesPanel({
    required this.isEditing,
    required this.onToggleEdit,
  });

  final bool isEditing;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
        decoration: BoxDecoration(
          color: isEditing
              ? _c.state.danger.withValues(alpha: 0.06)
              : _c.state.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: isEditing
                ? _c.state.danger.withValues(alpha: 0.3)
                : _c.state.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isEditing ? LucideIcons.calendarDays : LucideIcons.ban,
              size: 16,
              color: isEditing ? _c.state.danger : _c.state.warning,
            ),
            const SizedBox(width: DSSpacing.s2),
            Expanded(
              child: Text(
                isEditing
                    ? 'Tryk på en dato for at markere/fjerne den som optaget'
                    : 'Marker datoer som optaget for at skjule jobs på de dage',
                style: DSTextStyle.labelSm.copyWith(
                  color: isEditing ? _c.state.danger : _c.text.secondary,
                ),
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            GestureDetector(
              onTap: onToggleEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s2, vertical: 4),
                decoration: BoxDecoration(
                  color: isEditing
                      ? _c.state.danger
                      : _c.state.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(
                  isEditing ? 'Luk' : 'Rediger',
                  style: DSTextStyle.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isEditing
                        ? Colors.white
                        : _c.state.warning,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DJ tabs ──

class _DjNewJobsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(filteredDjJobsProvider);
    final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
    final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;

    return jobsAsync.when(
      loading: () => const SkeletonListView(),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.read(newDjJobsProvider.notifier).refresh(),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => ref.read(newDjJobsProvider.notifier).refresh(),
            child: ListView(
              children: const [
                SizedBox(height: 80),
                EmptyJobsView(
                  message: 'Ingen nye jobs lige nu.',
                  icon: LucideIcons.searchX,
                ),
              ],
            ),
          );
        }
        // Sort: biddable jobs first (by date asc), colliding jobs last (by date asc)
        final sorted = [...jobs]..sort((a, b) {
            final aColliding = _isDateColliding(a, quotes, extJobs);
            final bColliding = _isDateColliding(b, quotes, extJobs);
            if (aColliding != bColliding) return aColliding ? 1 : -1;
            return a.date.compareTo(b.date);
          });

        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(newDjJobsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final job = sorted[index];
              final colliding = _isDateColliding(job, quotes, extJobs);
              return AnimatedCard(
                index: index,
                child: JobCard(
                  job: job,
                  onTap: () => context.pushNamed(
                    AppRoutes.djQuoteForm,
                    extra: job,
                  ),
                  isColliding: colliding,
                  djTier: djTier,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Mirrors `collidingQuote` from the web app.
bool _isDateColliding(Job job, List<DjQuote> quotes, List<ExtJob> extJobs) {
  final sameDay = (DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (extJobs.any((e) => sameDay(e.date, job.date))) return true;

  final activeOnDate = quotes.where((q) =>
      sameDay(q.job.date, job.date) &&
      q.jobId != job.id &&
      q.status != QuoteStatus.lost &&
      q.status != QuoteStatus.overwritten);

  if (activeOnDate.any((q) => q.status == QuoteStatus.won)) return true;

  final pending = activeOnDate.where((q) => q.status == QuoteStatus.pending);
  return pending.length >= 2;
}

class _DjQuotesTab extends ConsumerWidget {
  const _DjQuotesTab({required this.filter});

  final QuoteStatus filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = switch (filter) {
      QuoteStatus.pending => ref.watch(pendingDjQuotesProvider),
      QuoteStatus.won => ref.watch(wonDjQuotesProvider),
      _ => ref.watch(expiredDjQuotesProvider),
    };

    return quotesAsync.when(
      loading: () => const SkeletonListView(),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.read(djQuotesProvider.notifier).refresh(),
      ),
      data: (quotes) {
        if (quotes.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => ref.read(djQuotesProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 80),
                EmptyJobsView(message: _emptyMessageForQuoteStatus(filter)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(djQuotesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: quotes.length,
            itemBuilder: (context, index) => AnimatedCard(
              index: index,
              child: QuoteCard(
                quote: quotes[index],
                onTap: () => context.pushNamed(
                  AppRoutes.quoteDetail,
                  extra: quotes[index],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _emptyMessageForQuoteStatus(QuoteStatus status) {
    return switch (status) {
      QuoteStatus.pending => 'Du har ikke afgivet nogen bud endnu.',
      QuoteStatus.won => 'Du har ikke vundet nogen jobs endnu.',
      _ => 'Ingen udgåede bud.',
    };
  }
}

class _DjExpiredTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(expiredDjQuotesProvider);

    return quotesAsync.when(
      loading: () => const SkeletonListView(),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.read(djQuotesProvider.notifier).refresh(),
      ),
      data: (quotes) {
        if (quotes.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => ref.read(djQuotesProvider.notifier).refresh(),
            child: ListView(
              children: const [
                SizedBox(height: 80),
                EmptyJobsView(message: 'Ingen udgåede bud.'),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(djQuotesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: quotes.length,
            itemBuilder: (context, index) => AnimatedCard(
              index: index,
              child: QuoteCard(
                quote: quotes[index],
                onTap: () => context.pushNamed(
                  AppRoutes.quoteDetail,
                  extra: quotes[index],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Instrumentalist tabs ──

class _InstrumentalistNewJobsTab extends ConsumerWidget {
  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(newInstrumentalistJobsProvider.notifier).refresh(),
      Future(() => ref.invalidate(instrumentalistExtJobsProvider)),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(combinedInstrumentalistJobsProvider);

    return jobsAsync.when(
      loading: () => const SkeletonListView(),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => _refresh(ref),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => _refresh(ref),
            child: ListView(
              children: const [
                SizedBox(height: 80),
                EmptyJobsView(
                  message: 'Ingen nye jobs i dine regioner lige nu.',
                  icon: LucideIcons.searchX,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => _refresh(ref),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: jobs.length,
            itemBuilder: (context, index) => AnimatedCard(
              index: index,
              child: JobCard(
                job: jobs[index],
                musicianPrice: calculateMusicianOfferPrice(
                  jobs[index].requestedMusicianHours,
                  jobs[index].createdAt,
                ),
                onTap: () => context.pushNamed(
                  AppRoutes.instrumentalistOfferForm,
                  extra: jobs[index],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InstrumentalistOffersTab extends ConsumerWidget {
  const _InstrumentalistOffersTab({required this.filter});

  final ServiceOfferStatus filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = switch (filter) {
      ServiceOfferStatus.sent => ref.watch(sentServiceOffersProvider),
      ServiceOfferStatus.won => ref.watch(wonServiceOffersProvider),
      ServiceOfferStatus.lost => ref.watch(expiredServiceOffersProvider),
    };

    return offersAsync.when(
      loading: () => const SkeletonListView(),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () =>
            ref.read(serviceOffersProvider.notifier).refresh(),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () =>
                ref.read(serviceOffersProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 80),
                EmptyJobsView(
                    message: _emptyMessageForOfferStatus(filter)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () =>
              ref.read(serviceOffersProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: offers.length,
            itemBuilder: (context, index) => AnimatedCard(
              index: index,
              child: ServiceOfferCard(
                offer: offers[index],
                onTap: () => context.pushNamed(
                  AppRoutes.serviceOfferDetail,
                  extra: offers[index],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _emptyMessageForOfferStatus(ServiceOfferStatus status) {
    return switch (status) {
      ServiceOfferStatus.sent => 'Du har ikke afgivet nogen tilbud endnu.',
      ServiceOfferStatus.won => 'Ingen accepterede jobs endnu.',
      ServiceOfferStatus.lost => 'Ingen udgåede tilbud.',
    };
  }
}

// ── Shared ──

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: _c.state.danger),
            const SizedBox(height: DSSpacing.s4),
            Text(
              'Noget gik galt',
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              message,
              style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s4),
            DSButton(
              label: 'Prøv igen',
              variant: DSButtonVariant.primary,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
