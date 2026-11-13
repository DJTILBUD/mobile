# Module: test/features/referrals

Unit and widget test suite for the referrals feature, verifying JSON serialization of referral models, phone number normalization/formatting, domain label and status logic, and UI rendering of referral forms, terms gates, and lists.

## Key files
- `test/features/referrals/data/referral_model_test.dart`: Unit tests verifying referral model serialization, deserialization (including string-to-number reward casting), and API input payload mapping
- `test/features/referrals/domain/phone_countries_test.dart`: Unit tests verifying country code lookup, phone number normalization, and E.164 phone formatting
- `test/features/referrals/domain/referral_labels_test.dart`: Unit tests verifying domain copy, job/reward statuses, date formatting, and form validation completeness rules
- `test/features/referrals/presentation/referrals_screen_test.dart`: Widget tests covering the referrals screen lifecycle, terms gate acceptance, tab switching, form validation, and referral list states

## Public interface
- main() in test/features/referrals/data/referral_model_test.dart
- main() in test/features/referrals/domain/phone_countries_test.dart
- main() in test/features/referrals/domain/referral_labels_test.dart
- main() in test/features/referrals/presentation/referrals_screen_test.dart

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
