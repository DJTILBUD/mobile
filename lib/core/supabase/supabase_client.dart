import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';

/// On Android emulator, 127.0.0.1 refers to the emulator itself.
/// The host machine is reachable at 10.0.2.2.
String get _resolvedSupabaseUrl {
  final url = EnvConfig.supabaseUrl;
  if (EnvConfig.isLocal && Platform.isAndroid) {
    return url.replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return url;
}

Future<void> initSupabase() async {
  final url = _resolvedSupabaseUrl;
  // ignore: avoid_print
  print('Initializing Supabase: url=$url, env=${EnvConfig.env}');
  await Supabase.initialize(
    url: url,
    anonKey: EnvConfig.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
