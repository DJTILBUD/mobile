# Module: lib/features/referrals

Provides the mobile referrals feature allowing musicians and DJs to hand over client leads to DJTILBUD, track referral statuses and rewards, and accept referral terms.

## Key files
- `lib/features/referrals/data/datasources/referrals_remote_datasource.dart`: Communicates with the web-app backend REST API (/api/referrals and /api/referrals/terms) using Supabase session tokens.
- `lib/features/referrals/data/models/referral_model.dart`: Encapsulates JSON serialization and deserialization for referrals and referral creation payloads into domain entities.
- `lib/features/referrals/data/repositories/referrals_repository_impl.dart`: Implements ReferralsRepository, converting data models from ReferralsRemoteDatasource into domain models.
- `lib/features/referrals/domain/entities/referral.dart`: Defines core domain entities including Referral, ReferralJob, ReferralInput, ReferralType, ReferralStatus, and ReferralRoleType.
- `lib/features/referrals/domain/entities/referral_terms.dart`: Defines domain structures and URLs for referral terms acceptance.
- `lib/features/referrals/domain/phone_countries.dart`: Handles country code parsing, local phone normalization, and E.164 phone formatting matching web and booking form formats.
- `lib/features/referrals/domain/referral_labels.dart`: Formats UI copy, job statuses, reward states, localized Danish dates, and provides referral event type/region constants.
- `lib/features/referrals/domain/repositories/referrals_repository.dart`: Defines the repository interface contract for referral operations and terms agreements.
- `lib/features/referrals/presentation/providers/referrals_provider.dart`: Riverpod providers managing referral list fetching, terms checking, and referral submission state.
- `lib/features/referrals/presentation/screens/referrals_screen.dart`: Main referral UI containing a tabbed interface for submitting new customer leads and viewing referral history.
- `lib/features/referrals/presentation/widgets/referral_card.dart`: Widget displaying individual referral details, status badge, reward status, and creation date.
- `lib/features/referrals/presentation/widgets/referral_form.dart`: Form widget for collecting referred customer details including name, phone with country code, date, event type, region, and role.
- `lib/features/referrals/presentation/widgets/referral_success_overlay.dart`: Animated dialog celebrating successful submission of a referral lead before switching tabs.

## Public interface
- ReferralsRemoteDatasource
- ReferralModel
- ReferralsRepositoryImpl
- ReferralsRepository
- Referral
- ReferralJob
- ReferralInput
- ReferralType
- ReferralStatus
- ReferralRoleType
- ReferralTermsStatus
- kReferralTermsUrl
- PhoneCountry
- phoneCountries
- findPhoneCountry
- normalizePhoneLocal
- formatE164Phone
- referralRewardDkk
- referralJobState
- referralRewardState
- formatReferralDate
- referralJobSummary
- referralEventTypes
- referralRegions
- referralInputIsComplete
- roleTypeApiValue
- roleTypeLabel
- referralsRepositoryProvider
- referralsProvider
- referralTermsProvider
- createReferralProvider
- CreateReferralNotifier
- ReferralsScreen
- ReferralCard
- ReferralForm
- ReferralSuccessOverlay
- showReferralSuccessOverlay

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:http/http.dart
- package:lucide_icons/lucide_icons.dart
- package:supabase_flutter/supabase_flutter.dart
- package:url_launcher/url_launcher.dart
- package:dj_tilbud_app/core/config/env_config.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/error/error_messages.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- _none_
