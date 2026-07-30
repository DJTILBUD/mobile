import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/job_duration.dart';
import 'package:dj_tilbud_app/features/jobs/domain/sax_offer_conflict.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/song_request.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job_action.dart';
import 'package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:dj_tilbud_app/features/jobs/data/datasources/jobs_remote_datasource.dart';
import 'package:dj_tilbud_app/features/jobs/data/repositories/jobs_repository_impl.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final datasource = JobsRemoteDatasource(client);
  return JobsRepositoryImpl(datasource);
});

String get _currentUserId => supabase.auth.currentUser!.id;

// ─── Base mixin for Realtime-backed notifiers ─────────────────────────────────

/// Sets state to AsyncLoading → fetches → AsyncData/AsyncError.
/// Returns when fetch is complete so RefreshIndicator can await it.
abstract class _RealtimeNotifier<T> extends StateNotifier<AsyncValue<T>> {
  _RealtimeNotifier(this.client) : super(const AsyncLoading());

  final SupabaseClient client;
  final List<RealtimeChannel> _channels = [];

  Future<T> fetch();

  Future<void> init() async {
    await _loadSilently();
    subscribeToRealtime();
  }

  Future<void> _loadSilently() async {
    try {
      state = AsyncData(await fetch());
    } catch (e, st) {
      debugPrint('[$runtimeType] fetch error: $e\n$st');
      state = AsyncError(e, st);
    }
  }

  /// Called by pull-to-refresh — shows spinner while loading.
  Future<void> refresh() async {
    state = const AsyncLoading();
    await _loadSilently();
  }

  /// Called by mutations after successful writes — updates silently (no spinner).
  Future<void> silentRefresh() => _loadSilently();

  void subscribeToRealtime();

  void addChannel(RealtimeChannel ch) => _channels.add(ch);

  @override
  void dispose() {
    for (final ch in _channels) {
      client.removeChannel(ch);
    }
    super.dispose();
  }
}

// ─── DJ: new jobs ─────────────────────────────────────────────────────────────

class NewDjJobsNotifier extends _RealtimeNotifier<List<Job>> {
  NewDjJobsNotifier(super.client, this._repository, this._userId) {
    init();
  }

  final JobsRepository _repository;
  final String _userId;

  @override
  Future<List<Job>> fetch() => _repository.fetchNewDjJobs(_userId);

  @override
  void subscribeToRealtime() {
    addChannel(
      client
          .channel('dj-new-jobs-$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'Jobs',
            callback: (_) => _loadSilently(),
          )
          .subscribe(),
    );
  }
}

final newDjJobsProvider =
    StateNotifierProvider<NewDjJobsNotifier, AsyncValue<List<Job>>>(
      (ref) => NewDjJobsNotifier(
        ref.watch(supabaseClientProvider),
        ref.watch(jobsRepositoryProvider),
        _currentUserId,
      ),
    );

// ─── DJ: quotes ───────────────────────────────────────────────────────────────

class DjQuotesNotifier extends _RealtimeNotifier<List<DjQuote>> {
  DjQuotesNotifier(super.client, this._repository, this._userId) {
    init();
  }

  final JobsRepository _repository;
  final String _userId;

  @override
  Future<List<DjQuote>> fetch() => _repository.fetchDjQuotes(_userId);

  @override
  void subscribeToRealtime() {
    addChannel(
      client
          .channel('dj-quotes-$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'Quotes',
            callback: (_) => _loadSilently(),
          )
          .subscribe(),
    );
  }
}

final djQuotesProvider =
    StateNotifierProvider<DjQuotesNotifier, AsyncValue<List<DjQuote>>>(
      (ref) => DjQuotesNotifier(
        ref.watch(supabaseClientProvider),
        ref.watch(jobsRepositoryProvider),
        _currentUserId,
      ),
    );

final djExtJobsProvider = FutureProvider<List<ExtJob>>((ref) async {
  final list = await ref
      .watch(jobsRepositoryProvider)
      .fetchDjExtJobs(_currentUserId);
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
});

/// Recurring-customer (venue) names for the current DJ's assigned ext jobs,
/// keyed by ext job id. Powers the "Fast kunde · <navn>" badge on the
/// "Udvalgte jobs" list + detail (mirrors the web app's udvalgte-jobs badge).
/// Resolved via the DJ-scoped web API because `RecurringCustomers` is not
/// RLS-readable by a DJ; failures (e.g. a non-DJ opening the shared ext-job
/// detail via a push) degrade to an empty map so the badge simply doesn't show.
final djExtJobRecurringNamesProvider = FutureProvider<Map<int, String>>((
  ref,
) async {
  try {
    return await ref
        .watch(jobsRepositoryProvider)
        .fetchDjExtJobRecurringNames(_currentUserId);
  } catch (_) {
    return <int, String>{};
  }
});

