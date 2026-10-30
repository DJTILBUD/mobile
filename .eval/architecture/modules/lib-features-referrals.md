# Module: lib/features/referrals

Implements the 'Henvis en kunde' (refer a customer) feature of the musician-facing app: lets a musician hand off a job request they can't take themselves to DJTILBUD, tracks the resulting referral's status and reward, and gates the feature behind accepting referral terms.

## Key files
- `lib/features/referrals/data/datasources/referrals_remote_datasource.dart`: Talks only to the web-app's /api/referrals endpoints (fetch, create, terms get/accept) using the Supabase auth token; translates HTTP responses/errors into app exceptions.
- `lib/features/referrals/data/models/referral_model.dart`: JSON (de)serialization mapping between the web API's referral/job shape and the domain Referral entity.
- `lib/features/referrals/data/repositories/referrals_repository_impl.dart`: Concrete ReferralsRepository implementation delegating to the remote datasource and converting models to entities.
- `lib/features/referrals/domain/entities/referral.dart`: Core domain entities: Referral, ReferralJob, ReferralInput, and enums for referral type/status/role type.
- `lib/features/referrals/domain/entities/referral_terms.dart`: Represents whether the performer has accepted the referral terms and the terms URL.
- `lib/features/referrals/domain/phone_countries.dart`: Phone country list and phone-number normalization/formatting logic mirrored from the customer-facing booking form.
- `lib/features/referrals/domain/referral_labels.dart`: Copy/state logic: job state labels, reward state text, Danish date formatting, event types, regions, and form-completeness validation.
- `lib/features/referrals/domain/repositories/referrals_repository.dart`: Abstract repository contract for fetching/creating referrals and managing terms acceptance.
- `lib/features/referrals/presentation/providers/referrals_provider.dart`: Riverpod providers/notifiers wiring the repository to UI state: referrals list, terms status, and create-referral submission flow.
- `lib/features/referrals/presentation/screens/referrals_screen.dart`: Main screen with two tabs ('Ny henvisning' and 'Mine henvisninger'), gates content behind terms acceptance, and handles submission feedback.
- `lib/features/referrals/presentation/widgets/referral_card.dart`: Displays a single referral's customer/job summary, status badge, and reward state.
- `lib/features/referrals/presentation/widgets/referral_form.dart`: Form widget capturing customer details (name, phone, date, event type, region, etc.) needed to create a referral.
- `lib/features/referrals/presentation/widgets/referral_success_overlay.dart`: Self-dismissing success animation shown after a referral is submitted, before switching tabs.

## Public interface
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
- referralJobState
- referralRewardState
- formatReferralDate
- referralJobSummary
- referralInputIsComplete
- roleTypeApiValue
- roleTypeLabel
- phoneCountries
- findPhoneCountry
- normalizePhoneLocal
- formatE164Phone

## Dependencies
- http
- supabase_flutter
- flutter_riverpod
- url_launcher
- lucide_icons
- dj_tilbud_app/core/config/env_config.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart

## Open questions
- The datasource docstring says creating a referral creates an ExtJob, Referrals row, admin Action and possibly a push — none of that server-side logic is visible in this module (it lives in a separate web-app repo), so its correctness can't be verified from these files alone.
- referral_labels.dart and phone_countries.dart are explicitly documented as hand-mirrored copies of logic in a separate web-app/dj-form codebase; drift between the two is only prevented by developer discipline, not shared code.
