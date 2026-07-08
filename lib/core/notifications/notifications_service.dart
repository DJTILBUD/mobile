import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/chat/data/models/conversation_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/ext_job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/job_model.dart';
import 'package:dj_tilbud_app/features/jobs/data/models/service_offer_model.dart';

/// Handles FCM token registration and notification tap navigation.
/// Call [initialize] once after Firebase.initializeApp().
/// Call [setupNavigationHandlers] once the router is ready.
class NotificationsService {
  static final _messaging = FirebaseMessaging.instance;

  // ── Impersonation guard (super-owner debug login) ──
  //
  // While impersonating a production user, the app must NEVER touch the
  // `DeviceTokens` table. Registering this device under the impersonated user
  // would not only add our token — `_upsertToken`'s cleanup step then DELETES
  // every other token for that user, i.e. their REAL phone's token, silently
  // killing their push notifications. So we hard-skip all token writes.
  //
  // The flag is persisted so a relaunch mid-impersonation (which fires an
  // `initialSession` → `registerToken()`) still skips registration.
  static const _impersonationKey = 'djtilbud_impersonating';
  static bool _impersonating = false;

  static bool get isImpersonating => _impersonating;

  /// Load the persisted impersonation flag. Call once at startup BEFORE the
  /// auth listener is wired (so a recovered session doesn't register a token).
  static Future<void> loadImpersonationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _impersonating = prefs.getBool(_impersonationKey) ?? false;
  }

  /// Enter/leave impersonation. Set to `true` BEFORE establishing the
  /// impersonated session; set to `false` on logout.
  static Future<void> setImpersonating(bool value) async {
    _impersonating = value;
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_impersonationKey, true);
    } else {
      await prefs.remove(_impersonationKey);
    }
  }

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    // Suppress system banners while app is in foreground — the in-app
    // banner handles foreground notifications instead.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Save token and listen for refreshes.
    // getToken() throws on iOS Simulator (no APNS) — safe to ignore.
    try {
      final token = await _messaging.getToken();
      if (token != null) await _upsertToken(token);
      _messaging.onTokenRefresh.listen(_upsertToken);
    } catch (_) {
      // APNS not available (simulator or permissions denied) — skip silently.
    }
  }

  /// Call this after a successful login to register the token for the current user.
  static Future<void> registerToken() async {
    // Never register while impersonating — see the impersonation guard note.
    if (_impersonating) return;
    try {
      // On iOS, APNs token may not be ready immediately after app start.
      // If it isn't, return early — onTokenRefresh (wired in initialize())
      // will fire once the FCM token becomes available.
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) return;
      }
      final token = await _messaging.getToken();
      if (token != null) await _upsertToken(token);
    } catch (e) {
      debugPrint('[NotificationsService] registerToken error: $e');
    }
  }

  static Future<void> _upsertToken(String token) async {
    // Guard the onTokenRefresh path too — see the impersonation guard note.
    if (_impersonating) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('DeviceTokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, token');

    // Remove stale tokens for this user — iOS FCM tokens rotate on reinstall
    // or APNs refresh, which would otherwise accumulate duplicate rows.
    await supabase
        .from('DeviceTokens')
        .delete()
        .eq('user_id', userId)
        .neq('token', token);
  }

  /// Deletes the current device token on logout.
  static Future<void> removeToken() async {
    // While impersonating we never registered a token, and the row that exists
    // for this user is their REAL device — don't delete it. See guard note.
    if (_impersonating) return;
    final String? token;
    try {
      token = await _messaging.getToken();
    } catch (_) {
      return;
    }
    if (token == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('DeviceTokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);
  }

  /// Call this after the router is available (in App widget).
  static void setupNavigationHandlers(GoRouter router) {
    // App brought to foreground by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      await navigateTo(msg.data, router);
    });
  }

  /// Call this on app start to handle tap from terminated state.
  static Future<void> handleInitialMessage(GoRouter router) async {
    final msg = await _messaging.getInitialMessage();
    if (msg != null) await navigateTo(msg.data, router);
  }

  /// Extracts the primary reference ID from FCM data (job_id, offer_id, etc.).
  static String? extractReferenceId(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_job':
      case 'another_round':
      case 'ready_reminder':
      case 'extra_hours_reminder':
      case 'contact_customer_reminder':
      case 'send_invoice_reminder':
      case 'content_record_reminder':
      case 'content_upload_reminder':
      case 'content_accepted':
      case 'content_rejected':
        return data['job_id'] as String?;
      case 'new_ext_job':
      case 'ext_job_assigned':
        return data['ext_job_id'] as String?;
      case 'song_request':
        return (data['ext_job_id'] ?? data['job_id']) as String?;
      case 'quote_won':
      case 'quote_lost':
        return data['quote_id'] as String?;
      case 'offer_won':
      case 'offer_lost':
        return data['offer_id'] as String?;
      case 'chat_message':
      case 'chat_unused_reminder':
      case 'support_admin':
        return data['conversation_id'] as String?;
      case 'admin_message':
        return data['message_id'] as String?;
      default:
        return null;
    }
  }

  /// Audit-log type for the funnel, carrying campaign + stage.
  ///
  /// Campaign pushes (e.g. the out-of-region "second wave") keep the generic
  /// `data.type` (`new_ext_job` / `new_job`) so tap-routing is unchanged, but
  /// the sender logs them under `second_wave_ext_job_sent` / `second_wave_job_sent`.
  /// Without this, the received/tapped events would log as the plain type and the
  /// campaign's opens would be invisible (sent under one name, opens under another).
  /// Mirrors the sender's naming so sent/received/tapped line up by prefix.
  static String campaignAwareLogType(Map<String, dynamic> data, String event) {
    final type = data['type'] as String?;
    if (data['campaign'] == 'second_wave') {
      if (type == 'new_ext_job') return 'second_wave_ext_job_$event';
      if (type == 'new_job') return 'second_wave_job_$event';
    }
    return type ?? 'unknown';
  }

  /// Logs a foreground received event to NotificationLogs (requires auth session).
  static Future<void> logReceivedToSupabase(Map<String, dynamic> data) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('NotificationLogs').insert({
        'user_id': userId,
        'notification_type': campaignAwareLogType(data, 'received'),
        'role': data['role'],
        'reference_id': extractReferenceId(data),
        'event': 'received',
      });
    } catch (_) {}
  }

  /// Public entry-point used by the in-app notification banner on tap.
  static Future<void> navigateTo(
    Map<String, dynamic> data,
    GoRouter router,
  ) async {
    final type = data['type'] as String?;
    final role = data['role'] as String?;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    AnalyticsService.logNotificationTapped(type ?? 'unknown', role: role);
    unawaited(
      supabase
          .from('NotificationLogs')
          .insert({
            'user_id': userId,
            'notification_type': campaignAwareLogType(data, 'tapped'),
            'role': role,
            'reference_id': extractReferenceId(data),
            'event': 'tapped',
          })
          .catchError((_) {}),
    );

    // Helper: go to shell tab then push detail synchronously (no async gap between
    // them) so the shell stays underneath and the back button works — exactly
    // the same as navigating from within the app.
    try {
      switch (type) {
        case 'new_job':
        case 'another_round':
          final jobId = _parseInt(data['job_id']);
          final homeTab =
              role == 'musician' ? '/instrumentalist/home' : '/dj/home';
          if (jobId != null) {
            final json =
                await supabase.from('Jobs').select().eq('id', jobId).single();
            final job = JobModel.fromJson(json).toEntity();
            router.go(homeTab);
            if (role == 'musician') {
              router.pushNamed(AppRoutes.instrumentalistOfferForm, extra: job);
            } else {
              router.pushNamed(AppRoutes.djQuoteForm, extra: job);
            }
          } else {
            router.go(homeTab);
          }

        case 'quote_won':
        case 'quote_lost':
          final quoteId = _parseInt(data['quote_id']);
          if (quoteId != null) {
            final json =
                await supabase
                    .from('Quotes')
                    .select('*, job:Jobs(*)')
                    .eq('id', quoteId)
                    .single();
            final quote = DjQuoteModel.fromJson(json).toEntity();
            router.go('/dj/home');
            router.pushNamed(AppRoutes.quoteDetail, extra: quote);
          } else {
            router.go('/dj/home');
          }

        case 'offer_won':
        case 'offer_lost':
          final offerId = _parseInt(data['offer_id']);
          if (offerId != null) {
            final json =
                await supabase
                    .from('ServiceOffers')
                    .select(
                      '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)',
                    )
                    .eq('id', offerId)
                    .single();
            final offer = ServiceOfferModel.fromJson(json).toEntity();
            router.go('/instrumentalist/home');
            router.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
          } else {
            router.go('/instrumentalist/home');
          }

        // The "unused chat" reminder and emoji-reaction pushes deep-link to the
        // conversation, same as a new chat message.
        case 'chat_message':
        case 'chat_reaction':
        case 'chat_unused_reminder':
          final convId = _parseInt(data['conversation_id']);
          final chatTab =
              role == 'musician' ? '/instrumentalist/chat' : '/dj/chat';
          if (convId != null) {
            final json =
                await supabase
                    .from('Conversations')
                    .select('''
              *,
              job:Jobs!Conversations_job_id_fkey(id, event_type, date),
              ext_job:ExtJobs!Conversations_ext_job_id_fkey(id, event_type, date, assigned_dj_name),
              dj:DjInfos!Conversations_dj_id_fkey(id, full_name),
              musician:Musicians!Conversations_musician_id_fkey(id, full_name, instrument)
            ''')
                    .eq('id', convId)
                    .single();
            final conversation = ConversationModel.fromJson(
              json,
            ).toEntity(userId);
            router.go(chatTab);
            router.pushNamed(AppRoutes.conversationDetail, extra: conversation);
          } else {
            router.go(chatTab);
          }

        case 'support_admin':
          // An admin support reply: open the chat screen (the admin Support tab lives there). Uses
          // the admin's own role shell. Deep-linking to the exact thread is a follow-up (would need
          // the thread entity, not just the conversation id).
          router.go(
            RoleCache.role == MusicianRole.instrumentalist
                ? '/instrumentalist/chat'
                : '/dj/chat',
          );

        case 'new_ext_job':
          // A NEW (biddable) ext job → put the musician in the OFFER stage, exactly like the browse
          // feed: map the ExtJob to a Job (toJobEntity sets isExtJob + extJobId) and open the offer
          // form. Do NOT open ExtJobDetailScreen — that is the WON/assigned fulfillment view (customer
          // contact, "kontakt kunden"), which is both wrong for an un-won job and leaks the customer's
          // details. The won view is only for ext_job_assigned (below).
          final extJobId = _parseInt(data['ext_job_id']);
          if (extJobId != null) {
            final json =
                await supabase
                    .from('ExtJobs')
                    .select()
                    .eq('id', extJobId)
                    .single();
            final job = ExtJobModel.fromJson(json).toJobEntity();
            router.go('/instrumentalist/home');
            router.pushNamed(AppRoutes.instrumentalistOfferForm, extra: job);
          } else {
            router.go('/instrumentalist/home');
          }

        case 'ext_job_assigned':
          final extJobId = _parseInt(data['ext_job_id']);
          final featuredTab =
              role == 'musician' ? '/instrumentalist/home' : '/dj/featured';
          if (extJobId != null) {
            final json =
                await supabase
                    .from('ExtJobs')
                    .select()
                    .eq('id', extJobId)
                    .single();
            final extJob = ExtJobModel.fromJson(json).toEntity();
            router.go(featuredTab);
            router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
          } else {
            router.go(featuredTab);
          }

        case 'song_request':
          // Navigate DJ to the job/ext-job detail so they can tap into song requests.
          final extJobId = _parseInt(data['ext_job_id']);
          final songJobId = _parseInt(data['job_id']);
          if (extJobId != null) {
            final json =
                await supabase
                    .from('ExtJobs')
                    .select()
                    .eq('id', extJobId)
                    .single();
            final extJob = ExtJobModel.fromJson(json).toEntity();
            router.go('/dj/featured');
            router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
          } else if (songJobId != null) {
            final quoteJson =
                await supabase
                    .from('Quotes')
                    .select('*, job:Jobs(*)')
                    .eq('job_id', songJobId)
                    .eq('dj_id', userId)
                    .maybeSingle();
            if (quoteJson != null) {
              final quote = DjQuoteModel.fromJson(quoteJson).toEntity();
              router.go('/dj/home');
              router.pushNamed(AppRoutes.quoteDetail, extra: quote);
            } else {
              router.go('/dj/home');
            }
          } else {
            router.go('/dj/home');
          }

        case 'custom_notification':
          // Admin-sent custom notification — no deep link, just dismiss.
          break;

        case 'admin_message':
          final isMusician = role == 'musician';
          final profileTab =
              isMusician ? '/instrumentalist/profile' : '/dj/profile';
          router.go(profileTab);
          // The adminMessages route requires a MusicianRole enum as `extra`;
          // passing the raw `role` String fell through to the "Mangler data"
          // screen (the bug that broke tapping this notification).
          router.pushNamed(
            AppRoutes.adminMessages,
            extra: isMusician ? MusicianRole.instrumentalist : MusicianRole.dj,
          );
          break;

        // Content accepted/rejected (DJ-only) → open the content library.
        case 'content_accepted':
        case 'content_rejected':
          router.go('/dj/profile');
          router.pushNamed(AppRoutes.myContent);
          break;

        // Content reminders are DJ-only and deep-link to the same job views as
        // the ready reminder. The day-after "log extra hours" reminder routes
        // the same way (DJ → quote/ext-job detail, musician → offer detail),
        // landing the user on the screen that holds the extra-hours control.
        // Process nudges (contact the customer / send the invoice) deep-link into
        // the job exactly like the ready reminder — DJ → quote/ext-job detail,
        // musician → offer detail.
        case 'content_record_reminder':
        case 'content_upload_reminder':
        case 'extra_hours_reminder':
        case 'contact_customer_reminder':
        case 'send_invoice_reminder':
        case 'ready_reminder':
          final jobId = _parseInt(data['job_id']);
          final isExtJob = data['is_ext_job'] == 'true';
          if (jobId != null) {
            if (role == 'dj') {
              if (isExtJob) {
                final json =
                    await supabase
                        .from('ExtJobs')
                        .select()
                        .eq('id', jobId)
                        .single();
                final extJob = ExtJobModel.fromJson(json).toEntity();
                router.go('/dj/featured');
                router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
              } else {
                final quoteJson =
                    await supabase
                        .from('Quotes')
                        .select('*, job:Jobs(*)')
                        .eq('job_id', jobId)
                        .eq('dj_id', userId)
                        .maybeSingle();
                if (quoteJson != null) {
                  final quote = DjQuoteModel.fromJson(quoteJson).toEntity();
                  router.go('/dj/home');
                  router.pushNamed(AppRoutes.quoteDetail, extra: quote);
                } else {
                  router.go('/dj/home');
                }
              }
            } else {
              final column = isExtJob ? 'ext_job_id' : 'job_id';
              final offerJson =
                  await supabase
                      .from('ServiceOffers')
                      .select(
                        '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)',
                      )
                      .eq(column, jobId)
                      .eq('musician_id', userId)
                      .maybeSingle();
              if (offerJson != null) {
                final offer = ServiceOfferModel.fromJson(offerJson).toEntity();
                router.go('/instrumentalist/home');
                router.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
              } else {
                router.go('/instrumentalist/home');
              }
            }
          } else {
            router.go(
              role == 'musician' ? '/instrumentalist/home' : '/dj/home',
            );
          }
      }
    } catch (e) {
      debugPrint('[NotificationsService] navigation error for type=$type: $e');
      if (role == 'musician') {
        router.go('/instrumentalist/home');
      } else {
        router.go('/dj/home');
      }
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
