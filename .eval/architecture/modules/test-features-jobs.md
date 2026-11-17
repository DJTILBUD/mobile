# Module: test/features/jobs

Provides unit and widget test suites for the jobs feature in the musician-facing app, covering DJ quotes and payout calculations, bid withdrawal windows, job availability rules, equipment delivery logistics, duration formatting, offer form validation, ready-for-billing checks, and UI interaction widgets.

## Key files
- `test/features/jobs/data/models/dj_quote_model_test.dart`: Tests JSON serialization and DJ payout calculation logic for quotes
- `test/features/jobs/domain/bid_withdrawal_test.dart`: Tests bid withdrawal time windows, countdown calculation, and bid pinning logic
- `test/features/jobs/domain/equipment_delivery_test.dart`: Tests equipment delivery data parsing, logistics diffing, and guest validation
- `test/features/jobs/domain/musician_job_availability_test.dart`: Tests resolution rules for whether a musician or saxophonist can bid on a job or ext-job
- `test/features/jobs/domain/ready_for_billing_gate_test.dart`: Tests gate conditions preventing jobs from entering ready-for-billing status before all winning musicians have contacted the customer
- `test/features/jobs/domain/offer_form_validation_test.dart`: Tests input validation for DJ quotes and musician offer forms
- `test/features/jobs/job_duration_test.dart`: Tests job duration calculation across midnight boundaries and localized formatting
- `test/features/jobs/presentation/equipment_delivery_section_test.dart`: Widget tests verifying delivery logistics editing, save button state, and canceled state handling
- `test/features/jobs/presentation/job_feedback_sheet_test.dart`: Widget tests for the non-bid feedback bottom sheet and repository submissions

## Public interface
- main() in test/features/jobs/data/models/dj_quote_model_test.dart
- main() in test/features/jobs/domain/bid_withdrawal_test.dart
- main() in test/features/jobs/domain/delivery_action_summary_test.dart
- main() in test/features/jobs/domain/dj_bid_status_test.dart
- main() in test/features/jobs/domain/entities/ext_job_test.dart
- main() in test/features/jobs/domain/entities/job_card_location_test.dart
- main() in test/features/jobs/domain/equipment_delivery_test.dart
- main() in test/features/jobs/domain/job_feedback_test.dart
- main() in test/features/jobs/domain/musician_job_availability_test.dart
- main() in test/features/jobs/domain/my_payout_test.dart
- main() in test/features/jobs/domain/offer_form_validation_test.dart
- main() in test/features/jobs/domain/ready_for_billing_gate_test.dart
- main() in test/features/jobs/job_duration_test.dart
- main() in test/features/jobs/presentation/equipment_delivery_section_test.dart
- main() in test/features/jobs/presentation/job_feedback_sheet_test.dart

## Dependencies
- package:flutter/material.dart
- package:flutter_test/flutter_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:intl/date_symbol_data_local.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart
- package:dj_tilbud_app/features/jobs/domain/bid_withdrawal.dart
- package:dj_tilbud_app/features/jobs/domain/dj_bid_status.dart
- package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart
- package:dj_tilbud_app/features/jobs/domain/job_duration.dart
- package:dj_tilbud_app/features/jobs/domain/job_feedback.dart
- package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart
- package:dj_tilbud_app/features/jobs/domain/my_payout.dart
- package:dj_tilbud_app/features/jobs/domain/offer_form_validation.dart
- package:dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart
- package:dj_tilbud_app/features/jobs/domain/repositories/jobs_repository.dart
- package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart
- package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_delivery_section.dart
- package:dj_tilbud_app/features/jobs/presentation/widgets/job_feedback_sheet.dart

## Open questions
- _none_
