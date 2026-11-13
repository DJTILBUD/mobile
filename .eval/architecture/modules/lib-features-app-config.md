# Module: lib/features/app_config [AI]

Manages remote app configuration and client update gating for the mobile application. Checks the running version against minimum and latest version requirements from Supabase and SharedPreferences cache, presenting either a blocking force-update screen or an optional soft-update dialog.

## Key files
- `lib/features/app_config/domain/entities/app_config.dart`: Defines the AppConfig entity modeling platform-specific minimum/latest versions, store URLs, and update messages.
- `lib/features/app_config/domain/version_compare.dart`: Implements dotted-decimal semantic version comparison, stripping pre-release or build suffixes.
- `lib/features/app_config/data/datasources/app_config_remote_datasource.dart`: Fetches the singleton AppConfig record from the Supabase AppConfig table.
- `lib/features/app_config/data/models/app_config_model.dart`: Data serialization model converting Supabase JSON to AppConfig domain entity.
- `lib/features/app_config/data/repositories/app_config_repository.dart`: Coordinates fetching live configuration from the remote datasource and caching to SharedPreferences for offline resilience.
- `lib/features/app_config/presentation/providers/app_config_provider.dart`: Riverpod providers determining the RequiredUpdateLevel (none, optional, forced) by evaluating current app version against config.
- `lib/features/app_config/presentation/screens/force_update_screen.dart`: Non-dismissable full-screen view displayed when a forced update is required, directing users to the respective app store.
- `lib/features/app_config/presentation/widgets/update_gate.dart`: Top-level lifecycle-aware wrapper widget managing soft update dialogs and full-screen blocking update screens.

## Public interface
- AppConfig
- compareVersions
- AppConfigRemoteDatasource.fetch
- AppConfigRepository.fetch
- RequiredUpdateLevel
- UpdateStatus
- appConfigRepositoryProvider
- updateStatusProvider
- ForceUpdateScreen
- UpdateGate

## Dependencies
- package:flutter/material.dart
- package:flutter/services.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:package_info_plus/package_info_plus.dart
- package:shared_preferences/shared_preferences.dart
- package:supabase_flutter/supabase_flutter.dart
- package:url_launcher/url_launcher.dart
- package:lucide_icons/lucide_icons.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/app.dart

## AI touchpoints [AI]
- `lib/features/app_config/presentation/providers/app_config_provider.dart`
- `lib/features/app_config/presentation/widgets/update_gate.dart`

## Open questions
- _none_
