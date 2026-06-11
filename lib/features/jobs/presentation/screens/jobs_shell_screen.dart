import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
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
import 'package:dj_tilbud_app/features/jobs/domain/date_collision.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job_action.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/quote_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/service_offer_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/empty_jobs_view.dart';
import 'package:dj_tilbud_app/features/first_win/presentation/providers/first_win_provider.dart';
import 'package:dj_tilbud_app/features/first_win/presentation/widgets/first_win_dialog.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class JobsShellScreen extends ConsumerStatefulWidget {
  const JobsShellScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<JobsShellScreen> createState() => _JobsShellScreenState();
}

class _JobsShellScreenState extends ConsumerState<JobsShellScreen> {
  bool _calendarMode = false;
  bool _availabilityGateDismissed = false;
  bool _availabilityGateShowing = false;
  bool _firstWinShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDj = widget.role == MusicianRole.dj;
      final async =
          isDj
              ? ref.read(djUnavailableDatesProvider)
              : ref.read(musicianUnavailableDatesProvider);
      _checkAvailabilityGate(async);
      _checkFirstWinGate();
    });
  }

  Future<void> _checkFirstWinGate() async {
    if (_firstWinShowing) return;
    final eligible = await ref.read(
      firstWinEligibleProvider(widget.role).future,
    );
    if (!eligible || !mounted || _firstWinShowing) return;
    _firstWinShowing = true;
    await showFirstWinDialog(context, ref, widget.role);
    if (mounted) _firstWinShowing = false;
  }

  void _checkAvailabilityGate(AsyncValue<Map<String, int>> async) {
    if (_calendarMode) return;
    if (_availabilityGateDismissed) return;
    if (_availabilityGateShowing) return;
    final dateMap = async.valueOrNull;
    if (dateMap == null) return;
    final distinctMonths = dateMap.keys.map((d) => d.substring(0, 7)).toSet();
    if (distinctMonths.length >= 2) return;
    _availabilityGateShowing = true;
    final missingMonths = 2 - distinctMonths.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _availabilityGateShowing = false;
        return;
      }
      showDialog<void>(
        context: context,
        builder:
            (ctx) => _AvailabilityGateDialog(
              missingMonthsCount: missingMonths,
              onGoToCalendar: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _calendarMode = true;
                  _availabilityGateShowing = false;
                });
              },
              onRemindLater: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _availabilityGateDismissed = true;
                  _availabilityGateShowing = false;
                });
              },
            ),
      ).then((_) {
        if (mounted) setState(() => _availabilityGateShowing = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final isDj = widget.role == MusicianRole.dj;

    ref.listen<AsyncValue<Map<String, int>>>(djUnavailableDatesProvider, (
      _,
      next,
    ) {
      if (isDj) _checkAvailabilityGate(next);
    });
    ref.listen<AsyncValue<Map<String, int>>>(musicianUnavailableDatesProvider, (
      _,
      next,
    ) {
      if (!isDj) _checkAvailabilityGate(next);
    });
    ref.listen<AsyncValue<bool>>(firstWinEligibleProvider(widget.role), (
      _,
      next,
    ) {
      if (next.valueOrNull == true) _checkFirstWinGate();
    });

    if (_calendarMode) {
      if (isDj) {
        return Scaffold(
          backgroundColor: _c.bg.surface,
          appBar: AppBar(
            toolbarHeight: 64,
            title: const Text('DJTilbud'),
            backgroundColor: _c.bg.surface,
            surfaceTintColor: _c.bg.surface,
            actions: [
              const _FilterTogglePill(),
              _ModeTogglePill(
                isCalendarMode: true,
                onToggle: () {
                  setState(() {
                    _calendarMode = false;
                    _availabilityGateShowing = false;
                  });
                  AnalyticsService.logCalendarModeToggled(toMode: 'list');
                  _checkAvailabilityGate(ref.read(djUnavailableDatesProvider));
                },
              ),
            ],
          ),
          body: const _DjCalendarView(),
        );
      } else {
        return Scaffold(
          backgroundColor: _c.bg.surface,
          appBar: AppBar(
            toolbarHeight: 64,
            title: const Text('Mine jobs'),
            backgroundColor: _c.bg.surface,
            surfaceTintColor: _c.bg.surface,
            actions: [
              _ModeTogglePill(
                isCalendarMode: true,
                onToggle: () {
                  setState(() {
                    _calendarMode = false;
                    _availabilityGateShowing = false;
                  });
                  AnalyticsService.logCalendarModeToggled(toMode: 'list');
                  _checkAvailabilityGate(
                    ref.read(musicianUnavailableDatesProvider),
                  );
                },
              ),
            ],
          ),
          body: const _InstrumentalistCalendarView(),
        );
      }
    }

    final wonActionCount =
        isDj
            ? ref.watch(djQuoteActionCountProvider)
            : ref.watch(musicianWonActionCountProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: const Text('DJTilbud'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          actions: [
            if (isDj) const _FilterTogglePill(),
            _ModeTogglePill(
              isCalendarMode: false,
              onToggle: () {
                setState(() => _calendarMode = true);
                AnalyticsService.logCalendarModeToggled(toMode: 'calendar');
              },
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
                label: isDj ? 'Bud afgivet' : 'Tilbud afgivet',
                icon: LucideIcons.send,
                activeIcon: LucideIcons.send,
                activeColor: _c.state.warning,
              ),
              DSTabItem(
                label: isDj ? 'Du har vundet' : 'Jobs accepteret',
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
          children:
              isDj
                  ? [
                    _DjNewJobsTab(),
                    _DjQuotesTab(filter: QuoteStatus.pending),
                    const _DjWonQuotesTab(),
                    _DjExpiredTab(),
                  ]
                  : [
                    _InstrumentalistNewJobsTab(),
                    _InstrumentalistOffersTab(filter: ServiceOfferStatus.sent),
                    const _InstrumentalistWonOffersTab(),
                    _InstrumentalistOffersTab(filter: ServiceOfferStatus.lost),
                  ],
        ),
      ),
    );
  }
}

// ── AppBar action pills ──

/// Icon-only two-segment switch: list | calendar
class _ModeTogglePill extends StatelessWidget {
  const _ModeTogglePill({required this.isCalendarMode, required this.onToggle});

  final bool isCalendarMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _c.bg.inputBg,
            borderRadius: BorderRadius.circular(DSRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconSegment(
                icon: LucideIcons.layoutList,
                selected: !isCalendarMode,
              ),
              _IconSegment(
                icon: LucideIcons.calendarDays,
                selected: isCalendarMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconSegment extends StatelessWidget {
  const _IconSegment({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return AnimatedContainer(
      duration: DSMotion.normal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _c.bg.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        boxShadow: selected ? DSShadow.sm : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: selected ? _c.text.primary : _c.text.muted,
        ),
      ),
    );
  }
}

/// Filter on/off pill — text label + check/x icon
class _FilterTogglePill extends ConsumerWidget {
  const _FilterTogglePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final enabled = ref.watch(djFiltersEnabledProvider);
    final color = _c.state.success;
    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 14, bottom: 14),
      child: GestureDetector(
        onTap: () {
          final newEnabled = !enabled;
          ref.read(djFiltersEnabledProvider.notifier).state = newEnabled;
          AnalyticsService.logDjFiltersToggled(enabled: newEnabled);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s3,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.12) : _c.bg.inputBg,
            borderRadius: BorderRadius.circular(DSRadius.pill),
            border: Border.all(
              color: enabled ? color : _c.border.subtle,
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: DSTextStyle.labelSm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : _c.text.secondary,
                ),
                child: Text(enabled ? 'Filtre til' : 'Filtre fra'),
              ),
              const SizedBox(width: 4),
              Icon(
                enabled ? LucideIcons.check : LucideIcons.x,
                size: 12,
                color: enabled ? color : _c.text.secondary,
              ),
            ],
          ),
        ),
      ),
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
    required List<DjQuote> pendingQuotes,
    required List<CalendarEvent> wonEvents,
    required String? djTier,
  }) {
    final events = <CalendarEvent>[];
    if (_showNew) {
      events.addAll(
        newJobs.map(
          (j) =>
              _jobToEvent(j, budgetDisplay: djAdjustedBudgetLabel(j, djTier)),
        ),
      );
    }
    if (_showSent) events.addAll(pendingQuotes.map(_quoteToEvent));
    if (_showWon) events.addAll(wonEvents);
    return events;
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

  void _onDayTapped(DateTime day, Map<String, int> unavailableMap) {
    if (_isEditingUnavailable) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final isCurrentlyUnavailable = unavailableMap.containsKey(dateStr);
      ref.read(djUnavailableDatesProvider.notifier).toggle(dateStr);
      if (isCurrentlyUnavailable) {
        AnalyticsService.logDateUnmarkedUnavailable();
      } else {
        AnalyticsService.logDateMarkedUnavailable();
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
    final _c = DSTheme.of(context);
    final newJobsAsync = ref.watch(filteredDjJobsProvider);
    final pendingAsync = ref.watch(pendingDjQuotesProvider);
    final wonAsync = ref.watch(calendarEventsProvider(MusicianRole.dj));
    final unavailableAsync = ref.watch(djUnavailableDatesProvider);
    final wonQuotesAsync = ref.watch(wonDjQuotesProvider);
    final extJobsAsync = ref.watch(djExtJobsProvider);
    final newJobs = newJobsAsync.valueOrNull ?? [];
    final pending = pendingAsync.valueOrNull ?? [];
    final won = wonAsync.valueOrNull ?? [];
    final unavailableMap = unavailableAsync.valueOrNull ?? {};
    final unavailableDates = Set<String>.from(unavailableMap.keys);

    // Navigation lookup maps
    final jobById = {for (final j in newJobs) j.id: j};
    final pendingById = {for (final q in pending) q.id: q};
    final wonByJobId = {
      for (final q in wonQuotesAsync.valueOrNull ?? <DjQuote>[]) q.jobId: q,
    };
    final extJobById = {
      for (final e in extJobsAsync.valueOrNull ?? <ExtJob>[]) e.id: e,
    };

    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;
    final allEvents = _buildEvents(
      newJobs: newJobs,
      pendingQuotes: pending,
      wonEvents: won,
      djTier: djTier,
    );
    final visibleEvents = _eventsForView(allEvents);

    final selectedLabel =
        _selectedDay != null && !_isEditingUnavailable
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
                    won.isNotEmpty
                        ? () => showIcalExportBottomSheet(
                          context,
                          events: won,
                          isDj: true,
                        )
                        : null,
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Filter row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: _KindChip(
                        label: 'Nye jobs',
                        active: _showNew,
                        activeColor: _c.state.info,
                        onTap: () => setState(() => _showNew = !_showNew),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: _KindChip(
                        label: 'Bud afgivet',
                        active: _showSent,
                        activeColor: _c.state.warning,
                        onTap: () => setState(() => _showSent = !_showSent),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: _KindChip(
                        label: 'Vundet',
                        active: _showWon,
                        activeColor: _c.state.success,
                        onTap: () => setState(() => _showWon = !_showWon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Unavailable dates panel ──
              _UnavailableDatesPanel(
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
                unavailableDays: unavailableDates,
                onDaySelected: (day) => _onDayTapped(day, unavailableMap),
                onMonthChanged:
                    (m) => setState(() {
                      _month = m;
                      _selectedDay = null;
                    }),
              ),
              const SizedBox(height: DSSpacing.s4),
              Divider(height: 1, color: _c.border.subtle),
              const SizedBox(height: DSSpacing.s2),
              // ── Section header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
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
                        horizontal: 8,
                        vertical: 2,
                      ),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendar, size: 40, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    _isEditingUnavailable
                        ? 'Tryk på datoer for at markere dem'
                        : (_selectedDay != null
                            ? 'Ingen jobs denne dag'
                            : 'Ingen jobs denne måned'),
                    style: DSTextStyle.labelMd.copyWith(
                      fontSize: 15,
                      color: _c.text.secondary,
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
                    () => _navigate(
                      context,
                      event,
                      jobById,
                      pendingById,
                      wonByJobId,
                      extJobById,
                    ),
              );
            }, childCount: visibleEvents.length),
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
    required List<ServiceOffer> sentOffers,
    required List<CalendarEvent> wonEvents,
  }) {
    final events = <CalendarEvent>[];
    if (_showNew) {
      events.addAll(
        newJobs.map(
          (j) => _jobToEvent(j, budgetDisplay: _musicianBudgetLabel(j)),
        ),
      );
    }
    if (_showSent) events.addAll(sentOffers.map(_offerToEvent));
    if (_showWon) events.addAll(wonEvents);
    return events;
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

  void _onDayTapped(DateTime day, Map<String, int> unavailableMap) {
    if (_isEditingUnavailable) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final isCurrentlyUnavailable = unavailableMap.containsKey(dateStr);
      ref.read(musicianUnavailableDatesProvider.notifier).toggle(dateStr);
      if (isCurrentlyUnavailable) {
        AnalyticsService.logDateUnmarkedUnavailable();
      } else {
        AnalyticsService.logDateMarkedUnavailable();
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

  void _navigate(
    BuildContext context,
    CalendarEvent event,
    Map<int, Job> jobById,
    Map<int, ServiceOffer> sentById,
    Map<int, ServiceOffer> wonById,
  ) {
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
    final _c = DSTheme.of(context);
    final newJobsAsync = ref.watch(combinedInstrumentalistJobsProvider);
    final sentAsync = ref.watch(sentServiceOffersProvider);
    final wonEventsAsync = ref.watch(
      calendarEventsProvider(MusicianRole.instrumentalist),
    );
    final wonOffersAsync = ref.watch(wonServiceOffersProvider);
    final unavailableAsync = ref.watch(musicianUnavailableDatesProvider);

    final newJobs = newJobsAsync.valueOrNull ?? [];
    final sent = sentAsync.valueOrNull ?? [];
    final wonEvents = wonEventsAsync.valueOrNull ?? [];
    final wonOffers = wonOffersAsync.valueOrNull ?? [];
    final unavailableMap = unavailableAsync.valueOrNull ?? {};
    final unavailableDates = Set<String>.from(unavailableMap.keys);

    final jobById = {for (final j in newJobs) j.id: j};
    final sentById = {for (final o in sent) o.id: o};
    final wonById = {for (final o in wonOffers) o.id: o};

    final allEvents = _buildEvents(
      newJobs: newJobs,
      sentOffers: sent,
      wonEvents: wonEvents,
    );
    final visibleEvents = _eventsForView(allEvents);

    final selectedLabel =
        _selectedDay != null && !_isEditingUnavailable
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
                          isDj: false,
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
                      child: _KindChip(
                        label: 'Nye jobs',
                        active: _showNew,
                        activeColor: _c.state.info,
                        onTap: () => setState(() => _showNew = !_showNew),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: _KindChip(
                        label: 'Bud afgivet',
                        active: _showSent,
                        activeColor: _c.state.warning,
                        onTap: () => setState(() => _showSent = !_showSent),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: _KindChip(
                        label: 'Vundet',
                        active: _showWon,
                        activeColor: _c.state.success,
                        onTap: () => setState(() => _showWon = !_showWon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),
              // ── Unavailable dates panel ──
              _UnavailableDatesPanel(
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
                unavailableDays: unavailableDates,
                onDaySelected: (day) => _onDayTapped(day, unavailableMap),
                onMonthChanged:
                    (m) => setState(() {
                      _month = m;
                      _selectedDay = null;
                    }),
              ),
              const SizedBox(height: DSSpacing.s4),
              Divider(height: 1, color: _c.border.subtle),
              const SizedBox(height: DSSpacing.s2),
              // ── Section header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
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
                        horizontal: 8,
                        vertical: 2,
                      ),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendar, size: 40, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    _isEditingUnavailable
                        ? 'Tryk på datoer for at markere dem'
                        : (_selectedDay != null
                            ? 'Ingen jobs denne dag'
                            : 'Ingen jobs denne måned'),
                    style: DSTextStyle.labelMd.copyWith(
                      fontSize: 15,
                      color: _c.text.secondary,
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
                    () => _navigate(context, event, jobById, sentById, wonById),
              );
            }, childCount: visibleEvents.length),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.s8)),
      ],
    );
  }
}

