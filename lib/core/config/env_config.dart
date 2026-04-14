import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime environment configuration.
///
/// In debug builds: reads saved preference from SharedPreferences,
/// falls back to dart-define ENV, falls back to 'local'.
/// In release builds: always uses 'dev'.
class EnvConfig {
  const EnvConfig._();

  static const _prefKey = 'djtilbud_env';

  /// Call once before accessing any values (at startup and after switching).
  static Future<void> load() async {
    final env = await _resolveEnv();
    await dotenv.load(fileName: '.env.$env');
  }

  static Future<String> _resolveEnv() async {
    if (!kDebugMode) return 'dev';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ??
        const String.fromEnvironment('ENV', defaultValue: 'local');
  }

  /// Save a new env preference. Call [load()] again after this to apply.
  static Future<void> saveEnvPreference(String env) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, env);
  }

  static String get env => dotenv.get('ENV', fallback: 'local');
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');

  static bool get isLocal => env == 'local';
  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
