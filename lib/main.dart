import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/widgets/restart_widget.dart';
import 'package:dj_tilbud_app/firebase_options.dart';

// Top-level handler required by Firebase for background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await RoleCache.load();
  await initSupabase();
  await initializeDateFormatting('da_DK');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await NotificationsService.initialize();
  runApp(const RestartWidget(child: ProviderScope(child: App())));
}
