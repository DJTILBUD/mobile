# Module: lib/features/app_config [AI]

Implements mobile app version-gating by fetching a singleton AppConfig row from Supabase and deciding whether to block the app with a forced update screen, show a one-time optional update prompt, or let the app run normally. Not part of the job feed, quoting, or profile features directly — it's an operational/app-health mechanism that wraps the whole app above routing.

## Key files
- `lib/features/app_config/data/datasources/app_config_remote_datasource.dart`: Fetches the singleton AppConfig row (id=1) from the Supabase 'AppConfig' table
- `lib/features/app_config/data/models/app_config_model.dart`: Parses raw Supabase JSON into AppConfigModel and maps it to the domain AppConfig entity
- `lib/features/app_config/data/repositories/app_config_repository.dart`: Fetches live config with fallback to a locally cached copy (SharedPreferences) if network/DB fails
- `lib/features/app_config/domain/entities/app_config.dart`: Domain entity describing the version-gating fields (min/latest versions, store URLs, update messages) populated by admins
- `lib/features/app_config/domain/version_compare.dart`: Utility to compare dotted-decimal version strings for gating decisions
- `lib/features/app_config/presentation/providers/app_config_provider.dart`: Riverpod providers resolving platform-specific gating decision (none/optional/forced) by comparing current app version against AppConfig
- `lib/features/app_config/presentation/screens/force_update_screen.dart`: Full-screen non-dismissable blocker UI shown when the app version is below the required minimum
- `lib/features/app_config/presentation/widgets/update_gate.dart`: Top-level widget wrapping the app above routing; shows ForceUpdateScreen or a soft update dialog, or passes through to child

## Public interface
- AppConfigRemoteDatasource.fetch
- AppConfigModel.fromJson
- AppConfigModel.toEntity
- AppConfigRepository.fetch
- AppConfig
- compareVersions
- RequiredUpdateLevel
- UpdateStatus
- appConfigRepositoryProvider
- updateStatusProvider
- ForceUpdateScreen
- UpdateGate

## Dependencies
- lib/core/supabase/supabase_client.dart
- lib/core/design_system/components.dart
- lib/app.dart

## AI touchpoints [AI]
- `lib/features/app_config/presentation/providers/app_config_provider.dart`
- `lib/features/app_config/presentation/widgets/update_gate.dart`

## Open questions
- Is the AppConfig table/admin tool populated manually, and is there any other consumer of this config beyond version gating (e.g. feature flags)?
- Why does a null config (fetch failure with no cache) resolve to 'none' gating rather than surfacing an error state to the user?
