import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_provider.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:dj_tilbud_app/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:dj_tilbud_app/features/calendar/domain/repositories/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CalendarRepositoryImpl(CalendarRemoteDatasource(client));
});

class CalendarEventsNotifier
    extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  CalendarEventsNotifier(this._repository, this._role)
      : super(const AsyncLoading()) {
    _load();
  }

  final CalendarRepository _repository;
  final MusicianRole _role;

  Future<void> _load() async {
    final userId = supabase.auth.currentUser!.id;
    try {
      final events = _role == MusicianRole.dj
          ? await _repository.fetchDjEvents(userId)
          : await _repository.fetchMusicianEvents(userId);
      state = AsyncData(events);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _load();
  }
}

final calendarEventsProvider = StateNotifierProvider.family<
    CalendarEventsNotifier,
    AsyncValue<List<CalendarEvent>>,
    MusicianRole>((ref, role) {
  return CalendarEventsNotifier(
    ref.watch(calendarRepositoryProvider),
    role,
  );
});

// ── Unavailable dates (DJ only) ──

/// Tracks manually-marked unavailable dates for the current DJ.
/// State: map of 'yyyy-MM-dd' → DjJobRejection row id (for deletion).
class DjUnavailableDatesNotifier
    extends StateNotifier<AsyncValue<Map<String, int>>> {
  DjUnavailableDatesNotifier(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final CalendarRepository _repository;

  Future<void> _load() async {
    final userId = supabase.auth.currentUser!.id;
    try {
      final dateToId = await _repository.fetchDjUnavailableDates(userId);
      state = AsyncData(dateToId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Adds a date as unavailable (used from the job view). Returns true on success.
  Future<bool> addDate(String userId, String dateStr) async {
    final current = Map<String, int>.from(state.valueOrNull ?? {});
    if (current.containsKey(dateStr)) return true; // already marked
    final next = Map<String, int>.from(current)..[dateStr] = -1;
    state = AsyncData(next);
    try {
      final newId = await _repository.createDjUnavailableDate(userId, dateStr);
      final updated = Map<String, int>.from(state.valueOrNull ?? next)
        ..[dateStr] = newId;
      state = AsyncData(updated);
      return true;
    } catch (_) {
      final rollback = Map<String, int>.from(state.valueOrNull ?? next)
        ..remove(dateStr);
      state = AsyncData(rollback);
      return false;
    }
  }

  /// Optimistically toggles a date as unavailable/available.
  Future<void> toggle(String dateStr) async {
    final current = Map<String, int>.from(state.valueOrNull ?? {});
    final userId = supabase.auth.currentUser!.id;

    if (current.containsKey(dateStr)) {
      final id = current[dateStr]!;
      final next = Map<String, int>.from(current)..remove(dateStr);
      state = AsyncData(next);
      try {
        await _repository.deleteDjUnavailableDate(id);
      } catch (_) {
        state = AsyncData(current); // rollback
      }
    } else {
      final next = Map<String, int>.from(current)..[dateStr] = -1;
      state = AsyncData(next);
      try {
        final newId =
            await _repository.createDjUnavailableDate(userId, dateStr);
        final updated = Map<String, int>.from(state.valueOrNull ?? next)
          ..[dateStr] = newId;
        state = AsyncData(updated);
      } catch (_) {
        final rollback = Map<String, int>.from(state.valueOrNull ?? next)
          ..remove(dateStr);
        state = AsyncData(rollback);
      }
    }
  }
}

final djUnavailableDatesProvider = StateNotifierProvider<
    DjUnavailableDatesNotifier,
    AsyncValue<Map<String, int>>>((ref) {
  return DjUnavailableDatesNotifier(ref.watch(calendarRepositoryProvider));
});
