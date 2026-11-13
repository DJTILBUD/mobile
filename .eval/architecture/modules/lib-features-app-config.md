# Module: lib/features/app_config [AI]

Manages remote application configuration and version gating for the DJTILBUD mobile app, determining whether to enforce a mandatory update, show an optional update prompt, or allow normal app access based on current platform versions.

## Key files
- `lib/features/app_config/domain/entities/app_config.dart`: Defines the AppConfig entity representing version requirements, store URLs, and messaging for iOS and Android.
- `lib/features/app_config/domain/version_compare.dart`: Utility function for comparing dotted decimal version strings.
- `lib/features/app_config/data/models/app_config_model.dart`: Data model for serialization and deserialization of AppConfig rows from Supabase.
- `lib/features/app_config/data/datasources/app_config_remote_datasource.dart`: Remote datasource fetching the singleton AppConfig record from Supabase.
- `lib/features/app_config/data/repositories/app_config_repository.dart`: Repository handling AppConfig retrieval with local cache fallback using SharedPreferences.
- `lib/features/app_config/presentation/providers/app_config_provider.dart`: Riverpod providers computing the required update level (forced, optional, or none) against the running app version.
- `lib/features/app_config/presentation/screens/force_update_screen.dart`: Non-dismissible screen displayed when the installed app version is below the mandatory minimum version.
- `lib/features/app_config/presentation/widgets/update_gate.dart`: Top-level wrapper widget monitoring update status, displaying dialog prompts or blocking the UI when updates are required.

## Public interface
- AppConfig
- AppConfigModel
- AppConfigRemoteDatasource
- AppConfigRepository
- int compareVersions(String a, String b)
- enum RequiredUpdateLevel
- UpdateStatus
- appConfigRepositoryProvider
- updateStatusProvider
- ForceUpdateScreen
- UpdateGate

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:package_info_plus/package_info_plus.dart
- package:shared_preferences/shared_preferences.dart
- package:supabase_flutter/supabase_flutter.dart
- package:url_launcher/url_launcher.dart
- package:lucide_icons/lucide_icons.dart
- dj_tilbud_app/app.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/supabase/supabase_client.dart

## AI touchpoints [AI]
- `lib/features/app_config/presentation/providers/app_config_provider.dart`
- `lib/features/app_config/presentation/widgets/update_gate.dart`

## Open questions
- _none_
