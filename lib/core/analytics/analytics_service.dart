import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralised analytics wrapper. All event names and parameter keys
/// are defined here so they stay consistent across the codebase.
///
/// Call sites: prefer the static typed helpers over raw logEvent() calls.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Attach to GoRouter so screen_view events are logged automatically.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Offer funnel ──────────────────────────────────────────────────────────

  /// Fired when a job detail screen is opened.
  /// [source]: 'list' | 'notification' | 'calendar'
  static Future<void> logJobViewed(
    int jobId,
    String eventType, {
    String source = 'list',
    String jobStatus = 'open',
  }) =>
      _log('job_viewed', {
        'job_id': jobId,
        'event_type': eventType,
        'job_status': jobStatus,
        'source': source,
      });

  /// Fired when the offer/quote form is opened.
  /// [role]: 'dj' | 'musician'
  static Future<void> logOfferFormOpened(
    int jobId,
    String eventType, {
    required String role,
    bool hasConflict = false,
    bool hasActiveOffer = false,
  }) =>
      _log('offer_form_opened', {
        'job_id': jobId,
        'event_type': eventType,
        'role': role,
        'has_conflict': hasConflict,
        'has_active_offer': hasActiveOffer,
      });

  /// Fired on a successful offer/quote submission.
  static Future<void> logOfferSubmitted(
    int jobId,
    String eventType, {
    required String role,
    int pitchLength = 0,
    bool usedAiDraft = false,
  }) =>
      _log('offer_submitted', {
        'job_id': jobId,
        'event_type': eventType,
        'role': role,
        'pitch_length': pitchLength,
        'used_ai_draft': usedAiDraft,
      });

  /// Fired when the user exits the offer form after writing something
  /// without submitting.
  static Future<void> logOfferFormAbandoned(
    int jobId, {
    required String role,
  }) =>
      _log('offer_form_abandoned', {
        'job_id': jobId,
        'role': role,
      });

  // ── AI agent ─────────────────────────────────────────────────────────────

  /// Fired when the user taps "Skriv med AI".
  static Future<void> logAiDraftRequested(
    int jobId,
    String eventType, {
    required String role,
  }) =>
      _log('ai_draft_requested', {
        'job_id': jobId,
        'event_type': eventType,
        'role': role,
      });

  /// Fired when the AI finishes generating the draft.
  static Future<void> logAiDraftReceived(
    int jobId, {
    required int latencyMs,
  }) =>
      _log('ai_draft_received', {
        'job_id': jobId,
        'latency_ms': latencyMs,
      });

  /// Fired when the user taps "Brug dette udkast".
  static Future<void> logAiDraftAccepted(
    int jobId, {
    required String role,
  }) =>
      _log('ai_draft_accepted', {
        'job_id': jobId,
        'role': role,
      });

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Fired when the user taps a push notification.
  static Future<void> logNotificationTapped(
    String type, {
    String? role,
  }) =>
      _log('notification_tapped', {
        'notification_type': type,
        if (role != null) 'role': role,
      });

  // ── Calendar & availability ───────────────────────────────────────────────

  static Future<void> logDateMarkedUnavailable() =>
      _log('date_marked_unavailable', {});

  static Future<void> logDateUnmarkedUnavailable() =>
      _log('date_unmarked_unavailable', {});

  /// [toMode]: 'calendar' | 'list'
  static Future<void> logCalendarModeToggled({required String toMode}) =>
      _log('calendar_mode_toggled', {'to_mode': toMode});

  static Future<void> logDjFiltersToggled({required bool enabled}) =>
      _log('dj_filters_toggled', {'enabled': enabled});

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<void> _log(
    String name,
    Map<String, Object> params,
  ) =>
      _analytics.logEvent(name: name, parameters: params.isEmpty ? null : params);
}
