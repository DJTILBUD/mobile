# Module: lib/features/onboarding

Multi-step onboarding wizard that walks a newly registered musician/DJ through completing their profile (required fields, media uploads, reviews) and, for DJs, configuring job feed filters before marking onboarding as complete.

## Key files
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`: Stateful screen implementing the step-by-step onboarding flow (profile fields, photos/video, reviews, and DJ-only job filters step), computing step completion/hints and finishing onboarding via the profile repository.

## Public interface
- OnboardingScreen

## Dependencies
- flutter_riverpod
- cached_network_image
- image_picker
- intl
- lucide_icons
- dj_tilbud_app/app.dart (markOnboardingComplete)
- dj_tilbud_app/core/config/role_cache.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/utils/event_type_labels.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart
- dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- dj_tilbud_app/features/profile/domain/entities/review.dart
- dj_tilbud_app/features/profile/domain/entities/user_file.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## Open questions
- The file is truncated (header building and subsequent widget-building methods like _buildStepIndicator, _buildStepContent, _buildFooter, and the DJ filters step UI are not shown), so full UI/filter logic cannot be fully summarized.
- No other files in lib/features/onboarding were provided (e.g., providers, repositories specific to onboarding), so it's unclear if onboarding has its own state management beyond reusing profile providers.
