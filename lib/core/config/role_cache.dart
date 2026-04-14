import 'package:shared_preferences/shared_preferences.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';

/// Caches the user's role locally so the router can restore the session
/// without an async DB call on startup.
class RoleCache {
  static const _key = 'djtilbud_user_role';
  static MusicianRole? _role;

  static MusicianRole? get role => _role;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    _role = value == 'dj'
        ? MusicianRole.dj
        : value == 'instrumentalist'
            ? MusicianRole.instrumentalist
            : null;
  }

  static Future<void> save(MusicianRole role) async {
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role.name);
  }

  static Future<void> clear() async {
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
