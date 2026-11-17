# Module: test/features/referrals

Unit and widget tests for the referrals feature in the Flutter app, verifying JSON data serialization, phone country formatting and normalisation, label formatting and business state rules, terms gate validation, and UI tab rendering on the referral screen.

## Key files
- `test/features/referrals/data/referral_model_test.dart`: Tests JSON deserialization from API responses and serialization of referral creation inputs to match API payloads.
- `test/features/referrals/domain/phone_countries_test.dart`: Tests local phone normalization, country resolution, and E.164 phone formatting logic.
- `test/features/referrals/domain/referral_labels_test.dart`: Tests domain presentation helpers, form validation rules, enum mappings, and status/payout copy.
- `test/features/referrals/presentation/referrals_screen_test.dart`: Widget tests covering the referrals screen, terms acceptance gating, tab switching, and empty/error/loading/populated states.

## Public interface
- main() in referral_model_test.dart
- main() in phone_countries_test.dart
- main() in referral_labels_test.dart
- main() in referrals_screen_test.dart

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter_test/flutter_test.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/referrals/data/models/referral_model.dart
- package:dj_tilbud_app/features/referrals/domain/entities/referral.dart
- package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart
- package:dj_tilbud_app/features/referrals/domain/phone_countries.dart
- package:dj_tilbud_app/features/referrals/domain/referral_labels.dart
- package:dj_tilbud_app/features/referrals/domain/repositories/referrals_repository.dart
- package:dj_tilbud_app/features/referrals/presentation/providers/referrals_provider.dart
- package:dj_tilbud_app/features/referrals/presentation/screens/referrals_screen.dart

## Open questions
- _none_
