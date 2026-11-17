# Module: lib/core [AI]

(part 1 of 3) Provides foundational app-wide infrastructure, including runtime environment configuration, user role caching, Firebase analytics tracking, and a unified design system of reusable UI components. (part 2 of 3) Provides the foundational infrastructure, design tokens, theming, cross-cutting error handling, push notification management, Supabase client initialization, and global navigation shell for the musician mobile application. (part 3 of 3) Provides core shared utilities, formatting helpers, and reusable UI widgets across the DJTILBUD musician-facing mobile app, including fee and pricing calculations, DJ-facing budget adjustments, gear serialization, and development environment switching.

_This module does not fit in one model call, so it was read in 3 parts and their summaries were combined without a further model call._

## Key files
- `lib/core/analytics/analytics_service.dart`: Wraps Firebase Analytics for user identity management, offer funnels, submit attempt/failure tracking, and view logging.
- `lib/core/config/env_config.dart`: Manages runtime environment resolution (local, dev, prod), dotenv configuration, and environment URL getters.
- `lib/core/config/role_cache.dart`: Persists and retrieves the user's MusicianRole locally via SharedPreferences for session restoration.
- `lib/core/design_system/components.dart`: Barrel export for all design system widgets and tokens.
- `lib/core/design_system/ds_button.dart`: Implements design-system buttons (DSButton) and icon buttons (DSIconButton).
- `lib/core/design_system/ds_dialog.dart`: Provides dialog containers and helper functions (showDSDialog, showDSConfirm).
- `lib/core/design_system/ds_input.dart`: Implements text input fields with custom validation, styling, and keyboard scroll handling.
- `lib/core/design_system/ds_toast.dart`: Presents floating snackbars/toasts for notifications.
- `lib/core/design_system/tokens.dart`: Defines role-based design tokens including light and dark palette colors, typography styles, shadows, border radii, and motion curves.
- `lib/core/design_system/showcase_screen.dart`: Interactive showcase screen for previewing design system foundations, components, and color themes.
- `lib/core/error/app_exception.dart`: Defines the sealed hierarchy of domain and API exceptions, including billing, authentication, and AI agent quota exceptions.
- `lib/core/error/error_messages.dart`: Maps thrown domain exceptions into user-safe Danish error strings.
- `lib/core/navigation/main_shell.dart`: Primary bottom navigation shell switching destinations based on musician role (DJ vs saxophonist/instrumentalist) and binding badge count providers.
- `lib/core/notifications/notifications_service.dart`: Manages Firebase Cloud Messaging (FCM) permissions, token synchronization with the DeviceTokens database table, impersonation safeguards, and push tap routing.
- `lib/core/notifications/in_app_notification_banner.dart`: Foreground animated notification banner component for incoming FCM messages.
- `lib/core/notifications/in_app_notification_provider.dart`: Riverpod providers tracking active foreground notifications, conversation view state, and UI dismiss bars.
- `lib/core/notifications/app_badge.dart`: Client-side OS application icon badge helper using AppBadgePlus.
- `lib/core/router/app_routes.dart`: Central route name constants for application navigation.
- `lib/core/supabase/supabase_client.dart`: Initializes and provides the global SupabaseClient instance with Android emulator host resolution.
- `lib/core/supabase/supabase_provider.dart`: Riverpod provider exposing the SupabaseClient instance.
- `lib/core/theme/app_theme.dart`: Configures light and dark Material 3 ThemeData with typography and branded color definitions.
- `lib/core/theme/theme_provider.dart`: Riverpod StateNotifier persisting and toggling light and dark theme mode via SharedPreferences.
- `lib/core/utils/budget_utils.dart`: Calculates platform fees, saxophonist deductions, WKNDS delivery deductions, and tier-adjusted DJ budget labels.
- `lib/core/utils/musician_price.dart`: Computes musician offer payouts and customer prices based on requested hours, cutoff dates, and high-season pricing rules.
- `lib/core/utils/sax_high_season.dart`: Determines whether an event date falls within the saxophone high-season pricing windows.
- `lib/core/utils/equipment_description.dart`: Parses and serializes structured and legacy equipment lists and speaker counts for quotes and job views.
- `lib/core/utils/wknds_delivery.dart`: Defines constants and budget adjustments for non-equipped DJs using WKNDS Events equipment delivery.
- `lib/core/utils/ical_generator.dart`: Generates RFC 5545 iCalendar (.ics) exports from calendar event lists.
- `lib/core/utils/birthday_person_age.dart`: Formats birthday age text input into clean event-type heading suffixes.
- `lib/core/utils/customer_name.dart`: Extracts the customer's first name for pre-won job display.
- `lib/core/utils/phone_utils.dart`: Normalizes lead phone numbers into dialable formats with international prefix handling.
- `lib/core/utils/planned_contact.dart`: Checks if a planned customer contact date is due or past due.
- `lib/core/utils/event_type_labels.dart`: Maps internal Danish event type keys to human-readable Danish labels.
- `lib/core/utils/unsaved_changes_dialog.dart`: Prompts users with a confirmation dialog when leaving a screen with unsaved changes.
- `lib/core/widgets/dev_env_banner.dart`: Debug floating tool to switch database environments and impersonate users.
- `lib/core/widgets/restart_widget.dart`: Provides root widget tree recreation for environment changes.
- `lib/core/widgets/skeleton_loading.dart`: Provides animated skeleton placeholder cards and list views for loading states.
- `lib/core/widgets/animated_card.dart`: Adds staggered entry animations and touch-scale feedback to cards.
- `lib/core/widgets/app_snackbar.dart`: Presents standardized success and error toast notifications.

