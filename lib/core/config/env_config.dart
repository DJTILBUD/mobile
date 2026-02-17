/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define-from-file=.env.<environment>`.
/// Default build uses `.env.local`.
class EnvConfig {
  const EnvConfig._();

  static const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isLocal => env == 'local';
  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
