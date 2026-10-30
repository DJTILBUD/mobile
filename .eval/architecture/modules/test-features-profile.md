# Module: test/features/profile

Unit and widget tests for the musician-facing profile feature: payment/billing setup (invoicing vs B-income, self-billing completeness, billing locks and change requests), performer earnings statistics (played vs booked-ahead jobs), profile photo/file ordering, admin message read-state handling, and the self-billing terms acceptance gate. These tests exercise the logic that lets a musician create and polish their profile and see how their won quotes translate into billable, earned, or upcoming income.

## Key files
- `test/features/profile/domain/billing_lock_parsing_test.dart`: Verifies PaymentInfoModel parses billing_locked_at and billing_email_secondary, never re-sends the lock timestamp to the server, validates a secondary billing email, and parses BillingChangeRequest status/admin-note fields from the API.
- `test/features/profile/domain/performer_stats_test.dart`: Tests computeStats: totals, year filtering, busiest-month logic, and the earned-vs-upcoming split so jobs booked ahead are never counted as already played/earned.
- `test/features/profile/domain/self_billing_complete_test.dart`: Tests isSelfBillingComplete and payment-type-aware isPaymentInfoComplete/isSelfBillingPayoutReady/missingPayoutReadyFields across business entity types (ApS, sole trader, private) and payment methods (Invoice, B-income).
- `test/features/profile/domain/self_billing_reference_format_test.dart`: Tests the SelfBillingReferenceFormat enum's DB value mapping/fallback, PaymentInfoModel parsing of the reference format (and exclusion from outgoing JSON), and PaymentInfo.isSelfBilled across payment/business-type combinations.
- `test/features/profile/domain/sort_user_files_test.dart`: Tests sortUserFiles ordering rules: ascending sortOrder, legacy null-sortOrder rows keeping insertion order, new (null) uploads appending after ordered ones, stable tie-breaking by id, and non-mutation of input.
- `test/features/profile/presentation/mark_admin_message_read_test.dart`: Regression test ensuring MarkAdminMessageReadNotifier (an autoDispose provider) survives being disposed mid-request without throwing, reporting success/failure instead of crashing.
- `test/features/profile/presentation/self_billing_terms_gate_test.dart`: Tests needsSelfBillingTermsProvider logic: shows the self-billing terms popup only when the self-billing flag is live, the musician's saved payment type is Invoice, and terms aren't yet accepted.
- `test/features/profile/presentation/stats_screen_test.dart`: Widget/render tests for StatsScreen covering populated, empty, signed-out, and excluded-entry states, the earned-vs-upcoming visual split, legend visibility, and narrow-screen layout safety.

## Public interface
- computeStats
- StatEntry
- sortUserFiles
- UserFile
- isSelfBillingComplete
- isPaymentInfoComplete
- isSelfBillingPayoutReady
- missingPayoutReadyFields
- validateSecondaryBillingEmail
- SelfBillingReferenceFormat
- PaymentInfo.isSelfBilled
- PaymentInfoModel
- BillingChangeRequest
- MarkAdminMessageReadNotifier
- needsSelfBillingTermsProvider
- selfBillingLiveProvider
- djPaymentInfoProvider
- StatsScreen
- statEntriesProvider
- statsYearProvider
- hasSessionProvider

## Dependencies
- dj_tilbud_app/features/profile/data/models/payment_info_model.dart
- dj_tilbud_app/features/profile/domain/billing_email_validation.dart
- dj_tilbud_app/features/profile/domain/entities/billing_change_request.dart
- dj_tilbud_app/features/profile/domain/self_billing_complete.dart
- dj_tilbud_app/features/profile/domain/performer_stats.dart
- dj_tilbud_app/features/profile/domain/entities/payment_info.dart
- dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart
- dj_tilbud_app/features/profile/domain/entities/user_file.dart
- dj_tilbud_app/features/profile/domain/sort_user_files.dart
- dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- dj_tilbud_app/features/profile/presentation/providers/stats_provider.dart
- dj_tilbud_app/features/profile/presentation/screens/stats_screen.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- flutter_riverpod
- flutter_test
- flutter/material.dart

## Open questions
- Several tests state they mirror files in web-app (e.g. web-app/documentation/billing-lock-plan.md, web-app/src/helpers/selfBillingComplete.test.ts, selfBillingReferenceFormat.ts, sortUserFiles.test.ts) that must be kept in sync — those files are not present in this module, so cross-repo consistency can't be verified here.
- performer_stats_test.dart content was truncated, so the full set of computeStats cases (beyond totals/year filter/busiest-month) is not fully visible.
- The actual source implementations (performer_stats.dart, self_billing_complete.dart, stats_provider.dart, stats_screen.dart, profile_provider.dart, etc.) are only inferred from these tests, not reviewed directly.