/// Musician counterpart of [djExtJobRecurringNamesProvider] — venue names for the
/// current sax's won/assigned ext jobs. The ext-job detail screen is shared by
/// DJs and musicians, so it coalesces both maps; each degrades to empty for the
/// wrong role (the DJ endpoint 404s for a musician, and vice-versa this one just
/// returns no rows), so watching both is safe.
final musicianExtJobRecurringNamesProvider = FutureProvider<Map<int, String>>((
  ref,
) async {
  try {
    return await ref
        .watch(jobsRepositoryProvider)
        .fetchMusicianExtJobRecurringNames();
  } catch (_) {
    return <int, String>{};
  }
});

/// DJ jobs after applying profile-level hard constraints and saved filter
/// preferences. Mirrors `useUnbidJobsFromMyRegions` from the web app.
/// Whether the DJ's optional job filter preferences (DjJobFilters) should be
/// applied. Hard profile constraints (suppressed, excluded event types, sax)
/// are always applied regardless of this toggle.
final djFiltersEnabledProvider = StateProvider<bool>((ref) => true);

final filteredDjJobsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final jobs = ref.watch(newDjJobsProvider);
  final filtersAsync = ref.watch(djJobFiltersProvider);
  final filtersEnabled = ref.watch(djFiltersEnabledProvider);

  // The server (GET /api/dj/biddable-jobs) already applied every hard rule —
  // suppression, quote cap, tier quotas, paused, sax capability, profile-excluded
  // event types, already-quoted/rejected exclusion, unavailable dates — and the
  // collision sort. The only thing left to do client-side is the *optional*
  // DjJobFilters, gated by the instant in-list "Filtre til/fra" toggle.
  return jobs.whenData((jobList) {
    final filters = filtersAsync.valueOrNull;
    if (!filtersEnabled || filters == null || !filters.hasActiveFilters) {
      return jobList;
    }
    return jobList
        .where((job) => !_isJobExcludedByFilters(job, filters))
        .toList();
  });
});

bool _isJobExcludedByFilters(Job job, DjJobFilters f) {
  // Event type (case-insensitive to match web app)
  if (f.excludedEventTypes.isNotEmpty) {
    final jobType = job.eventType.trim().toLowerCase();
    if (f.excludedEventTypes.any((e) => e.trim().toLowerCase() == jobType)) {
      return true;
    }
  }

  if (f.excludedRegions.contains(job.region)) return true;

  // Genre: exclude if ANY of the job's genres is in the excluded list
  // (matches web app: job.genres.some(...) not .every(...))
  if (f.excludedGenres.isNotEmpty &&
      job.genres != null &&
      job.genres!.isNotEmpty) {
    if (job.genres!.any((g) => f.excludedGenres.contains(g))) return true;
  }

  if (f.allowedWeekdays != null) {
    // DateTime.weekday: 1=Mon…7=Sun  →  map to  0=Sun…6=Sat
    final dartWeekday = job.date.weekday;
    final jsWeekday = dartWeekday == 7 ? 0 : dartWeekday;
    if (!f.allowedWeekdays!.contains(jsWeekday)) return true;
  }

  if (f.minBudget != null &&
      job.budgetEnd != null &&
      job.budgetEnd! < f.minBudget!)
    return true;
  if (f.maxBudget != null &&
      job.budgetStart != null &&
      job.budgetStart! > f.maxBudget!)
    return true;
  if (f.minGuests != null && job.guestsAmount < f.minGuests!) return true;
  if (f.maxGuests != null && job.guestsAmount > f.maxGuests!) return true;

  // Job length. Mirrors web `isJobExcludedByDjFilters`: the duration helper handles the
  // past-midnight wrap (21:00 -> 02:00 is 5h, not -19h), the comparison uses the true decimal
  // length so a 5.5h job is excluded by maxHours = 5, and an unknown length is never excluded.
  final durationHours = jobDurationHours(job.timeStart, job.timeEnd);
  if (durationHours != null) {
    if (f.minHours != null && durationHours < f.minHours!) return true;
    if (f.maxHours != null && durationHours > f.maxHours!) return true;
  }

  return false;
}

final pendingDjQuotesProvider = Provider<AsyncValue<List<DjQuote>>>((ref) {
  return ref.watch(djQuotesProvider).whenData((quotes) {
    final list = quotes.where((q) => q.status == QuoteStatus.pending).toList();
    list.sort((a, b) => a.job.date.compareTo(b.job.date));
    return list;
  });
});

final wonDjQuotesProvider = Provider<AsyncValue<List<DjQuote>>>((ref) {
  return ref.watch(djQuotesProvider).whenData((quotes) {
    final list = quotes.where((q) => q.status == QuoteStatus.won).toList();
    list.sort((a, b) {
      // Tier 0: red actions first, tier 1: planned contact, tier 2: no action
      int actionTier(DjQuote q) {
        if (q.hasAction) return 0;
        if (q.pendingAction == JobActionType.contactCustomerPlanned) return 1;
        return 2;
      }

      final tierDiff = actionTier(a).compareTo(actionTier(b));
      if (tierDiff != 0) return tierDiff;
      return a.job.date.compareTo(b.job.date);
    });
    return list;
  });
});

