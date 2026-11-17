# Module: test/features/profile

Test suite for profile feature domain logic and presentation components, validating bank account validation, self-billing completeness and reference formats, performer earnings calculations, venue input handling, file ordering, admin message read notifications, and UI rendering of statistics and venue inputs.

## Key files
- `test/features/profile/domain/bank_account_guard_test.dart`: Unit tests for Danish bank account, CVR, and CPR validation guards
- `test/features/profile/domain/billing_lock_parsing_test.dart`: Unit tests for billing lock parsing, secondary billing email validation, and change request status parsing
- `test/features/profile/domain/performer_stats_test.dart`: Unit tests for performer earnings computations, distinguishing earned historical gigs from upcoming bookings and handling monthly/categorical rollups
- `test/features/profile/domain/self_billing_complete_test.dart`: Unit tests for self-billing completeness criteria across various business entity types
- `test/features/profile/domain/self_billing_reference_format_test.dart`: Unit tests for self-billing reference format parsing and self-billed status checks
- `test/features/profile/domain/sort_user_files_test.dart`: Unit tests verifying sort order behavior for user files and gallery media
- `test/features/profile/domain/venues_test.dart`: Unit tests for parsing, trimming, deduplication, and max-length handling of venue tags
- `test/features/profile/presentation/mark_admin_message_read_test.dart`: Notifier unit tests ensuring MarkAdminMessageReadNotifier safely survives disposal while network calls are in flight
- `test/features/profile/presentation/self_billing_terms_gate_test.dart`: Provider unit tests evaluating conditions under which self-billing terms acceptance is prompted
- `test/features/profile/presentation/stats_screen_test.dart`: Widget tests for the statistics screen layout, responsive sizing, payout exclusion notes, and earned vs. upcoming visual breakdown
- `test/features/profile/presentation/venues_input_test.dart`: Widget tests validating interaction, input triggers, and chip deletions on the venue input widget

## Public interface
- _none_

## Dependencies
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart
- package:dj_tilbud_app/features/profile/domain/bank_account_guard.dart
- package:dj_tilbud_app/features/profile/domain/billing_email_validation.dart
- package:dj_tilbud_app/features/profile/domain/entities/billing_change_request.dart
- package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart
- package:dj_tilbud_app/features/profile/domain/entities/user_file.dart
- package:dj_tilbud_app/features/profile/domain/performer_stats.dart
- package:dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart
- package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart
- package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart
- package:dj_tilbud_app/features/profile/domain/sort_user_files.dart
- package:dj_tilbud_app/features/profile/domain/venues.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- package:dj_tilbud_app/features/profile/presentation/providers/stats_provider.dart
- package:dj_tilbud_app/features/profile/presentation/screens/stats_screen.dart
- package:dj_tilbud_app/features/profile/presentation/widgets/venues_input.dart
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter_test/flutter_test.dart

## Open questions
- _none_
