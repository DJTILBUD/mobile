import 'package:dj_tilbud_app/features/app_config/domain/entities/app_config.dart';

class AppConfigModel {
  const AppConfigModel({
    this.iosMinVersion,
    this.androidMinVersion,
    this.iosLatestVersion,
    this.androidLatestVersion,
    this.iosAppStoreUrl,
    this.androidPlayStoreUrl,
    this.forceUpdateTitle,
    this.forceUpdateMessage,
    this.optionalUpdateTitle,
    this.optionalUpdateMessage,
  });

  final String? iosMinVersion;
  final String? androidMinVersion;
  final String? iosLatestVersion;
  final String? androidLatestVersion;
  final String? iosAppStoreUrl;
  final String? androidPlayStoreUrl;
  final String? forceUpdateTitle;
  final String? forceUpdateMessage;
  final String? optionalUpdateTitle;
  final String? optionalUpdateMessage;

  static String? _nonEmpty(dynamic v) {
    if (v is! String) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      iosMinVersion: _nonEmpty(json['ios_min_version']),
      androidMinVersion: _nonEmpty(json['android_min_version']),
      iosLatestVersion: _nonEmpty(json['ios_latest_version']),
      androidLatestVersion: _nonEmpty(json['android_latest_version']),
      iosAppStoreUrl: _nonEmpty(json['ios_app_store_url']),
      androidPlayStoreUrl: _nonEmpty(json['android_play_store_url']),
      forceUpdateTitle: _nonEmpty(json['force_update_title']),
      forceUpdateMessage: _nonEmpty(json['force_update_message']),
      optionalUpdateTitle: _nonEmpty(json['optional_update_title']),
      optionalUpdateMessage: _nonEmpty(json['optional_update_message']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ios_min_version': iosMinVersion,
        'android_min_version': androidMinVersion,
        'ios_latest_version': iosLatestVersion,
        'android_latest_version': androidLatestVersion,
        'ios_app_store_url': iosAppStoreUrl,
        'android_play_store_url': androidPlayStoreUrl,
        'force_update_title': forceUpdateTitle,
        'force_update_message': forceUpdateMessage,
        'optional_update_title': optionalUpdateTitle,
        'optional_update_message': optionalUpdateMessage,
      };

  AppConfig toEntity() => AppConfig(
        iosMinVersion: iosMinVersion,
        androidMinVersion: androidMinVersion,
        iosLatestVersion: iosLatestVersion,
        androidLatestVersion: androidLatestVersion,
        iosAppStoreUrl: iosAppStoreUrl,
        androidPlayStoreUrl: androidPlayStoreUrl,
        forceUpdateTitle: forceUpdateTitle,
        forceUpdateMessage: forceUpdateMessage,
        optionalUpdateTitle: optionalUpdateTitle,
        optionalUpdateMessage: optionalUpdateMessage,
      );
}
