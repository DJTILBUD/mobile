# Module: test/features/referrals

Test suite for the referrals ('Henvis en kunde') feature in the Flutter musician app, verifying that referral data parsing, phone-number normalization, state/reward label copy, and the referrals screen UI stay faithful to the web app's booking-form and referrals-page behavior so a musician referring a customer sees consistent job status and payout information.

## Key files
- `test/features/referrals/data/referral_model_test.dart`: Guards the JSON contract for GET/POST /api/referrals (ReferralModel.fromJson, fromCreateResponse, inputToJson), including tolerating reward_dkk as either a number or numeric string and handling a missing job.
- `test/features/referrals/domain/phone_countries_test.dart`: Ports test cases from the web app's phoneCountries.test.ts to verify normalizePhoneLocal, findPhoneCountry, and formatE164Phone match the customer-facing booking form's phone handling.
- `test/features/referrals/domain/referral_labels_test.dart`: Pins Danish state/reward copy (referralJobState, referralRewardState, formatReferralDate, referralJobSummary, referralInputIsComplete, referralEventTypes, referralRegions, roleTypeApiValue) to the web ReferralsPage.tsx logic.
- `test/features/referrals/presentation/referrals_screen_test.dart`: Widget tests for ReferralsScreen covering the terms-acceptance gate, the 'Ny henvisning' form tab's disabled submit state, and the 'Mine henvisninger' list's loading/empty/error/populated states.

## Public interface
- _none_

## Dependencies
- dj_tilbud_app/features/referrals/data/models/referral_model.dart
- dj_tilbud_app/features/referrals/domain/entities/referral.dart
- dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart
- dj_tilbud_app/features/referrals/domain/phone_countries.dart
- dj_tilbud_app/features/referrals/domain/referral_labels.dart
- dj_tilbud_app/features/referrals/domain/repositories/referrals_repository.dart
- dj_tilbud_app/features/referrals/presentation/providers/referrals_provider.dart
- dj_tilbud_app/features/referrals/presentation/screens/referrals_screen.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/core/design_system/components.dart
- flutter_test
- flutter_riverpod
- flutter/material.dart

## Open questions
- What is the authoritative source (web app files) these tests mirror — e.g. ReferralsPage.tsx, dj-form/src/App.tsx — since this module only ports/pins their behavior without including them?
- Where is ReferralsRepository's real HTTP implementation (only a fake is shown here) and does it live outside this test module?
- Is the referral terms-acceptance gate persisted server-side only, or also cached locally, given the test only exercises the repository-backed flow?
