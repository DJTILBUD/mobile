import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
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
  final list = await ref.watch(jobsRepositoryProvider).fetchDjExtJobs(_currentUserId);
  list.sort((a, b) => a.date.compareTo(b.date));
  return list;
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
  final profileAsync = ref.watch(djProfileProvider);
  final filtersEnabled = ref.watch(djFiltersEnabledProvider);
  final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
  final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];

  return jobs.whenData((jobList) {
    final profile = profileAsync.valueOrNull;
    final filters = filtersAsync.valueOrNull;

    // If DJ is suppressed, show no jobs (matches web app: !djInfo.is_suppressed)
    if (profile?.isSuppressed == true) return [];

    final filtered = jobList.where((job) {
      // Hard constraint: event types excluded on the DJ profile (not a user toggle)
      if (profile != null && profile.excludedEventTypes.isNotEmpty) {
        final jobType = job.eventType.trim().toLowerCase();
        if (profile.excludedEventTypes
            .any((e) => e.trim().toLowerCase() == jobType)) {
          return false;
        }
      }

      // Hard constraint: don't show saxophonist jobs to DJs who can't play sax
      if (job.requestedSaxophonist && profile?.canPlayWithSax == false) {
        return false;
      }

      // Optional filters from DjJobFilters (user-controlled preferences)
      if (filtersEnabled && filters != null && filters.hasActiveFilters) {
        if (_isJobExcludedByFilters(job, filters)) return false;
      }

      return true;
    }).toList();

    // Sort: non-colliding jobs first, then newest created_at within each group.
    // Mirrors unbidJobsCompareFunction from the web app.
    filtered.sort((a, b) {
      final aCollides = _jobCollides(a, quotes, extJobs);
      final bCollides = _jobCollides(b, quotes, extJobs);
      if (aCollides && !bCollides) return 1;
      if (!aCollides && bCollides) return -1;
      return b.createdAt.compareTo(a.createdAt); // newest first
    });

    return filtered;
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
  if (f.excludedGenres.isNotEmpty && job.genres != null && job.genres!.isNotEmpty) {
    if (job.genres!.any((g) => f.excludedGenres.contains(g))) return true;
  }

  if (f.allowedWeekdays != null) {
    // DateTime.weekday: 1=Mon…7=Sun  →  map to  0=Sun…6=Sat
    final dartWeekday = job.date.weekday;
    final jsWeekday = dartWeekday == 7 ? 0 : dartWeekday;
    if (!f.allowedWeekdays!.contains(jsWeekday)) return true;
  }

  if (f.minBudget != null && job.budgetEnd != null && job.budgetEnd! < f.minBudget!) return true;
  if (f.maxBudget != null && job.budgetStart != null && job.budgetStart! > f.maxBudget!) return true;
  if (f.minGuests != null && job.guestsAmount < f.minGuests!) return true;
  if (f.maxGuests != null && job.guestsAmount > f.maxGuests!) return true;

  return false;
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Mirrors collidingQuote() from useCollidingQuote.ts.
/// Returns true if the job date collides with an existing ext job or
/// active quote (won = always blocks; 2+ pending = blocks).
bool _jobCollides(Job job, List<DjQuote> quotes, List<ExtJob> extJobs) {
  // Ext job assigned on the same date
  if (extJobs.any((e) => _sameDate(e.date, job.date))) return true;

  // Active quotes on the same date (exclude lost/overwritten and the same job)
  final onSameDate = quotes.where((q) =>
      _sameDate(q.job.date, job.date) &&
      q.status != QuoteStatus.lost &&
      q.status != QuoteStatus.overwritten &&
      q.job.id != job.id).toList();

  // A won job on the same date blocks all new bids
  if (onSameDate.any((q) => q.status == QuoteStatus.won)) return true;

  // 2 or more pending quotes on the same date blocks a third bid
  final pending = onSameDate.where((q) => q.status == QuoteStatus.pending).length;
  return pending >= 2;
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
    final list = quotes
        .where((q) =>
            q.status == QuoteStatus.lost ||
            q.status == QuoteStatus.overwritten)
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
  }
}

final newInstrumentalistJobsProvider = StateNotifierProvider<
    NewInstrumentalistJobsNotifier, AsyncValue<List<Job>>>(
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
/// Sort order: eligible first (newest created_at) → active offer (taken but biddable)
/// → date conflict (musician already booked). Mirrors web app priority logic.
final combinedInstrumentalistJobsProvider =
    Provider<AsyncValue<List<Job>>>((ref) {
  final regular = ref.watch(newInstrumentalistJobsProvider);
  final ext = ref.watch(instrumentalistExtJobsProvider);

  if (regular is AsyncLoading || ext is AsyncLoading) {
    return const AsyncLoading();
  }
  if (regular is AsyncError) return regular;
  if (ext is AsyncError) return ext;

  int tier(Job j) {
    if (j.hasDateConflict) return 2;
    if (j.hasActiveOffer) return 1;
    return 0;
  }

  final combined = <Job>[
    ...regular.valueOrNull ?? [],
    ...ext.valueOrNull ?? [],
  ]..sort((a, b) {
      final tierDiff = tier(a).compareTo(tier(b));
      if (tierDiff != 0) return tierDiff;
      return b.createdAt.compareTo(a.createdAt); // newest first within tier
    });

  return AsyncData(combined);
});

// ─── Instrumentalist: service offers ─────────────────────────────────────────

class ServiceOffersNotifier extends _RealtimeNotifier<List<ServiceOffer>> {
  ServiceOffersNotifier(super.client, this._repository, this._userId) {
    init();
  }

  final JobsRepository _repository;
  final String _userId;

  @override
  Future<List<ServiceOffer>> fetch() =>
      _repository.fetchServiceOffers(_userId);

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

final serviceOffersProvider =
    StateNotifierProvider<ServiceOffersNotifier, AsyncValue<List<ServiceOffer>>>(
  (ref) => ServiceOffersNotifier(
    ref.watch(supabaseClientProvider),
    ref.watch(jobsRepositoryProvider),
    _currentUserId,
  ),
);

final sentServiceOffersProvider = Provider<AsyncValue<List<ServiceOffer>>>((ref) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list = offers.where((o) => o.status == ServiceOfferStatus.sent).toList();
    list.sort((a, b) => a.job.date.compareTo(b.job.date));
    return list;
  });
});

