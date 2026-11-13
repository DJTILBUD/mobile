# Module: test/features/profile

Unit and widget tests for the profile feature, covering domain business logic (billing lock parsing, self-billing completeness, reference format handling, file sorting, and performer earnings statistics) and presentation layer behavior (admin message read notifier handling, self-billing terms gating, and stats screen rendering).

## Key files
- `test/features/profile/domain/billing_lock_parsing_test.dart`: Tests PaymentInfoModel billing lock parsing, secondary billing email validation, and BillingChangeRequest parsing.
- `test/features/profile/domain/performer_stats_test.dart`: Tests computeStats calculation logic for performer earnings, separating played vs upcoming jobs, month aggregations, and category breakdowns.
- `test/features/profile/domain/self_billing_complete_test.dart`: Tests completeness validation rules for self-billing across business entity types (ApS, sole trader, private) and payment methods.
- `test/features/profile/domain/self_billing_reference_format_test.dart`: Tests SelfBillingReferenceFormat parsing and payment self-billed detection.
- `test/features/profile/domain/sort_user_files_test.dart`: Tests ordering logic for user-uploaded profile files, ensuring null sort orders append stably.
- `test/features/profile/presentation/mark_admin_message_read_test.dart`: Tests MarkAdminMessageReadNotifier lifecycle resilience when autoDisposed mid-request.
- `test/features/profile/presentation/self_billing_terms_gate_test.dart`: Tests needsSelfBillingTermsProvider logic and terms acceptance parsing.
- `test/features/profile/presentation/stats_screen_test.dart`: Widget tests for StatsScreen validating layouts, empty states, sign-out safety, and upcoming job badges for musicians.

## Public interface
- void main()

## Dependencies
- flutter_test
- flutter/material.dart
- flutter_riverpod
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:dj_tilbud_app/features/profile/data/models/payment_info_model.dart
- package:dj_tilbud_app/features/profile/domain/billing_email_validation.dart
- package:dj_tilbud_app/features/profile/domain/entities/billing_change_request.dart
- package:dj_tilbud_app/features/profile/domain/entities/payment_info.dart
- package:dj_tilbud_app/features/profile/domain/entities/user_file.dart
- package:dj_tilbud_app/features/profile/domain/performer_stats.dart
- package:dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart
- package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart
- package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart
- package:dj_tilbud_app/features/profile/domain/sort_user_files.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- package:dj_tilbud_app/features/profile/presentation/providers/stats_provider.dart
- package:dj_tilbud_app/features/profile/presentation/screens/stats_screen.dart

## Open questions
- _none_
