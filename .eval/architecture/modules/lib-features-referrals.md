# Module: lib/features/referrals

Provides customer referral submission and tracking for musicians and DJs within the mobile app, allowing performers to hand over unserviced gig leads to DJTILBUD in exchange for rewards, accept referral terms, and view past referral statuses and payout states.

## Key files
- `lib/features/referrals/presentation/screens/referrals_screen.dart`: Main screen presenting the referral terms gate, new referral submission tab, and past referrals tracking tab.
- `lib/features/referrals/presentation/widgets/referral_form.dart`: Form widget capturing customer lead details (name, normalized phone number, event type, region, date, notes) for a referral.
- `lib/features/referrals/presentation/widgets/referral_card.dart`: Card component displaying referral status, event summary, job reference, and payout status for a referred customer.
- `lib/features/referrals/presentation/widgets/referral_success_overlay.dart`: Animated confirmation overlay displayed upon successful submission of a referral before navigating to the referrals list.
- `lib/features/referrals/presentation/providers/referrals_provider.dart`: Riverpod state providers and StateNotifier for creating referrals, fetching referrals, and checking terms acceptance status.
- `lib/features/referrals/domain/entities/referral.dart`: Domain entities and enums defining referral data models, referral jobs, status types, and creation input schemas.
- `lib/features/referrals/domain/entities/referral_terms.dart`: Domain model and URL configuration for referral terms acceptance.
- `lib/features/referrals/domain/referral_labels.dart`: Status badge formatting, copy mapping, and Danish date/text formatting functions mirroring the web-app logic.
- `lib/features/referrals/domain/phone_countries.dart`: International country dial codes, flag metadata, and phone normalization logic.
- `lib/features/referrals/domain/repositories/referrals_repository.dart`: Abstract repository interface defining referral operations and terms agreements.
- `lib/features/referrals/data/repositories/referrals_repository_impl.dart`: Implementation of ReferralsRepository calling the remote datasource.
- `lib/features/referrals/data/datasources/referrals_remote_datasource.dart`: Remote datasource communicating with the web-app REST endpoints (/api/referrals and /api/referrals/terms).
- `lib/features/referrals/data/models/referral_model.dart`: Data transfer model for serializing and deserializing referral payloads and API responses.

## Public interface
- ReferralsScreen
- ReferralCard
- ReferralForm
- ReferralSuccessOverlay
- showReferralSuccessOverlay
- referralsRepositoryProvider
- referralsProvider
- referralTermsProvider
- createReferralProvider
- CreateReferralNotifier
- ReferralsRepository
- ReferralsRepositoryImpl
- ReferralsRemoteDatasource
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
- referralJobState
- referralRewardState
- formatReferralDate
- referralJobSummary
- referralInputIsComplete
- roleTypeApiValue
- roleTypeLabel
- referralRewardDkk
- referralEventTypes
- referralRegions

## Dependencies
- http
- supabase_flutter
- flutter_riverpod
- lucide_icons
- url_launcher
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- _none_