// ── Calendar helper converters ──

/// Musician-facing payout label for a new job on the calendar.
/// Mirrors the fixed offer price shown on the musician "Nye jobs" list.
String _musicianBudgetLabel(Job job) {
  final price = calculateMusicianOfferPrice(
    job.requestedMusicianHours,
    job.createdAt,
  );
  return '${NumberFormat('#,###', 'da_DK').format(price).replaceAll(',', '.')} kr.';
}

CalendarEvent _jobToEvent(Job job, {String? budgetDisplay}) => CalendarEvent(
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
  budgetDisplay: budgetDisplay,
  jobId: job.id,
);

CalendarEvent _quoteToEvent(DjQuote quote) => CalendarEvent(
  id: quote.id,
  date: quote.job.date,
  label: quote.job.eventType,
  type: CalendarEventType.internal,
  kind: CalendarEventKind.sent,
  startTime: quote.job.timeStart.isEmpty ? null : quote.job.timeStart,
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
  type:
      offer.isExtJob ? CalendarEventType.external : CalendarEventType.internal,
  kind: CalendarEventKind.sent,
  startTime: offer.job.timeStart.isEmpty ? null : offer.job.timeStart,
  endTime: offer.job.timeEnd.isEmpty ? null : offer.job.timeEnd,
  location: offer.job.city.isEmpty ? null : offer.job.city,
  region: offer.job.region.isEmpty ? null : offer.job.region,
  guestsAmount: offer.job.guestsAmount > 0 ? offer.job.guestsAmount : null,
  jobId: offer.isExtJob ? null : offer.jobId,
  extJobId: offer.isExtJob ? offer.extJobId : null,
);

