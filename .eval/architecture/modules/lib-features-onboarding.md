# Module: lib/features/onboarding

Guides new musicians (DJs and saxophonists) through the multi-step onboarding process, ensuring they provide profile details, media uploads, reviews, and job preferences before accessing the rest of the application.

## Key files
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`: Multi-step onboarding UI and logic handling validation of profile data, file uploads, reviews, and job filters according to musician role

## Public interface
- OnboardingScreen

## Dependencies
- dj_tilbud_app/app.dart
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
- package:cached_network_image/cached_network_image.dart
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:image_picker/image_picker.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart

## Open questions
- _none_
