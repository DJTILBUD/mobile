import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabase;
});