// ── Month grouping (won-jobs lists) ──

const _kMonthNamesFull = [
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

/// Builds a list of widgets where the already-sorted [items] are grouped under
/// month/year headers (e.g. "Januar 2027"). Group order follows the date:
/// chronological for upcoming, most-recent-first when [descending] is true.
/// The incoming order is preserved within each month, so any "needs action"
/// ordering still floats to the top of its month.
List<Widget> _groupByMonth<T>({
  required List<T> items,
  required DateTime Function(T) dateOf,
  required Widget Function(int index, T item) cardOf,
  bool descending = false,
}) {
  final groups = <int, List<T>>{};
  for (final item in items) {
    final d = dateOf(item);
    final key = d.year * 12 + (d.month - 1);
    groups.putIfAbsent(key, () => <T>[]).add(item);
  }
  final keys = groups.keys.toList()..sort();
  if (descending) {
    final reversed = keys.reversed.toList();
    keys
      ..clear()
      ..addAll(reversed);
  }

  final children = <Widget>[];
  var index = 0;
  for (final key in keys) {
    final year = key ~/ 12;
    final month = key % 12;
    children.add(_MonthGroupHeader(label: '${_kMonthNamesFull[month]} $year'));
    for (final item in groups[key]!) {
      children.add(cardOf(index, item));
      index++;
    }
  }
  return children;
}

class _MonthGroupHeader extends StatelessWidget {
  const _MonthGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s3,
        DSSpacing.s4,
        DSSpacing.s1,
      ),
      child: Text(
        label,
        style: DSTextStyle.labelSm.copyWith(
          fontWeight: FontWeight.w700,
          color: c.text.secondary,
        ),
      ),
    );
  }
}

