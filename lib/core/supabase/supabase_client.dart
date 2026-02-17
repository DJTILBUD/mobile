import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
