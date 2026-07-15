import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Bounded reasons for [AnalyticsService.logOfferSubmitFailed].
///
/// A closed set on purpose: raw `error.message` text would explode the dimension
/// and is Danish user-facing copy that changes freely. Map to these instead.
abstract final class OfferSubmitFailure {
  /// Already has a won quote / 2 pending / a confirmed ext job on that date.
  static const dateCollision = 'date_collision';

  /// B-tier DJ bidding over the budget cap inside the first 4 hours.
  static const overBudgetFirst4h = 'over_budget_first_4h';

  /// Payment/billing info incomplete.
  static const billingIncomplete = 'billing_incomplete';

  /// Equipment description missing/invalid.
  static const equipmentInvalid = 'equipment_invalid';

  /// Price/pitch failed local validation.
  static const invalidInput = 'invalid_input';

  /// Account suppressed, or DJ tier 'C' (blocked-by-default).
  static const suppressedOrBlocked = 'suppressed_or_blocked';

  /// Tier quota / pending-quote cap reached.
  static const tierQuota = 'tier_quota';

  /// Job no longer accepting offers (paused/expired/closed).
  static const jobUnavailable = 'job_unavailable';

  /// Anything else the server rejected.
  static const serverError = 'server_error';

  /// Maps the server's rejection text onto one of the slugs above.
  ///
  /// Matches DANISH: the web API authors its reasons as Danish user-facing copy.
  /// Matching English is a mistake this codebase has already made once (see
  /// mobile/CLAUDE.md on the ready-for-billing blocker), which is why this is
  /// spelled out here rather than re-guessed per screen.
  ///
  /// Copy changes degrade a reason to [serverError] rather than breaking, which
  /// is also why the raw message is never used as the dimension itself: it is
  /// unbounded and would explode the cardinality.
  static String fromServerMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('samme dato') || m.contains('kollider'))
      return dateCollision;
    if (m.contains('maksimalt') || m.contains('kvote') || m.contains('3 bud')) {
      return tierQuota;
    }
    if (m.contains('deaktiveret') ||
        m.contains('spærret') ||
        m.contains('godkend')) {
      return suppressedOrBlocked;
    }
    if (m.contains('pause') || m.contains('udløbet') || m.contains('lukket')) {
      return jobUnavailable;
    }
    return serverError;
  }
}

