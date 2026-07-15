import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/widgets/restart_widget.dart';
import 'package:dj_tilbud_app/firebase_options.dart';

// Top-level handler required by Firebase for background/terminated messages.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.logNotificationReceived(
    // campaignAwareLogType, not the raw type: a "second wave" campaign is SENT
    // as new_job/new_ext_job but must be LOGGED under second_wave_*. Passing the
    // raw type here attributed campaign opens to the plain type, so the campaign
    // funnel read "sent N, opened 0" in GA4 — the same trap the Supabase path
    // already avoids.
    NotificationsService.campaignAwareLogType(message.data, 'received'),
    role: message.data['role'] as String?,
  );
  await _logBackgroundReceivedToSupabase(message.data);
}

Future<void> _logBackgroundReceivedToSupabase(Map<String, dynamic> data) async {
  try {
    // Load env without SharedPreferences — not available in background isolate.
    final env =
        kReleaseMode
            ? 'prod'
            : const String.fromEnvironment('ENV', defaultValue: 'local');
    await dotenv.load(fileName: '.env.$env');

    final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
    final logSecret = dotenv.get('NOTIFY_LOG_SECRET', fallback: '');
    if (supabaseUrl.isEmpty || logSecret.isEmpty) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await http.post(
      Uri.parse('$supabaseUrl/functions/v1/notify-log-received'),
      headers: {'Content-Type': 'application/json', 'x-log-secret': logSecret},
      body: jsonEncode({
        'token': token,
        'notification_type': NotificationsService.campaignAwareLogType(
          data,
          'received',
        ),
        'role': data['role'],
        'reference_id': NotificationsService.extractReferenceId(data),
      }),
    );
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await RoleCache.load();
  // Load the impersonation flag before the auth listener subscribes, so a
  // recovered impersonated session never registers a device token.
  await NotificationsService.loadImpersonationFlag();
  await initSupabase();
  await initializeDateFormatting('da_DK');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // One Firebase project serves every env, so collection has to be gated here:
  // otherwise a `flutter run` against local Supabase writes real events to the
  // production GA4 property. Impersonation is included for the same reason the
  // DeviceTokens writes guard on it — a support session would otherwise report a
  // real user's behaviour from the developer's device. The flag is loaded above,
  // before this runs.
  await AnalyticsService.setEnabled(
    EnvConfig.isProd && !NotificationsService.isImpersonating,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await NotificationsService.initialize();
  // Force early subscription so background recoverSession() events
  // are caught before the router is built.
  authNotifierEarlyInit();
  // Resolve onboarding status before GoRouter is created so the initial
  // redirect is correct without relying on async re-evaluation.
  await initOnboardingStatus();
  runApp(const RestartWidget(child: ProviderScope(child: App())));
}
