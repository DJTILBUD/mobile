# Module: lib/features/onboarding

Guides newly registered DJs and musicians through a multi-step onboarding wizard to ensure profile completion, media uploads, customer reviews, and DJ job filters before accessing the marketplace.

## Key files
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`: Stateful multi-step onboarding screen validating profile fields, required media files, minimum reviews, and DJ filter preferences before finalizing onboarding.

## Public interface
- OnboardingScreen

## Dependencies
- package:cached_network_image/cached_network_image.dart
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
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:image_picker/image_picker.dart
- package:intl/intl.dart
- package:lucide_icons/lucide_icons.dart

## Open questions
- _none_
