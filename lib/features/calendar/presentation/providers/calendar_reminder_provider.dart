import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the "Husk at angive dine optaget-datoer" indicator on
/// Profile → Kalender.
///
/// The reminder is active from the 1st of each month until the user marks any
/// unavailable date that month, then reappears on the 1st of the next month.
/// We persist the last calendar month (`YYYY-MM`) in which the user set a date;
/// the reminder shows whenever that stored month is not the current month
/// (which includes "never set" and "new month started"). Purely local — no push
/// notification and no DB.
class CalendarReminderNotifier extends StateNotifier<bool> {
  CalendarReminderNotifier() : super(false) {
    _init();
  }

  static const _key = 'unavailability_reminder_handled_month';

  static String _monthKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final handledMonth = prefs.getString(_key);
    state = handledMonth != _monthKey(DateTime.now());
  }

  /// Re-evaluates whether the reminder should show (e.g. after a month rolls
  /// over while the app stays open). Safe to call on screen builds.
  Future<void> refresh() => _init();

  /// Call when the user marks an unavailable date — clears the reminder for the
  /// current month. It reappears on the 1st of next month.
  Future<void> markHandled() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _monthKey(DateTime.now()));
  }
}

final calendarReminderProvider =
    StateNotifierProvider<CalendarReminderNotifier, bool>(
      (ref) => CalendarReminderNotifier(),
    );
