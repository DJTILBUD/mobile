import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/app_config/data/datasources/app_config_remote_datasource.dart';
import 'package:dj_tilbud_app/features/app_config/data/repositories/app_config_repository.dart';
import 'package:dj_tilbud_app/features/app_config/domain/entities/app_config.dart';
import 'package:dj_tilbud_app/features/app_config/domain/version_compare.dart';

enum RequiredUpdateLevel {
  /// Current version is fine — no UI to show.
  none,

  /// Newer version exists but not mandatory. Show a one-time soft prompt.
  optional,

  /// Current version is below the minimum required. Block the app.
  forced,
}

class UpdateStatus {
  const UpdateStatus({
    required this.level,
    required this.currentVersion,
    this.config,
  });

  final RequiredUpdateLevel level;
  final String currentVersion;
  final AppConfig? config;

  String? get storeUrl {
    if (config == null) return null;
    return Platform.isIOS ? config!.iosAppStoreUrl : config!.androidPlayStoreUrl;
  }
}

extension on AppConfig {
  String? minVersionFor() =>
      Platform.isIOS ? iosMinVersion : androidMinVersion;
  String? latestVersionFor() =>
      Platform.isIOS ? iosLatestVersion : androidLatestVersion;
  String? storeUrlFor() =>
      Platform.isIOS ? iosAppStoreUrl : androidPlayStoreUrl;
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(AppConfigRemoteDatasource(supabase));
});

/// Resolves the gating decision once on app start. Recomputed when invalidated
/// (e.g. on app resume — see `app.dart`).
final updateStatusProvider = FutureProvider<UpdateStatus>((ref) async {
  final repo = ref.watch(appConfigRepositoryProvider);
  final pkg = await PackageInfo.fromPlatform();
  final current = pkg.version;
  final config = await repo.fetch();
  if (config == null) {
    return UpdateStatus(
        level: RequiredUpdateLevel.none, currentVersion: current);
  }

  final minVersion = config.minVersionFor();
  final latestVersion = config.latestVersionFor();
  final storeUrl = config.storeUrlFor();

  // A forced gate requires BOTH a min_version AND a store URL to send the
  // user to — without the URL the blocker would be a dead-end.
  if (minVersion != null &&
      storeUrl != null &&
      compareVersions(current, minVersion) < 0) {
    return UpdateStatus(
      level: RequiredUpdateLevel.forced,
      currentVersion: current,
      config: config,
    );
  }
  // Soft prompt requires a store URL too, otherwise there's nothing for
  // the user to do.
  if (latestVersion != null &&
      storeUrl != null &&
      compareVersions(current, latestVersion) < 0) {
    return UpdateStatus(
      level: RequiredUpdateLevel.optional,
      currentVersion: current,
      config: config,
    );
  }
  return UpdateStatus(
    level: RequiredUpdateLevel.none,
    currentVersion: current,
    config: config,
  );
});