final expiredDjQuotesProvider = Provider<AsyncValue<List<DjQuote>>>((ref) {
  return ref.watch(djQuotesProvider).whenData((quotes) {
    final list =
        quotes
            .where(
              (q) =>
                  q.status == QuoteStatus.lost ||
                  q.status == QuoteStatus.overwritten,
            )
            .toList();
    list.sort((a, b) => a.job.date.compareTo(b.job.date));
    return list;
  });
});

// ─── Instrumentalist: new jobs ────────────────────────────────────────────────

class NewInstrumentalistJobsNotifier extends _RealtimeNotifier<List<Job>> {
  NewInstrumentalistJobsNotifier(super.client, this._repository, this._userId) {
    init();
  }

  final JobsRepository _repository;
  final String _userId;

  @override
  Future<List<Job>> fetch() => _repository.fetchNewInstrumentalistJobs(_userId);

  @override
  void subscribeToRealtime() {
    addChannel(
      client
          .channel('instrumentalist-new-jobs-$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'Jobs',
            callback: (_) => _loadSilently(),
          )
          .subscribe(),
    );
    // Also refresh when ANY service offer changes status (e.g. "sent" → "lost")
    // so hasActiveOffer updates for other musicians without requiring a manual refresh.
    addChannel(
      client
          .channel('instrumentalist-jobs-offers-$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'ServiceOffers',
            callback: (_) => _loadSilently(),
          )
          .subscribe(),
    );
  }
}

final newInstrumentalistJobsProvider = StateNotifierProvider<
  NewInstrumentalistJobsNotifier,
  AsyncValue<List<Job>>
>(
  (ref) => NewInstrumentalistJobsNotifier(
    ref.watch(supabaseClientProvider),
    ref.watch(jobsRepositoryProvider),
    _currentUserId,
  ),
);

final instrumentalistExtJobsProvider = FutureProvider<List<Job>>((ref) {
  return ref
      .watch(jobsRepositoryProvider)
      .fetchInstrumentalistExtJobs(_currentUserId);
});

/// Combined feed: regular jobs + ext jobs.
/// Sort order: eligible first (newest created_at)
/// → optaget/taken (another musician has an active offer — can't bid)
/// → dato-konflikt (musician already has a won job on the same date — can't bid).
/// Mirrors web app priority logic.
final combinedInstrumentalistJobsProvider = Provider<AsyncValue<List<Job>>>((
  ref,
) {
  final regular = ref.watch(newInstrumentalistJobsProvider);
  final ext = ref.watch(instrumentalistExtJobsProvider);

  if (regular is AsyncLoading || ext is AsyncLoading) {
    return const AsyncLoading();
  }
  if (regular is AsyncError) return regular;
  if (ext is AsyncError) return ext;

  // Bookings the musician has already WON. A feed job is "occupied" (date conflict) only when it
  // time-conflicts with a won booking (same date, gap < 3h) — not merely the same calendar day, so
  // a short sax gig ≥ 3h clear stays biddable. Mirrors the DB rule (see saxBookingsConflict).
  final wonBookings =
      ref
          .watch(wonServiceOffersProvider)
          .valueOrNull
          ?.map((o) => o.job)
          .toList() ??
      const [];

  // Sax window = musicianStartTime + requestedMusicianHours (NOT the DJ timeStart/timeEnd).
  bool isOccupied(Job j) => wonBookings.any(
    (won) => saxBookingsConflict(
      dateA: saxDateKey(j.date),
      startA: j.musicianStartTime,
      endA: saxEndTime(j.musicianStartTime, j.requestedMusicianHours),
      dateB: saxDateKey(won.date),
      startB: won.musicianStartTime,
      endB: saxEndTime(won.musicianStartTime, won.requestedMusicianHours),
    ),
  );

  // Tier 0 = eligible (shown first)
  // Tier 1 = optaget — another musician already has an active offer (shown second)
  // Tier 2 = dato-konflikt — musician has a won job on the same date (shown last)
  int tier(Job j) {
    if (j.hasDateConflict) return 2;
    if (j.hasActiveOffer) return 1;
    return 0;
  }

  final combined =
      <Job>[
          ...regular.valueOrNull ?? [],
          ...ext.valueOrNull ?? [],
        ].map((j) => isOccupied(j) ? j.withDateConflict() : j).toList()
        ..sort((a, b) {
          final tierDiff = tier(a).compareTo(tier(b));
          if (tierDiff != 0) return tierDiff;
          return b.createdAt.compareTo(a.createdAt); // newest first within tier
        });

  return AsyncData(combined);
});

