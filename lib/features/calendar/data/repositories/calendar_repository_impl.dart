import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:dj_tilbud_app/features/calendar/data/models/calendar_event_model.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:dj_tilbud_app/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._datasource);

  final CalendarRemoteDatasource _datasource;

  @override
  Future<List<CalendarEvent>> fetchDjEvents(String userId) async {
    try {
      final quotesData = await _datasource.fetchDjWonQuotes(userId);
      final extJobsData = await _datasource.fetchDjAssignedExtJobs(userId);

      final events = <CalendarEvent>[];

      for (final row in quotesData) {
        if (row['job'] != null) {
          events.add(CalendarEventModel.fromDjQuoteJson(row).toEntity());
        }
      }
      for (final row in extJobsData) {
        events.add(CalendarEventModel.fromDjExtJobJson(row).toEntity());
      }

      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<List<CalendarEvent>> fetchMusicianEvents(String userId) async {
    try {
      final jobOffersData =
          await _datasource.fetchMusicianWonJobOffers(userId);
      final extJobOffersData =
          await _datasource.fetchMusicianWonExtJobOffers(userId);

      final events = <CalendarEvent>[];

      for (final row in jobOffersData) {
        if (row['job'] != null) {
          events
              .add(CalendarEventModel.fromMusicianJobOfferJson(row).toEntity());
        }
      }
      for (final row in extJobOffersData) {
        if (row['ext_job'] != null) {
          events.add(
              CalendarEventModel.fromMusicianExtJobOfferJson(row).toEntity());
        }
      }

      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  static const _unavailablePrefix = '__unavailable_date__:';

  @override
  Future<Map<String, int>> fetchDjUnavailableDates(String userId) async {
    try {
      final rows =
          await _datasource.fetchDjUnavailableDateRejections(userId);
      final result = <String, int>{};
      for (final row in rows) {
        final id = (row['id'] as num).toInt();
        final reasons = (row['reason'] as List?)?.cast<String>() ?? [];
        for (final reason in reasons) {
          if (reason.startsWith(_unavailablePrefix)) {
            final date = reason.substring(_unavailablePrefix.length);
            if (date.isNotEmpty) result[date] = id;
          }
        }
      }
      return result;
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<int> createDjUnavailableDate(String userId, String dateStr) async {
    try {
      final row = await _datasource.createDjUnavailableDate(userId, dateStr);
      return (row['id'] as num).toInt();
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteDjUnavailableDate(int id) async {
    try {
      await _datasource.deleteDjUnavailableDate(id);
    } on sb.PostgrestException catch (e) {
      throw DatabaseException(e.message);
    }
  }
}
