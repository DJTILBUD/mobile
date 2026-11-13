# Module: lib/features/referrals

Enables musicians to refer customer event leads they cannot take to DJTILBUD in exchange for rewards, accept referral terms, submit new lead details, and track referral and payout statuses.

## Key files
- `lib/features/referrals/data/datasources/referrals_remote_datasource.dart`: Handles HTTP communication with the web application's referral endpoints (/api/referrals and /api/referrals/terms).
- `lib/features/referrals/data/models/referral_model.dart`: Serializes and deserializes referral objects, external job details, and referral creation payloads.
- `lib/features/referrals/data/repositories/referrals_repository_impl.dart`: Implements the domain repository interface to fetch referrals, submit new leads, and manage terms acceptance.
- `lib/features/referrals/domain/entities/referral.dart`: Defines core domain entities and enums for referrals, associated job summaries, and lead submission inputs.
- `lib/features/referrals/domain/entities/referral_terms.dart`: Defines the referral terms URL and acceptance status entity.
- `lib/features/referrals/domain/phone_countries.dart`: Contains country dialing code definitions and phone number normalization utilities mirroring the web booking form.
- `lib/features/referrals/domain/referral_labels.dart`: Provides label mapping, status badge tones, reward payout strings, event types, regions, and form validation logic.
- `lib/features/referrals/domain/repositories/referrals_repository.dart`: Defines the contract for fetching referrals, creating referrals, and managing referral terms acceptance.
- `lib/features/referrals/presentation/providers/referrals_provider.dart`: Provides Riverpod providers and a StateNotifier for managing terms verification, referrals loading, and form submission.
- `lib/features/referrals/presentation/screens/referrals_screen.dart`: Main referral screen displaying terms gating, new referral submission form, and submitted referral history tabs.
- `lib/features/referrals/presentation/widgets/referral_card.dart`: Card widget displaying the lead name, event summary, job status badge, and reward/payout instructions.
- `lib/features/referrals/presentation/widgets/referral_form.dart`: Form widget for capturing lead contact information, event type, date, region, and role preferences.
- `lib/features/referrals/presentation/widgets/referral_success_overlay.dart`: Animated temporary celebration overlay displayed immediately after successful referral creation.

## Public interface
- ReferralsScreen
- referralsRepositoryProvider
- referralsProvider
- referralTermsProvider
- createReferralProvider
- ReferralsRepository
- Referral
- ReferralJob
- ReferralInput
- ReferralType
- ReferralStatus
- ReferralRoleType
- ReferralTermsStatus
- showReferralSuccessOverlay

## Dependencies
- flutter/material.dart
- flutter_riverpod
- lucide_icons
- http
- supabase_flutter
- url_launcher
- package:dj_tilbud_app/core/config/env_config.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/error/error_messages.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- _none_
