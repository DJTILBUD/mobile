# Module: test/features/jobs

Unit tests for the jobs feature domain logic and data models in the Flutter mobile app, verifying quote parsing, payout override rules, DJ bidding statuses, external job budget display, card location formatting, musician job availability resolution, offer form validations, ready-for-billing gating, and job duration calculations.

## Key files
- `test/features/jobs/data/models/dj_quote_model_test.dart`: Tests DjQuoteModel JSON serialization, entity conversion, payout calculations, and payout override logic.
- `test/features/jobs/domain/dj_bid_status_test.dart`: Tests DjBidStatus parsing from JSON responses, fallback logic for malformed data, and user-facing title strings.
- `test/features/jobs/domain/entities/ext_job_test.dart`: Tests ExtJob entity budget display logic to ensure only honorar is exposed.
- `test/features/jobs/domain/entities/job_card_location_test.dart`: Tests location label formatting on Job entity cards across regions, postal codes, and city names.
- `test/features/jobs/domain/musician_job_availability_test.dart`: Tests musician job availability resolution rules covering partner bookings, assigned musicians, active offers, and job status constraints.
- `test/features/jobs/domain/offer_form_validation_test.dart`: Tests client-side validation logic for DJ quotes and musician offer forms.
- `test/features/jobs/domain/ready_for_billing_gate_test.dart`: Tests the client-side gating and error message mapping for moving a job to ready for billing based on musician contact state.
- `test/features/jobs/job_duration_test.dart`: Tests job duration hour calculation across midnight and formatting of duration strings.

## Public interface
- main()

## Dependencies
- package:flutter_test/flutter_test.dart
- package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart
- package:dj_tilbud_app/features/jobs/domain/dj_bid_status.dart
- package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart
- package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart
- package:dj_tilbud_app/features/jobs/domain/offer_form_validation.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- package:dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart
- package:dj_tilbud_app/features/jobs/domain/job_duration.dart

## Open questions
- _none_