// ── Calendar filter chips ──

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
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.12) : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(
            color: active ? activeColor : _c.border.subtle,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: DSTextStyle.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? activeColor : _c.text.secondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              active ? LucideIcons.check : LucideIcons.x,
              size: 11,
              color: active ? activeColor : _c.text.secondary,
            ),
          ],
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
    final _c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s2,
        ),
        decoration: BoxDecoration(
          color:
              isEditing
                  ? _c.state.danger.withValues(alpha: 0.06)
                  : _c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color:
                isEditing
                    ? _c.state.danger.withValues(alpha: 0.3)
                    : _c.border.subtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isEditing ? LucideIcons.calendarDays : LucideIcons.ban,
              size: 16,
              color: isEditing ? _c.state.danger : _c.text.muted,
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
                  horizontal: DSSpacing.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEditing ? _c.state.danger : _c.border.subtle,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(
                  isEditing ? 'Luk' : 'Rediger',
                  style: DSTextStyle.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isEditing ? _c.text.onDark : _c.text.secondary,
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
    final _c = DSTheme.of(context);
    final jobsAsync = ref.watch(filteredDjJobsProvider);
    final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
    final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;

    return jobsAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(newDjJobsProvider.notifier).refresh(),
          ),
      data: (jobs) {
        if (jobs.isEmpty) {
          // The visible list is empty. If the *unfiltered* server list still has
          // jobs, the DJ's own filters are hiding them → nudge them to loosen.
          // Otherwise there are genuinely no matching jobs right now.
          final rawJobs = ref.watch(newDjJobsProvider).valueOrNull ?? const [];
          final filtersHiding = rawJobs.isNotEmpty;
          final djId = ref.watch(djProfileProvider).valueOrNull?.id;

          final empty =
              filtersHiding
                  ? EmptyJobsView(
                    icon: LucideIcons.slidersHorizontal,
                    title: 'Ingen jobs matcher dine filtre',
                    message:
                        'Dine filtre skjuler ${rawJobs.length} ${rawJobs.length == 1 ? 'job' : 'jobs'} lige nu. Udvid dem for at se flere.',
                    actionLabel: 'Justér filtre',
                    onAction:
                        djId == null
                            ? null
                            : () => context.pushNamed(
                              AppRoutes.djJobFilters,
                              extra: djId,
                            ),
                    secondaryLabel: 'Slå filtre fra',
                    onSecondary:
                        () =>
                            ref.read(djFiltersEnabledProvider.notifier).state =
                                false,
                  )
                  : const EmptyJobsView(
                    icon: LucideIcons.searchX,
                    title: 'Ingen nye jobs lige nu',
                    message:
                        'Vi giver dig besked, så snart der dukker et job op, der passer til dig.',
                  );

          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => ref.read(newDjJobsProvider.notifier).refresh(),
            child: ListView(children: [const SizedBox(height: 80), empty]),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(newDjJobsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final colliding = isDateColliding(job, quotes, extJobs);
              return AnimatedCard(
                index: index,
                child: JobCard(
                  job: job,
                  onTap:
                      () =>
                          context.pushNamed(AppRoutes.djQuoteForm, extra: job),
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

class _DjQuotesTab extends ConsumerWidget {
  const _DjQuotesTab({required this.filter});

  final QuoteStatus filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final quotesAsync = switch (filter) {
      QuoteStatus.pending => ref.watch(pendingDjQuotesProvider),
      QuoteStatus.won => ref.watch(wonDjQuotesProvider),
      _ => ref.watch(expiredDjQuotesProvider),
    };

    return quotesAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(djQuotesProvider.notifier).refresh(),
          ),
      data: (quotes) {
        final sorted = quotes;

        if (sorted.isEmpty) {
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
            itemCount: sorted.length,
            itemBuilder:
                (context, index) => AnimatedCard(
                  index: index,
                  child: QuoteCard(
                    quote: sorted[index],
                    onTap:
                        () => context.pushNamed(
                          AppRoutes.quoteDetail,
                          extra: sorted[index],
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

// ── DJ Won Quotes Tab (with played-jobs toggle) ──

class _DjWonQuotesTab extends ConsumerStatefulWidget {
  const _DjWonQuotesTab();

  @override
  ConsumerState<_DjWonQuotesTab> createState() => _DjWonQuotesTabState();
}

class _DjWonQuotesTabState extends ConsumerState<_DjWonQuotesTab> {
  bool _showPlayed = false;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final quotesAsync = ref.watch(wonDjQuotesProvider);

    return quotesAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(djQuotesProvider.notifier).refresh(),
          ),
      data: (quotes) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        int actionTier(DjQuote q) {
          if (q.hasAction) return 0;
          if (q.pendingAction == JobActionType.contactCustomerPlanned) return 1;
          return 2;
        }

        final upcoming =
            quotes
                .where(
                  (q) =>
                      !DateTime(
                        q.job.date.year,
                        q.job.date.month,
                        q.job.date.day,
                      ).isBefore(today),
                )
                .toList()
              ..sort((a, b) {
                final tierDiff = actionTier(a).compareTo(actionTier(b));
                if (tierDiff != 0) return tierDiff;
                return a.job.date.compareTo(b.job.date);
              });

        final played =
            quotes
                .where(
                  (q) => DateTime(
                    q.job.date.year,
                    q.job.date.month,
                    q.job.date.day,
                  ).isBefore(today),
                )
                .toList()
              ..sort((a, b) => b.job.date.compareTo(a.job.date));

        final displayList = _showPlayed ? played : upcoming;

        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(djQuotesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (played.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4,
                    vertical: DSSpacing.s2,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _showPlayed = !_showPlayed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s3,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _showPlayed
                                ? _c.state.success.withValues(alpha: 0.10)
                                : _c.bg.inputBg,
                        borderRadius: BorderRadius.circular(DSRadius.pill),
                        border: Border.all(
                          color:
                              _showPlayed ? _c.state.success : _c.border.subtle,
                          width: _showPlayed ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showPlayed
                                ? LucideIcons.calendarCheck
                                : LucideIcons.history,
                            size: 14,
                            color:
                                _showPlayed
                                    ? _c.state.success
                                    : _c.text.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showPlayed
                                ? 'Kommende jobs (${upcoming.length})'
                                : 'Vis spillede jobs (${played.length})',
                            style: DSTextStyle.labelSm.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  _showPlayed
                                      ? _c.state.success
                                      : _c.text.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (displayList.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: EmptyJobsView(
                    message:
                        _showPlayed
                            ? 'Ingen spillede jobs endnu.'
                            : quotes.isEmpty
                            ? 'Du har ikke vundet nogen jobs endnu.'
                            : 'Ingen kommende vundne jobs.',
                    icon: LucideIcons.calendarCheck,
                  ),
                )
              else
                ..._groupByMonth<DjQuote>(
                  items: displayList,
                  dateOf: (q) => q.job.date,
                  descending: _showPlayed,
                  cardOf:
                      (index, q) => AnimatedCard(
                        index: index,
                        child: QuoteCard(
                          quote: q,
                          isPlayed: _showPlayed,
                          onTap:
                              () => context.pushNamed(
                                AppRoutes.quoteDetail,
                                extra: q,
                              ),
                        ),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DjExpiredTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final quotesAsync = ref.watch(expiredDjQuotesProvider);

    return quotesAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
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
            itemBuilder:
                (context, index) => AnimatedCard(
                  index: index,
                  child: QuoteCard(
                    quote: quotes[index],
                    onTap:
                        () => context.pushNamed(
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
    final _c = DSTheme.of(context);
    final jobsAsync = ref.watch(combinedInstrumentalistJobsProvider);
    final sentOffers = ref.watch(sentServiceOffersProvider).valueOrNull ?? [];
    final wonOffers = ref.watch(wonServiceOffersProvider).valueOrNull ?? [];

    return jobsAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
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
            itemBuilder: (context, index) {
              final job = jobs[index];
              final hasConflict = _musicianHasDateConflict(
                job,
                sentOffers,
                wonOffers,
              );
              return AnimatedCard(
                index: index,
                child: JobCard(
                  job: job,
                  isMusicianView: true,
                  isColliding: hasConflict,
                  musicianPrice: calculateMusicianOfferPrice(
                    job.requestedMusicianHours,
                    job.createdAt,
                  ),
                  onTap:
                      () => context.pushNamed(
                        AppRoutes.instrumentalistOfferForm,
                        extra: job,
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

bool _musicianHasDateConflict(
  Job job,
  List<ServiceOffer> sent,
  List<ServiceOffer> won,
) {
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  return sent.any((o) => sameDay(o.job.date, job.date)) ||
      won.any((o) => sameDay(o.job.date, job.date));
}

// ── Instrumentalist Won Offers Tab (with played-jobs toggle) ──

class _InstrumentalistWonOffersTab extends ConsumerStatefulWidget {
  const _InstrumentalistWonOffersTab();

  @override
  ConsumerState<_InstrumentalistWonOffersTab> createState() =>
      _InstrumentalistWonOffersTabState();
}

class _InstrumentalistWonOffersTabState
    extends ConsumerState<_InstrumentalistWonOffersTab> {
  bool _showPlayed = false;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final offersAsync = ref.watch(wonServiceOffersProvider);

    return offersAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(serviceOffersProvider.notifier).refresh(),
          ),
      data: (offers) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        int actionTier(ServiceOffer o) {
          if (o.hasAction) return 0;
          if (o.pendingAction == JobActionType.contactCustomerPlanned) return 1;
          return 2;
        }

        final upcoming =
            offers
                .where(
                  (o) =>
                      !DateTime(
                        o.job.date.year,
                        o.job.date.month,
                        o.job.date.day,
                      ).isBefore(today),
                )
                .toList()
              ..sort((a, b) {
                final tierDiff = actionTier(a).compareTo(actionTier(b));
                if (tierDiff != 0) return tierDiff;
                return a.job.date.compareTo(b.job.date);
              });

        final played =
            offers
                .where(
                  (o) => DateTime(
                    o.job.date.year,
                    o.job.date.month,
                    o.job.date.day,
                  ).isBefore(today),
                )
                .toList()
              ..sort((a, b) => b.job.date.compareTo(a.job.date));

        final displayList = _showPlayed ? played : upcoming;

        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(serviceOffersProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // Toggle button — only shown when there are played jobs
              if (played.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s4,
                    vertical: DSSpacing.s2,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _showPlayed = !_showPlayed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s3,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _showPlayed
                                ? _c.state.success.withValues(alpha: 0.10)
                                : _c.bg.inputBg,
                        borderRadius: BorderRadius.circular(DSRadius.pill),
                        border: Border.all(
                          color:
                              _showPlayed ? _c.state.success : _c.border.subtle,
                          width: _showPlayed ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showPlayed
                                ? LucideIcons.calendarCheck
                                : LucideIcons.history,
                            size: 14,
                            color:
                                _showPlayed
                                    ? _c.state.success
                                    : _c.text.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showPlayed
                                ? 'Kommende jobs (${upcoming.length})'
                                : 'Vis spillede jobs (${played.length})',
                            style: DSTextStyle.labelSm.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  _showPlayed
                                      ? _c.state.success
                                      : _c.text.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Either upcoming or played — never both at once
              if (displayList.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: EmptyJobsView(
                    message:
                        _showPlayed
                            ? 'Ingen spillede jobs endnu.'
                            : offers.isEmpty
                            ? 'Ingen accepterede jobs endnu.'
                            : 'Ingen kommende accepterede jobs.',
                    icon: LucideIcons.calendarCheck,
                  ),
                )
              else
                ..._groupByMonth<ServiceOffer>(
                  items: displayList,
                  dateOf: (o) => o.job.date,
                  descending: _showPlayed,
                  cardOf:
                      (index, o) => AnimatedCard(
                        index: index,
                        child: ServiceOfferCard(
                          offer: o,
                          isPlayed: _showPlayed,
                          onTap:
                              () => context.pushNamed(
                                AppRoutes.serviceOfferDetail,
                                extra: o,
                              ),
                        ),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Instrumentalist Offers Tab (sent / lost) ──

class _InstrumentalistOffersTab extends ConsumerWidget {
  const _InstrumentalistOffersTab({required this.filter});

  final ServiceOfferStatus filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final offersAsync = switch (filter) {
      ServiceOfferStatus.sent => ref.watch(sentServiceOffersProvider),
      ServiceOfferStatus.won => ref.watch(wonServiceOffersProvider),
      ServiceOfferStatus.lost => ref.watch(expiredServiceOffersProvider),
    };

    return offersAsync.when(
      loading: () => const SkeletonListView(),
      error:
          (error, _) => _ErrorView(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(serviceOffersProvider.notifier).refresh(),
          ),
      data: (offers) {
        final sorted = offers;

        if (sorted.isEmpty) {
          return RefreshIndicator(
            color: _c.brand.primary,
            onRefresh: () => ref.read(serviceOffersProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 80),
                EmptyJobsView(message: _emptyMessageForOfferStatus(filter)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _c.brand.primary,
          onRefresh: () => ref.read(serviceOffersProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: sorted.length,
            itemBuilder:
                (context, index) => AnimatedCard(
                  index: index,
                  child: ServiceOfferCard(
                    offer: sorted[index],
                    onTap:
                        () => context.pushNamed(
                          AppRoutes.serviceOfferDetail,
                          extra: sorted[index],
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

// ── Availability gate dialog ──

class _AvailabilityGateDialog extends StatelessWidget {
  const _AvailabilityGateDialog({
    required this.missingMonthsCount,
    required this.onGoToCalendar,
    required this.onRemindLater,
  });

  final int missingMonthsCount;
  final VoidCallback onGoToCalendar;
  final VoidCallback onRemindLater;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final monthText =
        missingMonthsCount == 1 ? '1 måned' : '$missingMonthsCount måneder';
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      backgroundColor: _c.bg.surface,
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarDays, size: 40, color: _c.brand.primary),
            const SizedBox(height: DSSpacing.s4),
            Text(
              'Husk dine optagne datoer',
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s3),
            Text(
              'Du mangler at markere optagne datoer for mindst $monthText. Det hjælper os med at vise dig relevante jobs.',
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s6),
            DSButton(
              label: 'Gå til kalender',
              variant: DSButtonVariant.primary,
              onTap: onGoToCalendar,
            ),
            const SizedBox(height: DSSpacing.s3),
            GestureDetector(
              onTap: onRemindLater,
              child: Text(
                'Påmind mig senere',
                style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared ──

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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
