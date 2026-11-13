# Module: test/features/referrals

Unit and widget tests for the referrals feature in the Flutter app, verifying referral data model serialization/deserialization, phone number formatting/normalization, status and reward copy labels, validation rules, terms acceptance gate, and referral list/form UI rendering.

## Key files
- `test/features/referrals/data/referral_model_test.dart`: Tests ReferralModel JSON parsing, deserialization from list/create responses, numeric/string reward coercion, and POST input schema mapping.
- `test/features/referrals/domain/phone_countries_test.dart`: Tests international phone number normalization, country code lookups, and E.164 phone formatting matching the customer web booking form logic.
- `test/features/referrals/domain/referral_labels_test.dart`: Tests label generation for referral job states, payout reward copy, date and job summary formatting, form validation completion checks, and enum value mapping.
- `test/features/referrals/presentation/referrals_screen_test.dart`: Widget tests for the ReferralsScreen, testing UI states (tabs, terms gate and acceptance, loading, error, empty, and populated referrals).

## Public interface
- void main() in test/features/referrals/data/referral_model_test.dart
- void main() in test/features/referrals/domain/phone_countries_test.dart
- void main() in test/features/referrals/domain/referral_labels_test.dart
- void main() in test/features/referrals/presentation/referrals_screen_test.dart

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