/// Whether the musician's optional job filter preferences (MusicianJobFilters)
/// should be applied to the feed. Mirrors `djFiltersEnabledProvider`.
final musicianFiltersEnabledProvider = StateProvider<bool>((ref) => true);

/// The instrumentalist feed after applying the saved MusicianJobFilters
/// (region + sax type), gated by the instant in-list "Filtre til/fra" toggle.
/// Mirrors `filteredDjJobsProvider` on the DJ side.
final filteredInstrumentalistJobsProvider = Provider<AsyncValue<List<Job>>>((
  ref,
) {
  final jobs = ref.watch(combinedInstrumentalistJobsProvider);
  final filtersAsync = ref.watch(musicianJobFiltersProvider);
  final filtersEnabled = ref.watch(musicianFiltersEnabledProvider);

  return jobs.whenData((jobList) {
    final filters = filtersAsync.valueOrNull;
    if (!filtersEnabled || filters == null || !filters.hasActiveFilters) {
      return jobList;
    }
    return jobList
        .where((job) => !_isJobExcludedByMusicianFilters(job, filters))
        .toList();
  });
});

bool _isJobExcludedByMusicianFilters(Job job, MusicianJobFilters f) {
  if (f.excludedRegions.contains(job.region)) return true;

  final saxType = job.saxType?.trim().toLowerCase();
  if (saxType != null &&
      saxType.isNotEmpty &&
      f.excludedSaxTypes.any((e) => e.trim().toLowerCase() == saxType)) {
    return true;
  }

  return false;
}

// ─── Instrumentalist: service offers ─────────────────────────────────────────

class ServiceOffersNotifier extends _RealtimeNotifier<List<ServiceOffer>> {
  ServiceOffersNotifier(super.client, this._repository, this._userId) {
    init();
  }

  final JobsRepository _repository;
  final String _userId;

  @override
  Future<List<ServiceOffer>> fetch() => _repository.fetchServiceOffers(_userId);

  @override
  void subscribeToRealtime() {
    addChannel(
      client
          .channel('service-offers-$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ServiceOffers',
            callback: (_) => _loadSilently(),
          )
          .subscribe(),
    );
  }
}

final serviceOffersProvider = StateNotifierProvider<
  ServiceOffersNotifier,
  AsyncValue<List<ServiceOffer>>
>(
  (ref) => ServiceOffersNotifier(
    ref.watch(supabaseClientProvider),
    ref.watch(jobsRepositoryProvider),
    _currentUserId,
  ),
);

final sentServiceOffersProvider = Provider<AsyncValue<List<ServiceOffer>>>((
  ref,
) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list =
        offers.where((o) => o.status == ServiceOfferStatus.sent).toList();
    list.sort((a, b) => a.job.date.compareTo(b.job.date));
    return list;
  });
});

final wonServiceOffersProvider = Provider<AsyncValue<List<ServiceOffer>>>((
  ref,
) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list =
        offers.where((o) => o.status == ServiceOfferStatus.won).toList();
    list.sort((a, b) {
      // Tier 0: red actions first, tier 1: planned contact, tier 2: no action
      int actionTier(ServiceOffer o) {
        if (o.hasAction) return 0;
        if (o.pendingAction == JobActionType.contactCustomerPlanned) return 1;
        return 2;
      }

      final tierDiff = actionTier(a).compareTo(actionTier(b));
      if (tierDiff != 0) return tierDiff;
      return a.job.date.compareTo(b.job.date);
    });
    return list;
  });
});

final expiredServiceOffersProvider = Provider<AsyncValue<List<ServiceOffer>>>((
  ref,
) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list =
        offers.where((o) => o.status == ServiceOfferStatus.lost).toList();
    list.sort((a, b) => a.job.date.compareTo(b.job.date));
    return list;
  });
});

// ─── Job detail provider ──────────────────────────────────────────────────────

final jobDetailProvider = FutureProvider.family<Job, int>((ref, jobId) {
  return ref.watch(jobsRepositoryProvider).fetchJobDetail(jobId);
});

// ─── Invoice status providers ─────────────────────────────────────────────────

/// first_invoice_paid for a regular job (DJ quote or instrumentalist offer).
final invoiceStatusByJobIdProvider = FutureProvider.autoDispose
    .family<bool?, int>((ref, jobId) {
      return ref.watch(jobsRepositoryProvider).fetchInvoiceStatus(jobId: jobId);
    });

/// first_invoice_paid for an ext job (instrumentalist offer on ext job).
final invoiceStatusByExtJobIdProvider = FutureProvider.autoDispose
    .family<bool?, int>((ref, extJobId) {
      return ref
          .watch(jobsRepositoryProvider)
          .fetchInvoiceStatus(extJobId: extJobId);
    });

// ─── Event address providers ──────────────────────────────────────────────────
// The precise event address (JobMetadata.event_address) for a WON job/offer.
// Only the winning DJ/musician can read it; returns null otherwise.

