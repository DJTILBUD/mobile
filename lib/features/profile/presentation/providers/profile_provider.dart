import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_job_filters.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/admin_message.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';
import 'package:dj_tilbud_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:dj_tilbud_app/features/profile/data/repositories/profile_repository_impl.dart';

// ── Repository provider ──

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final datasource = ProfileRemoteDatasource(client);
  return ProfileRepositoryImpl(datasource);
});

String get _userId => supabase.auth.currentUser!.id;

// ── DJ Profile ──

final djProfileProvider = FutureProvider<DjProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchDjProfile(_userId);
});

// ── Musician Profile ──

final musicianProfileProvider = FutureProvider<MusicianProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMusicianProfile(_userId);
});

// ── Payment Info ──

final djPaymentInfoProvider = FutureProvider<PaymentInfo?>((ref) {
  return ref
      .watch(profileRepositoryProvider)
      .fetchPaymentInfo(userId: _userId, isDj: true);
});

final musicianPaymentInfoProvider = FutureProvider<PaymentInfo?>((ref) {
  return ref
      .watch(profileRepositoryProvider)
      .fetchPaymentInfo(userId: _userId, isDj: false);
});

// ── Reviews ──

final djReviewsProvider = FutureProvider<List<Review>>((ref) {
  return ref
      .watch(profileRepositoryProvider)
      .fetchReviews(userId: _userId, isDj: true);
});

final musicianReviewsProvider = FutureProvider<List<Review>>((ref) {
  return ref
      .watch(profileRepositoryProvider)
      .fetchReviews(userId: _userId, isDj: false);
});

// ── User Files ──

final userFilesProvider = FutureProvider<List<UserFile>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchUserFiles(_userId);
});

// ── DJ Job Filters ──

final djJobFiltersProvider = FutureProvider<DjJobFilters?>((ref) {
  return ref.watch(profileRepositoryProvider).fetchDjJobFilters(_userId);
});

class SaveDjJobFiltersNotifier extends StateNotifier<AsyncValue<void>> {
  SaveDjJobFiltersNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final ProfileRepository _repository;
  final Ref _ref;

  Future<bool> save(DjJobFilters filters) async {
    state = const AsyncLoading();
    try {
      await _repository.saveDjJobFilters(filters);
      state = const AsyncData(null);
      _ref.invalidate(djJobFiltersProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final saveDjJobFiltersProvider = StateNotifierProvider.autoDispose<
  SaveDjJobFiltersNotifier,
  AsyncValue<void>
>((ref) => SaveDjJobFiltersNotifier(ref.watch(profileRepositoryProvider), ref));

// ── Musician Job Filters ──

final musicianJobFiltersProvider = FutureProvider<MusicianJobFilters?>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMusicianJobFilters(_userId);
});

class SaveMusicianJobFiltersNotifier extends StateNotifier<AsyncValue<void>> {
  SaveMusicianJobFiltersNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final ProfileRepository _repository;
  final Ref _ref;

  Future<bool> save(MusicianJobFilters filters) async {
    state = const AsyncLoading();
    try {
      await _repository.saveMusicianJobFilters(filters);
      state = const AsyncData(null);
      _ref.invalidate(musicianJobFiltersProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final saveMusicianJobFiltersProvider = StateNotifierProvider.autoDispose<
  SaveMusicianJobFiltersNotifier,
  AsyncValue<void>
>(
  (ref) =>
      SaveMusicianJobFiltersNotifier(ref.watch(profileRepositoryProvider), ref),
);

// ── Standard Messages ──

final standardMessagesProvider = FutureProvider<List<StandardMessage>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchStandardMessages(_userId);
});

// ── Admin Messages ──

final adminMessagesProvider = FutureProvider.family<List<AdminMessage>, bool>((
  ref,
  isDj,
) {
  return ref
      .watch(profileRepositoryProvider)
      .fetchAdminMessages(userId: _userId, isDj: isDj);
});

final unreadAdminMessageCountProvider = Provider.family<int, bool>((ref, isDj) {
  final messages = ref.watch(adminMessagesProvider(isDj)).valueOrNull ?? [];
  return messages.where((m) => !m.isRead).length;
});

class MarkAdminMessageReadNotifier extends StateNotifier<AsyncValue<void>> {
  MarkAdminMessageReadNotifier(this._repository) : super(const AsyncData(null));

  final ProfileRepository _repository;

  /// Marks one admin message read. Returns whether the write succeeded.
  ///
  /// ⚠️ EVERY `state =` after an await is guarded by `mounted`, and the outcome
  /// is RETURNED rather than published. This provider is `autoDispose` and
  /// **nothing watches it** — `admin_messages_screen` only `ref.read`s the
  /// notifier — so Riverpod disposes this instance as soon as `read` returns,
  /// long before the Supabase round-trip finishes. The old unguarded
  /// `state = await AsyncValue.guard(...)` therefore threw
  /// *"Tried to use MarkAdminMessageReadNotifier after `dispose` was called"*
  /// on **every** admin message a user opened. The DB write itself always went
  /// through — only the state write was invalid — which is why the message did
  /// get marked read while the app logged an unhandled exception.
  ///
  /// The general shape: an `autoDispose` StateNotifier that is only ever
  /// `ref.read` (never `ref.watch`) has NO listener keeping it alive, so it
  /// cannot safely publish anything after an await. Either watch it somewhere
  /// (that is why the ready-for-billing notifiers survive — `quote_detail_screen`
  /// watches them for the loading spinner) or return the result like this.
  Future<bool> mark({
    required int messageId,
    required String userId,
    required bool isDj,
  }) async {
    if (mounted) state = const AsyncLoading();
    try {
      await _repository.markAdminMessageRead(
        messageId: messageId,
        userId: userId,
        isDj: isDj,
      );
      if (mounted) state = const AsyncData(null);
      return true;
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
      return false;
    }
  }
}

final markAdminMessageReadProvider = StateNotifierProvider.autoDispose<
  MarkAdminMessageReadNotifier,
  AsyncValue<void>
>((ref) => MarkAdminMessageReadNotifier(ref.watch(profileRepositoryProvider)));

// ── iCal Token ──

final icalTokenProvider = FutureProvider.family<String?, bool>((
  ref,
  isDj,
) async {
  return ref
      .watch(profileRepositoryProvider)
      .fetchIcalToken(userId: _userId, isDj: isDj);
});

class GenerateIcalTokenNotifier extends StateNotifier<AsyncValue<String?>> {
  GenerateIcalTokenNotifier(this._repository, this._ref)
    : super(const AsyncData(null));

  final ProfileRepository _repository;
  final Ref _ref;

  Future<String?> generate({required bool isDj}) async {
    state = const AsyncLoading();
    try {
      final token = await _repository.generateIcalToken(
        userId: _userId,
        isDj: isDj,
      );
      state = AsyncData(token);
      _ref.invalidate(icalTokenProvider(isDj));
      return token;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final generateIcalTokenProvider = StateNotifierProvider.autoDispose<
  GenerateIcalTokenNotifier,
  AsyncValue<String?>
>(
  (ref) => GenerateIcalTokenNotifier(ref.watch(profileRepositoryProvider), ref),
);
