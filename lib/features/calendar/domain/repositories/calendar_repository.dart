import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> fetchDjEvents(String userId);
  Future<List<CalendarEvent>> fetchMusicianEvents(String userId);

  Future<Map<String, int>> fetchDjUnavailableDates(String userId);
  Future<int> createDjUnavailableDate(String userId, String dateStr);
  Future<void> deleteDjUnavailableDate(int id);

  Future<Map<String, int>> fetchMusicianUnavailableDates(String userId);
  Future<int> createMusicianUnavailableDate(String userId, String dateStr);
  Future<void> deleteMusicianUnavailableDate(int id);
}