final eventAddressByJobIdProvider = FutureProvider.autoDispose
    .family<String?, int>((ref, jobId) {
      return ref.watch(jobsRepositoryProvider).fetchEventAddress(jobId: jobId);
    });

final eventAddressByExtJobIdProvider = FutureProvider.autoDispose
    .family<String?, int>((ref, extJobId) {
      return ref
          .watch(jobsRepositoryProvider)
          .fetchEventAddress(extJobId: extJobId);
    });

// ─── Mutation notifiers ───────────────────────────────────────────────────────

class CreateDjQuoteNotifier extends StateNotifier<AsyncValue<DjQuote?>> {
  CreateDjQuoteNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> submit({
    required int jobId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    state = const AsyncLoading();
    try {
      final quote = await _repository.createDjQuote(
        userId: _currentUserId,
        jobId: jobId,
        priceDkk: priceDkk,
        equipmentDescription: equipmentDescription,
        salesPitch: salesPitch,
        earlySetupStatus: earlySetupStatus,
        earlySetupPrice: earlySetupPrice,
      );
      state = AsyncData(quote);
      _ref.read(newDjJobsProvider.notifier).silentRefresh();
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final createDjQuoteProvider = StateNotifierProvider.autoDispose<
  CreateDjQuoteNotifier,
  AsyncValue<DjQuote?>
>((ref) => CreateDjQuoteNotifier(ref.watch(jobsRepositoryProvider), ref));

class RejectDjJobNotifier extends StateNotifier<AsyncValue<void>> {
  RejectDjJobNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> reject(int jobId, {List<String> reasons = const []}) async {
    state = const AsyncLoading();
    try {
      await _repository.rejectDjJob(
        userId: _currentUserId,
        jobId: jobId,
        reasons: reasons,
      );
      state = const AsyncData(null);
      _ref.read(newDjJobsProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final rejectDjJobProvider =
    StateNotifierProvider.autoDispose<RejectDjJobNotifier, AsyncValue<void>>(
      (ref) => RejectDjJobNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

class CreateServiceOfferNotifier
    extends StateNotifier<AsyncValue<ServiceOffer?>> {
  CreateServiceOfferNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> submit({
    int? jobId,
    int? extJobId,
    required int priceDkk,
    required int musicianPayoutDkk,
    required String salesPitch,
    required String instrument,
  }) async {
    state = const AsyncLoading();
    try {
      final offer = await _repository.createServiceOffer(
        userId: _currentUserId,
        jobId: jobId,
        extJobId: extJobId,
        priceDkk: priceDkk,
        musicianPayoutDkk: musicianPayoutDkk,
        salesPitch: salesPitch,
        instrument: instrument,
      );
      state = AsyncData(offer);
      _ref.read(newInstrumentalistJobsProvider.notifier).silentRefresh();
      _ref.invalidate(instrumentalistExtJobsProvider);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final createServiceOfferProvider = StateNotifierProvider.autoDispose<
  CreateServiceOfferNotifier,
  AsyncValue<ServiceOffer?>
>((ref) => CreateServiceOfferNotifier(ref.watch(jobsRepositoryProvider), ref));

// ─── Contact customer notifiers ───────────────────────────────────────────────

class MarkJobContactedNotifier extends StateNotifier<AsyncValue<void>> {
  MarkJobContactedNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> markContacted(int jobId) async {
    state = const AsyncLoading();
    try {
      await _repository.markJobCustomerContacted(jobId);
      state = const AsyncData(null);
      _ref.invalidate(jobDetailProvider(jobId));
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// Not autoDispose: these mutation notifiers are read via `ref.read(.notifier)`
// from inside a modal bottom sheet, so nothing watches them. Under autoDispose
// the notifier is disposed before the async work completes, which then crashes
// when it tries to set `state` or invalidate dependent providers.
final markJobContactedProvider =
    StateNotifierProvider<MarkJobContactedNotifier, AsyncValue<void>>(
      (ref) => MarkJobContactedNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

class MarkExtJobContactedNotifier extends StateNotifier<AsyncValue<void>> {
  MarkExtJobContactedNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> markContacted(int extJobId) async {
    state = const AsyncLoading();
    try {
      await _repository.markExtJobCustomerContacted(extJobId);
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final markExtJobContactedProvider = StateNotifierProvider<
  MarkExtJobContactedNotifier,
  AsyncValue<void>
>((ref) => MarkExtJobContactedNotifier(ref.watch(jobsRepositoryProvider), ref));

class MarkServiceOfferContactedNotifier
    extends StateNotifier<AsyncValue<void>> {
  MarkServiceOfferContactedNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> markContacted(int offerId) async {
    state = const AsyncLoading();
    try {
      await _repository.markServiceOfferCustomerContacted(offerId);
      state = const AsyncData(null);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final markServiceOfferContactedProvider =
    StateNotifierProvider<MarkServiceOfferContactedNotifier, AsyncValue<void>>(
      (ref) => MarkServiceOfferContactedNotifier(
        ref.watch(jobsRepositoryProvider),
        ref,
      ),
    );

// ─── Planned contact notifiers ────────────────────────────────────────────────

class SetJobPlannedContactNotifier extends StateNotifier<AsyncValue<void>> {
  SetJobPlannedContactNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> setPlanned(int jobId, String date) async {
    state = const AsyncLoading();
    try {
      await _repository.setJobPlannedContact(jobId, date);
      state = const AsyncData(null);
      _ref.invalidate(jobDetailProvider(jobId));
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final setJobPlannedContactProvider =
    StateNotifierProvider<SetJobPlannedContactNotifier, AsyncValue<void>>(
      (ref) =>
          SetJobPlannedContactNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

class SetExtJobPlannedContactNotifier extends StateNotifier<AsyncValue<void>> {
  SetExtJobPlannedContactNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> setPlanned(int extJobId, String date) async {
    state = const AsyncLoading();
    try {
      await _repository.setExtJobPlannedContact(extJobId, date);
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final setExtJobPlannedContactProvider =
    StateNotifierProvider<SetExtJobPlannedContactNotifier, AsyncValue<void>>(
      (ref) => SetExtJobPlannedContactNotifier(
        ref.watch(jobsRepositoryProvider),
        ref,
      ),
    );

class SetServiceOfferPlannedContactNotifier
    extends StateNotifier<AsyncValue<void>> {
  SetServiceOfferPlannedContactNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> setPlanned(int offerId, String date) async {
    state = const AsyncLoading();
    try {
      await _repository.setServiceOfferPlannedContact(offerId, date);
      state = const AsyncData(null);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final setServiceOfferPlannedContactProvider = StateNotifierProvider<
  SetServiceOfferPlannedContactNotifier,
  AsyncValue<void>
>(
  (ref) => SetServiceOfferPlannedContactNotifier(
    ref.watch(jobsRepositoryProvider),
    ref,
  ),
);

// ─── Ready for billing notifiers ──────────────────────────────────────────────

class MarkJobReadyForBillingNotifier extends StateNotifier<AsyncValue<void>> {
  MarkJobReadyForBillingNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> markReady(int jobId) async {
    state = const AsyncLoading();
    try {
      await _repository.markJobReadyForBilling(jobId);
      state = const AsyncData(null);
      _ref.invalidate(jobDetailProvider(jobId));
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final markJobReadyForBillingProvider = StateNotifierProvider.autoDispose<
  MarkJobReadyForBillingNotifier,
  AsyncValue<void>
>(
  (ref) =>
      MarkJobReadyForBillingNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class MarkExtJobReadyForBillingNotifier
    extends StateNotifier<AsyncValue<void>> {
  MarkExtJobReadyForBillingNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> markReady(int extJobId) async {
    state = const AsyncLoading();
    try {
      await _repository.markExtJobReadyForBilling(extJobId);
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final markExtJobReadyForBillingProvider = StateNotifierProvider.autoDispose<
  MarkExtJobReadyForBillingNotifier,
  AsyncValue<void>
>(
  (ref) =>
      MarkExtJobReadyForBillingNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Jeg er klar notifiers ────────────────────────────────────────────────────

class ResolveEarlySetupNotifier extends StateNotifier<AsyncValue<void>> {
  ResolveEarlySetupNotifier(this._repository) : super(const AsyncData(null));

  final JobsRepository _repository;

  Future<bool> resolve(int quoteId, {required bool accepted}) async {
    state = const AsyncLoading();
    try {
      await _repository.resolveEarlySetup(quoteId, accepted: accepted);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final resolveEarlySetupProvider =
    StateNotifierProvider<ResolveEarlySetupNotifier, AsyncValue<void>>(
      (ref) => ResolveEarlySetupNotifier(ref.watch(jobsRepositoryProvider)),
    );

class ConfirmDjReadyNotifier extends StateNotifier<AsyncValue<void>> {
  ConfirmDjReadyNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> confirm(int quoteId) async {
    state = const AsyncLoading();
    try {
      await _repository.confirmDjReady(quoteId);
      state = const AsyncData(null);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final confirmDjReadyProvider =
    StateNotifierProvider.autoDispose<ConfirmDjReadyNotifier, AsyncValue<void>>(
      (ref) => ConfirmDjReadyNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

class ConfirmExtJobDjReadyNotifier extends StateNotifier<AsyncValue<void>> {
  ConfirmExtJobDjReadyNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> confirm(int extJobId) async {
    state = const AsyncLoading();
    try {
      await _repository.confirmExtJobDjReady(extJobId);
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final confirmExtJobDjReadyProvider = StateNotifierProvider.autoDispose<
  ConfirmExtJobDjReadyNotifier,
  AsyncValue<void>
>(
  (ref) => ConfirmExtJobDjReadyNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Extra hours notifiers ────────────────────────────────────────────────────

class AddExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  AddExtraHoursNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> add(
    int quoteId, {
    required double extraHours,
    required num pricePerHour,
    required int newTotalPrice,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.addExtraHours(
        quoteId,
        extraHours: extraHours,
        pricePerHour: pricePerHour,
        newTotalPrice: newTotalPrice,
      );
      state = const AsyncData(null);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final addExtraHoursProvider =
    StateNotifierProvider.autoDispose<AddExtraHoursNotifier, AsyncValue<void>>(
      (ref) => AddExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

class DeleteExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteExtraHoursNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> delete(int quoteId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteExtraHours(quoteId);
      state = const AsyncData(null);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final deleteExtraHoursProvider = StateNotifierProvider.autoDispose<
  DeleteExtraHoursNotifier,
  AsyncValue<void>
>((ref) => DeleteExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref));

class AddExtJobExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  AddExtJobExtraHoursNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> add(
    int extJobId, {
    required double extraHours,
    required num pricePerHour,
    required int newTotalPrice,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.addExtJobExtraHours(
        extJobId,
        extraHours: extraHours,
        pricePerHour: pricePerHour,
        newTotalPrice: newTotalPrice,
      );
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final addExtJobExtraHoursProvider = StateNotifierProvider.autoDispose<
  AddExtJobExtraHoursNotifier,
  AsyncValue<void>
>((ref) => AddExtJobExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref));

class DeleteExtJobExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteExtJobExtraHoursNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> delete(int extJobId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteExtJobExtraHours(extJobId);
      state = const AsyncData(null);
      _ref.invalidate(djExtJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final deleteExtJobExtraHoursProvider = StateNotifierProvider.autoDispose<
  DeleteExtJobExtraHoursNotifier,
  AsyncValue<void>
>(
  (ref) =>
      DeleteExtJobExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class EditDjQuoteNotifier extends StateNotifier<AsyncValue<DjQuote?>> {
  EditDjQuoteNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> edit({
    required int quoteId,
    required int priceDkk,
    required String equipmentDescription,
    required String salesPitch,
    String? earlySetupStatus,
    int? earlySetupPrice,
  }) async {
    state = const AsyncLoading();
    try {
      final quote = await _repository.editDjQuote(
        quoteId: quoteId,
        priceDkk: priceDkk,
        equipmentDescription: equipmentDescription,
        salesPitch: salesPitch,
        earlySetupStatus: earlySetupStatus,
        earlySetupPrice: earlySetupPrice,
      );
      state = AsyncData(quote);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final editDjQuoteProvider = StateNotifierProvider.autoDispose<
  EditDjQuoteNotifier,
  AsyncValue<DjQuote?>
>((ref) => EditDjQuoteNotifier(ref.watch(jobsRepositoryProvider), ref));

class ConfirmMusicianReadyNotifier extends StateNotifier<AsyncValue<void>> {
  ConfirmMusicianReadyNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> confirm(int offerId) async {
    state = const AsyncLoading();
    try {
      await _repository.confirmMusicianReady(offerId);
      state = const AsyncData(null);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final confirmMusicianReadyProvider = StateNotifierProvider.autoDispose<
  ConfirmMusicianReadyNotifier,
  AsyncValue<void>
>(
  (ref) => ConfirmMusicianReadyNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Save DJ Notes ────────────────────────────────────────────────────────────

class SaveDjNotesNotifier extends StateNotifier<AsyncValue<void>> {
  SaveDjNotesNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> save(int quoteId, String notes) async {
    state = const AsyncLoading();
    try {
      await _repository.saveDjNotes(quoteId, notes);
      state = const AsyncData(null);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final saveDjNotesProvider =
    StateNotifierProvider.autoDispose<SaveDjNotesNotifier, AsyncValue<void>>(
      (ref) => SaveDjNotesNotifier(ref.watch(jobsRepositoryProvider), ref),
    );

// ─── Date conflict check ──────────────────────────────────────────────────────

/// Returns true if the current musician already has a WON offer that time-conflicts with the target
/// booking (same date, gap < 3h). Open offers do NOT block. See [saxBookingsConflict].
final dateConflictProvider = FutureProvider.autoDispose
    .family<bool, SaxConflictQuery>((ref, query) async {
      return ref
          .watch(jobsRepositoryProvider)
          .hasDateConflict(
            _currentUserId,
            date: query.date,
            startTime: query.startTime,
            endTime: query.endTime,
          );
    });

// ─── Service offers for a job (DJ view) ─────────────────────────────────────

final serviceOffersForJobProvider = FutureProvider.autoDispose
    .family<List<ServiceOffer>, int>((ref, jobId) {
      return ref.watch(jobsRepositoryProvider).fetchServiceOffersForJob(jobId);
    });

// ─── Song requests for a job (DJ view) ───────────────────────────────────────

final songRequestsForJobProvider = FutureProvider.autoDispose
    .family<List<SongRequest>, int>((ref, jobId) {
      return ref.watch(jobsRepositoryProvider).fetchSongRequestsForJob(jobId);
    });

final songRequestsForExtJobProvider = FutureProvider.autoDispose
    .family<List<SongRequest>, int>((ref, extJobId) {
      return ref
          .watch(jobsRepositoryProvider)
          .fetchSongRequestsForExtJob(extJobId);
    });

// ─── Won DJ info for a job (Musician view) ───────────────────────────────────

final wonDjInfoForJobProvider = FutureProvider.autoDispose
    .family<({String djId, String fullName, String? phone})?, int>((
      ref,
      jobId,
    ) {
      return ref.watch(jobsRepositoryProvider).fetchWonDjInfoForJob(jobId);
    });

final userProfileImageProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, userId) {
      return ref.watch(jobsRepositoryProvider).fetchProfileImageUrl(userId);
    });

// ─── Musician extra hours ─────────────────────────────────────────────────────

class AddMusicianExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  AddMusicianExtraHoursNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> add(int offerId, {required double extraHours}) async {
    state = const AsyncLoading();
    try {
      await _repository.addMusicianExtraHours(offerId, extraHours: extraHours);
      state = const AsyncData(null);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final addMusicianExtraHoursProvider = StateNotifierProvider.autoDispose<
  AddMusicianExtraHoursNotifier,
  AsyncValue<void>
>(
  (ref) =>
      AddMusicianExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Special request fee ──────────────────────────────────────────────────────

class SetSpecialRequestFeeNotifier extends StateNotifier<AsyncValue<void>> {
  SetSpecialRequestFeeNotifier(this._repository) : super(const AsyncData(null));
  final JobsRepository _repository;

  Future<bool> set(int offerId, {required int feeDkk}) async {
    state = const AsyncLoading();
    try {
      await _repository.setSpecialRequestFee(offerId, feeDkk: feeDkk);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final setSpecialRequestFeeProvider = StateNotifierProvider.autoDispose<
  SetSpecialRequestFeeNotifier,
  AsyncValue<void>
>((ref) => SetSpecialRequestFeeNotifier(ref.watch(jobsRepositoryProvider)));

class RemoveSpecialRequestFeeNotifier extends StateNotifier<AsyncValue<void>> {
  RemoveSpecialRequestFeeNotifier(this._repository)
    : super(const AsyncData(null));
  final JobsRepository _repository;

  Future<bool> remove(int offerId) async {
    state = const AsyncLoading();
    try {
      await _repository.removeSpecialRequestFee(offerId);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final removeSpecialRequestFeeProvider = StateNotifierProvider.autoDispose<
  RemoveSpecialRequestFeeNotifier,
  AsyncValue<void>
>((ref) => RemoveSpecialRequestFeeNotifier(ref.watch(jobsRepositoryProvider)));

// ─── Musician notes ───────────────────────────────────────────────────────────

class SaveMusicianNotesNotifier extends StateNotifier<AsyncValue<void>> {
  SaveMusicianNotesNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> save(int offerId, String notes) async {
    state = const AsyncLoading();
    try {
      await _repository.saveMusicianNotes(offerId, notes);
      state = const AsyncData(null);
      _ref.read(serviceOffersProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final saveMusicianNotesProvider = StateNotifierProvider.autoDispose<
  SaveMusicianNotesNotifier,
  AsyncValue<void>
>((ref) => SaveMusicianNotesNotifier(ref.watch(jobsRepositoryProvider), ref));

// ─── Action counts ────────────────────────────────────────────────────────────

/// Won DJ quotes that need an action — for the "Du har vundet" tab badge
/// and the Jobs bottom-nav badge. Mirrors web app "Overblik" badge.
final djQuoteActionCountProvider = Provider<int>((ref) {
  final wonQuotes = ref.watch(wonDjQuotesProvider).valueOrNull ?? [];
  return wonQuotes.where((q) => q.hasAction).length;
});

/// Ext jobs that need an action — for the Udvalgte bottom-nav badge.
/// Mirrors web app "Udvalgte jobs" badge.
final djExtJobActionCountProvider = Provider<int>((ref) {
  final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
  return extJobs.where((e) => e.hasAction).length;
});

/// Combined count — kept for backwards compat if needed elsewhere.
final djWonActionCountProvider = Provider<int>(
  (ref) =>
      ref.watch(djQuoteActionCountProvider) +
      ref.watch(djExtJobActionCountProvider),
);

/// Number of won musician service offers that need an action.
/// Used for the red badge on the "Jobs accepteret" tab and the Jobs nav item.
final musicianWonActionCountProvider = Provider<int>((ref) {
  final wonOffers = ref.watch(wonServiceOffersProvider).valueOrNull ?? [];
  return wonOffers.where((o) => o.hasAction).length;
});