## Public interface
- OfferSubmitFailure.fromServerMessage(String message)
- AnalyticsService.observer
- AnalyticsService.setEnabled(bool value)
- AnalyticsService.setUser({required String userId, String? role})
- AnalyticsService.clearUser()
- AnalyticsService.logJobViewed(int jobId, String eventType, {required String source, String jobStatus, bool isExtJob})
- AnalyticsService.logOfferFormOpened(int jobId, String eventType, {required String role, required String source, required bool hasConflict, required bool hasActiveOffer, bool isExtJob, String? tier})
- AnalyticsService.logOfferSubmitAttempted(int jobId, {required String role, bool isExtJob, int pitchLength, bool usedAiDraft, int? msSinceFormOpen})
- EnvConfig.load()
- EnvConfig.saveEnvPreference(String env)
- EnvConfig.supabaseUrl
- EnvConfig.supabaseAnonKey
- EnvConfig.webAppUrl
- EnvConfig.isProd
- RoleCache.load()
- RoleCache.save(MusicianRole role)
- RoleCache.clear()
- RoleCache.role
- showDSDialog<T>(BuildContext context, {required String title, String? message, Widget? content, required List<Widget> Function(BuildContext ctx) actions, bool barrierDismissible})
- showDSConfirm(BuildContext context, {required String title, String? message, String confirmLabel, String cancelLabel, bool destructive})
- DSToast.show(BuildContext context, {required DSToastVariant variant, required String title, String? description, Duration duration})
- DSColors, DSBrandColors, DSBgColors, DSTextColors, DSBorderColors, DSStateColors, DSTextStyle, DSSpacing, DSRadius, DSMotion, DSShadow, lightColors, darkColors, dsContentOn
- DesignSystemShowcase
- AppException, NetworkException, AuthException, NoMusicianProfileException, NeedsProfileSetupException, DatabaseException, BillingInfoIncompleteException, BillingLockException, AgentException, AgentLimitException
- friendlyErrorMessage(Object? error, {String? fallback})
- MainShell
- setAppIconBadge(int count)
- InAppNotificationBanner
- inAppNotificationProvider, activeConversationIdProvider, suppressKeyboardDismissBarProvider
- NotificationsService.initialize(), NotificationsService.registerToken(), NotificationsService.removeToken(), NotificationsService.setupNavigationHandlers(GoRouter), NotificationsService.handleInitialMessage(GoRouter), NotificationsService.feedReadEvents, NotificationsService.loadImpersonationFlag(), NotificationsService.setImpersonating(bool)
- AppRoutes
- initSupabase(), supabase
- supabaseClientProvider
- buildAppTheme(), buildDarkAppTheme(), AppColors
- themeModeProvider, ThemeModeNotifier
- String formatBirthdayPersonAge(String? birthdayPersonAge)
- double getFeeForJob(DateTime jobCreatedAt)
- double? adjustBudgetForDjView({required double? budget, bool requestedSaxophonist, double? requestedMusicianHours, String? djTier, double? maxBudget, DateTime? jobCreatedAt, DateTime? eventDate, String? equipmentStatus})
- (int, int) bTierFallbackBudgetRange(String? equipmentStatus)
- String bTierFallbackBudgetLabel(String? equipmentStatus)
- String? djBudgetLabelFromParts({required double? budgetStart, required double? budgetEnd, required String? djTier, bool requestedSaxophonist, double? requestedMusicianHours, DateTime? jobCreatedAt, DateTime? eventDate, bool isExtJob, String? equipmentStatus})
- String? customerFirstName(String? leadName)
- ParsedEquipmentState? parseStructuredEquipmentDescription(String? raw)
- ParsedEquipmentState parseEquipmentDescription(String? raw)
- String serializeEquipmentDescription(List<String> selectedEquipment, int topSpeakerCount, int bottomSpeakerCount, [int? bottomSpeakerMin])
- List<String> getEquipmentDisplayItems(String? raw)
- String eventTypeLabel(String type)
- String generateIcal(List<CalendarEvent> events)
- int calculateMusicianOfferPrice(double? requestedHours, [DateTime? jobCreatedAt, DateTime? eventDate])
- int calculateCustomerMusicianPrice(double? requestedHours, [DateTime? jobCreatedAt, DateTime? eventDate])
- String? dialablePhoneNumber(String? raw)
- bool isPlannedContactDue(DateTime? plannedFor, {DateTime? now})
- bool isSaxHighSeason(DateTime? eventDate)
- bool isLegacySaxHighSeason(DateTime? eventDate)
- bool isSaxSeasonPricingActive(DateTime? jobCreatedAt, DateTime? eventDate)
- Future<bool?> showUnsavedChangesDialog(BuildContext context)
- bool isNonEquippedDj(String? equipmentStatus)
- int deliveryDeductionForDj(String? equipmentStatus)
- class AnimatedCard
- class AppSnackbar
- class DevEnvBanner
- class RestartWidget
- class SkeletonCard
- class SkeletonListView

## Dependencies
- cached_network_image
- firebase_analytics
- flutter_dotenv
- lucide_icons
- shared_preferences
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- flutter/material.dart
- flutter_riverpod
- go_router
- firebase_messaging
- app_badge_plus
- supabase_flutter
- google_fonts
- package:flutter/material.dart
- package:intl/intl.dart
- package:http/http.dart
- package:supabase_flutter/supabase_flutter.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/config/env_config.dart
- package:dj_tilbud_app/core/config/role_cache.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/features/auth/data/datasources/auth_remote_datasource.dart
- package:dj_tilbud_app/features/auth/data/repositories/auth_repository_impl.dart
- package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart

## AI touchpoints [AI]
- `lib/core/error/error_messages.dart`
- `lib/core/error/app_exception.dart`

## Open questions
- _none_
