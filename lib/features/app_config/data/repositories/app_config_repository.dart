import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dj_tilbud_app/features/app_config/data/datasources/app_config_remote_datasource.dart';
import 'package:dj_tilbud_app/features/app_config/data/models/app_config_model.dart';
import 'package:dj_tilbud_app/features/app_config/domain/entities/app_config.dart';

class AppConfigRepository {
  AppConfigRepository(this._datasource);

  final AppConfigRemoteDatasource _datasource;

  static const _cacheKey = 'djtilbud_app_config_cache_v1';

  /// Fetch the live AppConfig. On any network/DB failure, fall back to the
  /// last cached value (so an offline first-launch can't soft-brick the app
  /// behind a stuck loading state). Returns null only when nothing is
  /// cached AND the network failed — caller should treat that as "no
  /// gating" rather than blocking the user out without info.
  Future<AppConfig?> fetch() async {
    try {
      final json = await _datasource.fetch();
      if (json != null) {
        await _writeCache(json);
        return AppConfigModel.fromJson(json).toEntity();
      }
    } catch (_) {
      // Swallow — fall through to cache.
    }
    return _readCache();
  }

  Future<void> _writeCache(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(json));
  }

  Future<AppConfig?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppConfigModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }
}