final wonServiceOffersProvider = Provider<AsyncValue<List<ServiceOffer>>>((ref) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list = offers.where((o) => o.status == ServiceOfferStatus.won).toList();
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

final expiredServiceOffersProvider =
    Provider<AsyncValue<List<ServiceOffer>>>((ref) {
  return ref.watch(serviceOffersProvider).whenData((offers) {
    final list = offers.where((o) => o.status == ServiceOfferStatus.lost).toList();
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
final invoiceStatusByJobIdProvider =
    FutureProvider.autoDispose.family<bool?, int>((ref, jobId) {
  return ref.watch(jobsRepositoryProvider).fetchInvoiceStatus(jobId: jobId);
});

/// first_invoice_paid for an ext job (instrumentalist offer on ext job).
final invoiceStatusByExtJobIdProvider =
    FutureProvider.autoDispose.family<bool?, int>((ref, extJobId) {
  return ref
      .watch(jobsRepositoryProvider)
      .fetchInvoiceStatus(extJobId: extJobId);
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

final createDjQuoteProvider =
    StateNotifierProvider.autoDispose<CreateDjQuoteNotifier, AsyncValue<DjQuote?>>(
  (ref) => CreateDjQuoteNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class RejectDjJobNotifier extends StateNotifier<AsyncValue<void>> {
  RejectDjJobNotifier(this._repository, this._ref)
      : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> reject(int jobId, {List<String> reasons = const []}) async {
    state = const AsyncLoading();
    try {
      await _repository.rejectDjJob(
          userId: _currentUserId, jobId: jobId, reasons: reasons);
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
    CreateServiceOfferNotifier, AsyncValue<ServiceOffer?>>(
  (ref) =>
      CreateServiceOfferNotifier(ref.watch(jobsRepositoryProvider), ref),
);

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

final markJobContactedProvider =
    StateNotifierProvider.autoDispose<MarkJobContactedNotifier, AsyncValue<void>>(
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

final markExtJobContactedProvider =
    StateNotifierProvider.autoDispose<MarkExtJobContactedNotifier, AsyncValue<void>>(
  (ref) =>
      MarkExtJobContactedNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class MarkServiceOfferContactedNotifier extends StateNotifier<AsyncValue<void>> {
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

final markServiceOfferContactedProvider = StateNotifierProvider.autoDispose<
    MarkServiceOfferContactedNotifier, AsyncValue<void>>(
  (ref) => MarkServiceOfferContactedNotifier(
      ref.watch(jobsRepositoryProvider), ref),
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
    StateNotifierProvider.autoDispose<SetJobPlannedContactNotifier, AsyncValue<void>>(
  (ref) => SetJobPlannedContactNotifier(ref.watch(jobsRepositoryProvider), ref),
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
    StateNotifierProvider.autoDispose<SetExtJobPlannedContactNotifier, AsyncValue<void>>(
  (ref) =>
      SetExtJobPlannedContactNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class SetServiceOfferPlannedContactNotifier extends StateNotifier<AsyncValue<void>> {
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

final setServiceOfferPlannedContactProvider =
    StateNotifierProvider.autoDispose<SetServiceOfferPlannedContactNotifier, AsyncValue<void>>(
  (ref) => SetServiceOfferPlannedContactNotifier(
      ref.watch(jobsRepositoryProvider), ref),
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
    MarkJobReadyForBillingNotifier, AsyncValue<void>>(
  (ref) =>
      MarkJobReadyForBillingNotifier(ref.watch(jobsRepositoryProvider), ref),
);

class MarkExtJobReadyForBillingNotifier extends StateNotifier<AsyncValue<void>> {
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
    MarkExtJobReadyForBillingNotifier, AsyncValue<void>>(
  (ref) => MarkExtJobReadyForBillingNotifier(
      ref.watch(jobsRepositoryProvider), ref),
);

// ─── Jeg er klar notifiers ────────────────────────────────────────────────────

class ResolveEarlySetupNotifier extends StateNotifier<AsyncValue<void>> {
  ResolveEarlySetupNotifier(this._repository)
      : super(const AsyncData(null));

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

final resolveEarlySetupProvider = StateNotifierProvider<
    ResolveEarlySetupNotifier, AsyncValue<void>>(
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

final confirmDjReadyProvider = StateNotifierProvider.autoDispose<
    ConfirmDjReadyNotifier, AsyncValue<void>>(
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
    ConfirmExtJobDjReadyNotifier, AsyncValue<void>>(
  (ref) =>
      ConfirmExtJobDjReadyNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Extra hours notifiers ────────────────────────────────────────────────────

class AddExtraHoursNotifier extends StateNotifier<AsyncValue<void>> {
  AddExtraHoursNotifier(this._repository, this._ref)
      : super(const AsyncData(null));

  final JobsRepository _repository;
  final Ref _ref;

  Future<bool> add(int quoteId, {required double extraHours, required int pricePerHour}) async {
    state = const AsyncLoading();
    try {
      await _repository.addExtraHours(quoteId, extraHours: extraHours, pricePerHour: pricePerHour);
      state = const AsyncData(null);
      _ref.read(djQuotesProvider.notifier).silentRefresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final addExtraHoursProvider = StateNotifierProvider.autoDispose<
    AddExtraHoursNotifier, AsyncValue<void>>(
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
    DeleteExtraHoursNotifier, AsyncValue<void>>(
  (ref) => DeleteExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref),
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
    EditDjQuoteNotifier, AsyncValue<DjQuote?>>(
  (ref) => EditDjQuoteNotifier(ref.watch(jobsRepositoryProvider), ref),
);

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
    ConfirmMusicianReadyNotifier, AsyncValue<void>>(
  (ref) =>
      ConfirmMusicianReadyNotifier(ref.watch(jobsRepositoryProvider), ref),
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

final saveDjNotesProvider = StateNotifierProvider.autoDispose<
    SaveDjNotesNotifier, AsyncValue<void>>(
  (ref) => SaveDjNotesNotifier(ref.watch(jobsRepositoryProvider), ref),
);

// ─── Date conflict check ──────────────────────────────────────────────────────

/// Returns true if the current musician already has a sent/won offer on [date].
final dateConflictProvider =
    FutureProvider.autoDispose.family<bool, DateTime>((ref, date) async {
  return ref.watch(jobsRepositoryProvider).hasDateConflict(_currentUserId, date);
});

// ─── Service offers for a job (DJ view) ─────────────────────────────────────

final serviceOffersForJobProvider =
    FutureProvider.autoDispose.family<List<ServiceOffer>, int>((ref, jobId) {
  return ref.watch(jobsRepositoryProvider).fetchServiceOffersForJob(jobId);
});

// ─── Won DJ info for a job (Musician view) ───────────────────────────────────

final wonDjInfoForJobProvider = FutureProvider.autoDispose
    .family<({String djId, String fullName, String? phone})?, int>((ref, jobId) {
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
    AddMusicianExtraHoursNotifier, AsyncValue<void>>(
  (ref) =>
      AddMusicianExtraHoursNotifier(ref.watch(jobsRepositoryProvider), ref),
);

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
    SaveMusicianNotesNotifier, AsyncValue<void>>(
  (ref) => SaveMusicianNotesNotifier(ref.watch(jobsRepositoryProvider), ref),
);

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
final djWonActionCountProvider = Provider<int>((ref) =>
    ref.watch(djQuoteActionCountProvider) +
    ref.watch(djExtJobActionCountProvider));

/// Number of won musician service offers that need an action.
/// Used for the red badge on the "Jobs accepteret" tab and the Jobs nav item.
final musicianWonActionCountProvider = Provider<int>((ref) {
  final wonOffers = ref.watch(wonServiceOffersProvider).valueOrNull ?? [];
  return wonOffers.where((o) => o.hasAction).length;
});
