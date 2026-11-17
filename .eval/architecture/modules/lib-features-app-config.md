# Module: lib/features/app_config [AI]

Manages remote application configuration from Supabase and local cache to enforce minimum version requirements (force-update) and notify musicians of optional app updates.

## Key files
- `lib/features/app_config/data/datasources/app_config_remote_datasource.dart`: Fetches the singleton application configuration row (id = 1) from the Supabase 'AppConfig' table.
- `lib/features/app_config/data/models/app_config_model.dart`: Data model for JSON serialization/deserialization and mapping AppConfig table fields to the domain entity.
- `lib/features/app_config/data/repositories/app_config_repository.dart`: Coordinates fetching live config and caching to SharedPreferences for offline fallback support.
- `lib/features/app_config/domain/entities/app_config.dart`: Domain entity representing platform min/latest versions, store URLs, and update prompt copy.
- `lib/features/app_config/domain/version_compare.dart`: Utility function to compare dotted-decimal semantic version strings while stripping build/pre-release metadata.
- `lib/features/app_config/presentation/providers/app_config_provider.dart`: Riverpod providers evaluating package version against remote requirements to determine RequiredUpdateLevel.
- `lib/features/app_config/presentation/screens/force_update_screen.dart`: Full-screen, non-dismissable UI blocking outdated app versions and linking to the relevant app store.
- `lib/features/app_config/presentation/widgets/update_gate.dart`: Top-level lifecycle-aware widget wrapper that intercepts execution to present force update blockers or soft update dialogs.

## Public interface
- class AppConfig
- class AppConfigModel
- class AppConfigRemoteDatasource
- class AppConfigRepository
- class ForceUpdateScreen
- class UpdateGate
- class UpdateStatus
- enum RequiredUpdateLevel
- int compareVersions(String a, String b)
- final appConfigRepositoryProvider
- final updateStatusProvider

## Dependencies
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:lucide_icons/lucide_icons.dart
- package:package_info_plus/package_info_plus.dart
- package:shared_preferences/shared_preferences.dart
- package:supabase_flutter/supabase_flutter.dart
- package:url_launcher/url_launcher.dart
- dj_tilbud_app/app.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/supabase/supabase_client.dart

## AI touchpoints [AI]
- `lib/features/app_config/presentation/providers/app_config_provider.dart`
- `lib/features/app_config/presentation/widgets/update_gate.dart`

## Open questions
- _none_
