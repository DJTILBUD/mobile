import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: App()));
}
