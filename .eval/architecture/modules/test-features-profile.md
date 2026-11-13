# Module: test/features/profile

Provides unit and widget test suites for profile domain logic, payment and self-billing parsing and validation, file sorting, stats calculation, and profile presentation providers/screens.

## Key files
- `test/features/profile/domain/billing_lock_parsing_test.dart`: Tests parsing of billing lock metadata, secondary billing emails, validation logic, and billing change request statuses.
- `test/features/profile/domain/performer_stats_test.dart`: Tests computation of performer stats including earned vs upcoming revenue, chronological monthly breakdown, and categorization.
- `test/features/profile/domain/self_billing_complete_test.dart`: Tests self-billing and payment profile completeness rules across business types.
- `test/features/profile/domain/self_billing_reference_format_test.dart`: Tests self-billing reference format DB mappings and payment entity helper methods.
- `test/features/profile/domain/sort_user_files_test.dart`: Tests gallery image sorting behavior with explicit sort order, null append ordering, and tie-breakers.
- `test/features/profile/presentation/mark_admin_message_read_test.dart`: Tests autoDispose lifecycle safety for the MarkAdminMessageReadNotifier during async operations.
- `test/features/profile/presentation/self_billing_terms_gate_test.dart`: Tests conditional gating for self-billing terms acceptance across payment types and live feature flags.
- `test/features/profile/presentation/stats_screen_test.dart`: Widget tests validating stats screen rendering, empty states, upcoming/earned legend displays, responsive constraints, and unauthenticated behavior.

## Public interface
- void main() in test/features/profile/domain/billing_lock_parsing_test.dart
- void main() in test/features/profile/domain/performer_stats_test.dart
- void main() in test/features/profile/domain/self_billing_complete_test.dart
- void main() in test/features/profile/domain/self_billing_reference_format_test.dart
- void main() in test/features/profile/domain/sort_user_files_test.dart
- void main() in test/features/profile/presentation/mark_admin_message_read_test.dart
- void main() in test/features/profile/presentation/self_billing_terms_gate_test.dart
- void main() in test/features/profile/presentation/stats_screen_test.dart

## Dependencies
- package:flutter_test/flutter_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter/material.dart
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
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dart:async

## Open questions
- _none_