/// Centralised analytics wrapper. All event names and parameter keys
/// are defined here so they stay consistent across the codebase.
///
/// Call sites: prefer the static typed helpers over raw logEvent() calls.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Attach to GoRouter so screen_view events are logged automatically.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Collection gate ───────────────────────────────────────────────────────

  static bool _enabled = true;

  /// Turns collection on/off. There is ONE Firebase project for every env, so
  /// without this every `flutter run` against local Supabase writes real events
  /// to the production GA4 property. Call with `EnvConfig.isProd` at startup,
  /// and with `false` while impersonating a real user from a debug build (an
  /// impersonated session would otherwise attribute that user's behaviour to the
  /// developer's device).
  ///
  /// Also flips the SDK's own switch, which persists to disk — that is what
  /// suppresses the background isolate (`_firebaseBackgroundHandler`), since a
  /// fresh isolate does not inherit [_enabled].
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      await _analytics.setAnalyticsCollectionEnabled(value);
    } catch (e) {
      debugPrint('[AnalyticsService] setAnalyticsCollectionEnabled failed: $e');
    }
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  /// Identifies the signed-in user so GA4 events can be joined to Supabase rows
  /// (`Musicians`, `AgentInteractions`, `NotificationLogs`). Without this GA4
  /// only knows device pseudo-IDs, so no question spanning GA4 and Postgres
  /// (e.g. "did the AI draft win more jobs?") is answerable.
  /// [role] is nullable on purpose: Supabase fires `signedIn` BEFORE
  /// `RoleCache.save(role)` runs, so on a first login the role is not known yet.
  /// The id is the part that matters for joining; the property fills in on the
  /// next `initialSession`.
  static Future<void> setUser({required String userId, String? role}) async {
    if (!_enabled) return;
    try {
      await _analytics.setUserId(id: userId);
      if (role != null) {
        await _analytics.setUserProperty(name: 'role', value: role);
      }
    } catch (e) {
      debugPrint('[AnalyticsService] setUser failed: $e');
    }
  }

  /// Clears identity on logout. Without the reset the device pseudo-ID persists,
  /// so a second user signing in on the same device is merged into the first.
  static Future<void> clearUser() async {
    if (!_enabled) return;
    try {
      await _analytics.setUserId(id: null);
      await _analytics.setUserProperty(name: 'role', value: null);
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('[AnalyticsService] clearUser failed: $e');
    }
  }

  // ── Offer funnel ──────────────────────────────────────────────────────────

  // `job_id` alone is ambiguous: Jobs and ExtJobs are separate id spaces, so id
  // 491 can exist as both. Every job-scoped event carries `is_ext_job` so the two
  // can be told apart downstream.

  /// Fired when a job detail screen is opened.
  /// [source]: 'list' | 'notification' | 'calendar'
  static Future<void> logJobViewed(
    int jobId,
    String eventType, {
    required String source,
    String jobStatus = 'open',
    bool isExtJob = false,
  }) => _log('job_viewed', {
    'job_id': jobId,
    'event_type': eventType,
    'job_status': jobStatus,
    'source': source,
    'is_ext_job': isExtJob ? 1 : 0,
  });

  /// Fired when the offer/quote form is opened.
  ///
  /// This is the real top of the funnel: nothing routes to the job-detail screen,
  /// so a musician goes straight from feed/push/calendar/chat into this form.
  /// [source] is therefore where attribution lives — 'list' | 'notification' |
  /// 'calendar' | 'chat'.
  /// [role]: 'dj' | 'musician'
  static Future<void> logOfferFormOpened(
    int jobId,
    String eventType, {
    required String role,
    required String source,
    required bool hasConflict,
    required bool hasActiveOffer,
    bool isExtJob = false,
    String? tier,
  }) => _log('offer_form_opened', {
    'job_id': jobId,
    'event_type': eventType,
    'role': role,
    'source': source,
    'has_conflict': hasConflict ? 1 : 0,
    'has_active_offer': hasActiveOffer ? 1 : 0,
    'is_ext_job': isExtJob ? 1 : 0,
    if (tier != null) 'tier': tier,
  });

  /// Fired when the user hits submit, BEFORE validation and the server call.
  ///
  /// Paired with [logOfferSubmitted] / [logOfferSubmitFailed] so a submit success
  /// rate is computable. Previously only the success was logged, which made every
  /// rejection (date collision, tier quota, suppression) invisible.
  static Future<void> logOfferSubmitAttempted(
    int jobId, {
    required String role,
    bool isExtJob = false,
    int pitchLength = 0,
    bool usedAiDraft = false,
    int? msSinceFormOpen,
  }) => _log('offer_submit_attempted', {
    'job_id': jobId,
    'role': role,
    'is_ext_job': isExtJob ? 1 : 0,
    'pitch_length': pitchLength,
    'used_ai_draft': usedAiDraft ? 1 : 0,
    if (msSinceFormOpen != null) 'ms_since_form_open': msSinceFormOpen,
  });

  /// Fired when a submit is rejected.
  ///
  /// [reason] must be one of [OfferSubmitFailure] — a bounded slug, so the
  /// dimension stays groupable instead of becoming free-text error strings.
  /// [errorSource]: 'client' (local validation) | 'server' (API rejection).
  static Future<void> logOfferSubmitFailed(
    int jobId, {
    required String role,
    required String reason,
    required String errorSource,
    bool isExtJob = false,
    int? msSinceFormOpen,
  }) => _log('offer_submit_failed', {
    'job_id': jobId,
    'role': role,
    'reason': reason,
    'error_source': errorSource,
    'is_ext_job': isExtJob ? 1 : 0,
    if (msSinceFormOpen != null) 'ms_since_form_open': msSinceFormOpen,
  });

  /// Fired on a successful offer/quote submission.
  static Future<void> logOfferSubmitted(
    int jobId,
    String eventType, {
    required String role,
    int pitchLength = 0,
    bool usedAiDraft = false,
    bool isExtJob = false,
    int? msSinceFormOpen,
  }) => _log('offer_submitted', {
    'job_id': jobId,
    'event_type': eventType,
    'role': role,
    'pitch_length': pitchLength,
    'used_ai_draft': usedAiDraft ? 1 : 0,
    'is_ext_job': isExtJob ? 1 : 0,
    if (msSinceFormOpen != null) 'ms_since_form_open': msSinceFormOpen,
  });

  /// Fired when the user leaves the offer form without submitting.
  ///
  /// Fires even when nothing was typed ([wasDirty] = false): "opened it, read the
  /// budget, backed out" is the hesitation signal, and it used to be dropped
  /// because only the dirty-form confirm dialog logged.
  static Future<void> logOfferFormAbandoned(
    int jobId, {
    required String role,
    required bool wasDirty,
    bool isExtJob = false,
    int pitchLength = 0,
    int? msOnForm,
  }) => _log('offer_form_abandoned', {
    'job_id': jobId,
    'role': role,
    'was_dirty': wasDirty ? 1 : 0,
    'is_ext_job': isExtJob ? 1 : 0,
    'pitch_length': pitchLength,
    if (msOnForm != null) 'ms_on_form': msOnForm,
  });

  /// Fired when a DJ explicitly turns a job down.
  ///
  /// [method]: 'not_interested' | 'marked_busy'. [reasons] is the picker's own
  /// answer to "why didn't you bid?" — already collected and written to the DB,
  /// it just was not being emitted.
  static Future<void> logJobDismissed(
    int jobId, {
    required String role,
    required String method,
    String? reasons,
  }) => _log('job_dismissed', {
    'job_id': jobId,
    'role': role,
    'method': method,
    if (reasons != null) 'reasons': reasons,
  });

  // ── AI agent ─────────────────────────────────────────────────────────────

  /// Fired when the user taps "Skriv med AI".
  static Future<void> logAiDraftRequested(
    int jobId,
    String eventType, {
    required String role,
  }) => _log('ai_draft_requested', {
    'job_id': jobId,
    'event_type': eventType,
    'role': role,
  });

  /// Fired when the AI finishes generating the draft.
  static Future<void> logAiDraftReceived(int jobId, {required int latencyMs}) =>
      _log('ai_draft_received', {'job_id': jobId, 'latency_ms': latencyMs});

  /// Fired when the user taps "Brug dette udkast".
  static Future<void> logAiDraftAccepted(int jobId, {required String role}) =>
      _log('ai_draft_accepted', {'job_id': jobId, 'role': role});

  // ── Post-submit lifecycle ─────────────────────────────────────────────────

  /// Fired when the performer marks the customer as contacted.
  static Future<void> logCustomerContacted(
    int jobId, {
    required String role,
    bool isExtJob = false,
    bool planned = false,
  }) => _log('customer_contacted', {
    'job_id': jobId,
    'role': role,
    'is_ext_job': isExtJob ? 1 : 0,
    // true = scheduled a future contact date rather than contacting now.
    'planned': planned ? 1 : 0,
  });

  /// Fired when the performer marks a job ready for billing.
  static Future<void> logReadyForBilling(
    int jobId, {
    required String role,
    bool isExtJob = false,
  }) => _log('ready_for_billing', {
    'job_id': jobId,
    'role': role,
    'is_ext_job': isExtJob ? 1 : 0,
  });

  /// Fired when a DJ uploads a job-content clip.
  static Future<void> logContentUploaded({int? jobId, bool isExtJob = false}) =>
      _log('content_uploaded', {
        if (jobId != null) 'job_id': jobId,
        'is_ext_job': isExtJob ? 1 : 0,
      });

  // ── Auth & activation ─────────────────────────────────────────────────────

  static Future<void> logLoginSucceeded({String? role}) =>
      _log('login_succeeded', {if (role != null) 'role': role});

  /// [reason]: a bounded slug, never the raw exception text.
  static Future<void> logLoginFailed({required String reason}) =>
      _log('login_failed', {'reason': reason});

  static Future<void> logSignupCompleted() => _log('signup_completed', {});

  static Future<void> logRoleSelected({required String role}) =>
      _log('role_selected', {'role': role});

  static Future<void> logOnboardingCompleted({required String role}) =>
      _log('onboarding_completed', {'role': role});

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Fired when a push notification is received (foreground or background).
  static Future<void> logNotificationReceived(String type, {String? role}) =>
      _log('notification_received', {
        'notification_type': type,
        if (role != null) 'role': role,
      });

  /// Fired when the user opens a notification.
  ///
  /// [source]: 'push' (real push tap) | 'banner' (foreground in-app banner) |
  /// 'in_app_feed' (a historical row in the notification centre). Without this
  /// the feed's re-tappable rows inflate the push open rate, which is the metric
  /// the platform treats as canonical.
  static Future<void> logNotificationTapped(
    String type, {
    required String source,
    String? role,
  }) => _log('notification_tapped', {
    'notification_type': type,
    'source': source,
    if (role != null) 'role': role,
  });

  /// Fired when the in-app notification centre is opened.
  static Future<void> logNotificationCentreOpened() =>
      _log('notification_centre_opened', {});

  // ── Calendar & availability ───────────────────────────────────────────────

  /// [source]: 'calendar' | 'jobs_calendar' | 'quote_form'
  static Future<void> logDateMarkedUnavailable({
    required String role,
    required String source,
  }) => _log('date_marked_unavailable', {'role': role, 'source': source});

  static Future<void> logDateUnmarkedUnavailable({
    required String role,
    required String source,
  }) => _log('date_unmarked_unavailable', {'role': role, 'source': source});

  /// [toMode]: 'calendar' | 'list'
  static Future<void> logCalendarModeToggled({required String toMode}) =>
      _log('calendar_mode_toggled', {'to_mode': toMode});

  static Future<void> logDjFiltersToggled({required bool enabled}) =>
      _log('dj_filters_toggled', {'enabled': enabled ? 1 : 0});

  /// Mirror of [logDjFiltersToggled] for saxophonists, whose filter pill was
  /// previously unlogged.
  static Future<void> logMusicianFiltersToggled({required bool enabled}) =>
      _log('musician_filters_toggled', {'enabled': enabled ? 1 : 0});

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Every call site drops the returned future, so an uncaught throw here became
  /// an unhandled zone error: invisible, since the app has no crash reporting.
  /// Swallow it, but say so — silent failure is the thing this codebase keeps
  /// getting bitten by.
  static Future<void> _log(String name, Map<String, Object> params) async {
    if (!_enabled) return;
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params.isEmpty ? null : params,
      );
    } catch (e) {
      debugPrint('[AnalyticsService] logEvent "$name" failed: $e');
    }
  }
}
