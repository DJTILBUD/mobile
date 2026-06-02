import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('DeviceTokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id, token',
    );

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
        return data['conversation_id'] as String?;
      case 'admin_message':
        return data['message_id'] as String?;
      default:
        return null;
    }
  }

  /// Logs a foreground received event to NotificationLogs (requires auth session).
  static Future<void> logReceivedToSupabase(Map<String, dynamic> data) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('NotificationLogs').insert({
        'user_id': userId,
        'notification_type': data['type'] ?? 'unknown',
        'role': data['role'],
        'reference_id': extractReferenceId(data),
        'event': 'received',
      });
    } catch (_) {}
  }

  /// Public entry-point used by the in-app notification banner on tap.
  static Future<void> navigateTo(
      Map<String, dynamic> data, GoRouter router) async {
    final type = data['type'] as String?;
    final role = data['role'] as String?;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    AnalyticsService.logNotificationTapped(type ?? 'unknown', role: role);
    unawaited(supabase.from('NotificationLogs').insert({
      'user_id': userId,
      'notification_type': type ?? 'unknown',
      'role': role,
      'reference_id': extractReferenceId(data),
      'event': 'tapped',
    }).catchError((_) {}));

    // Helper: go to shell tab then push detail synchronously (no async gap between
    // them) so the shell stays underneath and the back button works — exactly
    // the same as navigating from within the app.
    try {
      switch (type) {
        case 'new_job':
        case 'another_round':
          final jobId = _parseInt(data['job_id']);
          final homeTab = role == 'musician' ? '/instrumentalist/home' : '/dj/home';
          if (jobId != null) {
            final json = await supabase
                .from('Jobs')
                .select()
                .eq('id', jobId)
                .single();
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
            final json = await supabase
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
            final json = await supabase
                .from('ServiceOffers')
                .select(
                    '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)')
                .eq('id', offerId)
                .single();
            final offer = ServiceOfferModel.fromJson(json).toEntity();
            router.go('/instrumentalist/home');
            router.pushNamed(AppRoutes.serviceOfferDetail, extra: offer);
          } else {
            router.go('/instrumentalist/home');
          }

        case 'chat_message':
          final convId = _parseInt(data['conversation_id']);
          final chatTab = role == 'musician' ? '/instrumentalist/chat' : '/dj/chat';
          if (convId != null) {
            final json = await supabase.from('Conversations').select('''
              *,
              job:Jobs!Conversations_job_id_fkey(id, event_type, date),
              ext_job:ExtJobs!Conversations_ext_job_id_fkey(id, event_type, date, assigned_dj_name),
              dj:DjInfos!Conversations_dj_id_fkey(id, full_name),
              musician:Musicians!Conversations_musician_id_fkey(id, full_name, instrument)
            ''').eq('id', convId).single();
            final conversation = ConversationModel.fromJson(json).toEntity(userId);
            router.go(chatTab);
            router.pushNamed(AppRoutes.conversationDetail, extra: conversation);
          } else {
            router.go(chatTab);
          }

        case 'new_ext_job':
          final extJobId = _parseInt(data['ext_job_id']);
          if (extJobId != null) {
            final json = await supabase
                .from('ExtJobs')
                .select()
                .eq('id', extJobId)
                .single();
            final extJob = ExtJobModel.fromJson(json).toEntity();
            router.go('/instrumentalist/home');
            router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
          } else {
            router.go('/instrumentalist/home');
          }

        case 'ext_job_assigned':
          final extJobId = _parseInt(data['ext_job_id']);
          final featuredTab = role == 'musician' ? '/instrumentalist/home' : '/dj/featured';
          if (extJobId != null) {
            final json = await supabase
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
            final json = await supabase
                .from('ExtJobs')
                .select()
                .eq('id', extJobId)
                .single();
            final extJob = ExtJobModel.fromJson(json).toEntity();
            router.go('/dj/featured');
            router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
          } else if (songJobId != null) {
            final quoteJson = await supabase
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
          final profileTab =
              role == 'musician' ? '/instrumentalist/profile' : '/dj/profile';
          router.go(profileTab);
          router.pushNamed(AppRoutes.adminMessages, extra: role);
          break;

        // Content accepted/rejected (DJ-only) → open the content library.
        case 'content_accepted':
        case 'content_rejected':
          router.go('/dj/profile');
          router.pushNamed(AppRoutes.myContent);
          break;

        // Content reminders are DJ-only and deep-link to the same job views as
        // the ready reminder.
        case 'content_record_reminder':
        case 'content_upload_reminder':
        case 'ready_reminder':
          final jobId = _parseInt(data['job_id']);
          final isExtJob = data['is_ext_job'] == 'true';
          if (jobId != null) {
            if (role == 'dj') {
              if (isExtJob) {
                final json = await supabase
                    .from('ExtJobs')
                    .select()
                    .eq('id', jobId)
                    .single();
                final extJob = ExtJobModel.fromJson(json).toEntity();
                router.go('/dj/featured');
                router.pushNamed(AppRoutes.extJobDetail, extra: extJob);
              } else {
                final quoteJson = await supabase
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
              final offerJson = await supabase
                  .from('ServiceOffers')
                  .select(
                      '*, job:Jobs!ServiceOffers_job_id_fkey(*), ext_job:ExtJobs!ServiceOffers_ext_job_id_fkey(*)')
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
                role == 'musician' ? '/instrumentalist/home' : '/dj/home');
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
