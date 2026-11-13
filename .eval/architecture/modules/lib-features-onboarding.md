# Module: lib/features/onboarding

Provides the multi-step onboarding wizard for newly registered DJs and musicians to complete their initial profile information, upload required media (profile photo, common picture, and video), add at least three reviews, and configure job preferences/filters.

## Key files
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`: Stateful multi-step onboarding screen guiding DJs (4 steps) and other musicians (3 steps) through profile completion, media validation, review entries, and job filter setup.

## Public interface
- OnboardingScreen

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:cached_network_image/cached_network_image.dart
- package:image_picker/image_picker.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart
- package:dj_tilbud_app/app.dart
- package:dj_tilbud_app/core/config/role_cache.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/error/error_messages.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/utils/event_type_labels.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/profile/domain/entities/dj_job_filters.dart
- package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- package:dj_tilbud_app/features/profile/domain/entities/review.dart
- package:dj_tilbud_app/features/profile/domain/entities/user_file.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## Open questions
- _none_
