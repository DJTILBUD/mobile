import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> fetchDjEvents(String userId);
  Future<List<CalendarEvent>> fetchMusicianEvents(String userId);

  /// Returns a map of date strings ('yyyy-MM-dd') → rejection row id.
  Future<Map<String, int>> fetchDjUnavailableDates(String userId);

  /// Inserts an unavailable-date rejection. Returns the new row id.
  Future<int> createDjUnavailableDate(String userId, String dateStr);

  /// Deletes an unavailable-date rejection by row id.
  Future<void> deleteDjUnavailableDate(int id);
}
