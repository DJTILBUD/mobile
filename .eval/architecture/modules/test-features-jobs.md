# Module: test/features/jobs

Unit tests for the jobs feature domain logic, data models, validation rules, billing gates, payout calculations, and job availability rules for DJs and musicians.

## Key files
- `test/features/jobs/data/models/dj_quote_model_test.dart`: Tests DjQuoteModel JSON serialization, placeholder fallback, and DJ payout calculation logic including override rules.
- `test/features/jobs/domain/dj_bid_status_test.dart`: Tests DjBidStatus parsing and localized status title determination.
- `test/features/jobs/domain/entities/ext_job_test.dart`: Tests ExtJob budget display formatting and confidentiality enforcement against customer total leakage.
- `test/features/jobs/domain/entities/job_card_location_test.dart`: Tests location label formatting on job cards across region, postal code, and city combinations.
- `test/features/jobs/domain/musician_job_availability_test.dart`: Tests musician job bidding availability logic based on job status, partner bookings, offers, and musician assignments.
- `test/features/jobs/domain/offer_form_validation_test.dart`: Tests input validation for DJ quotes and musician offer forms.
- `test/features/jobs/domain/ready_for_billing_gate_test.dart`: Tests client-side gate validation and error messaging requiring all winning musicians to contact the customer before billing.
- `test/features/jobs/job_duration_test.dart`: Tests calculation and Danish formatting of job durations across day boundaries.

## Public interface
- void main() in test/features/jobs/data/models/dj_quote_model_test.dart
- void main() in test/features/jobs/domain/dj_bid_status_test.dart
- void main() in test/features/jobs/domain/entities/ext_job_test.dart
- void main() in test/features/jobs/domain/entities/job_card_location_test.dart
- void main() in test/features/jobs/domain/musician_job_availability_test.dart
- void main() in test/features/jobs/domain/offer_form_validation_test.dart
- void main() in test/features/jobs/domain/ready_for_billing_gate_test.dart
- void main() in test/features/jobs/job_duration_test.dart

## Dependencies
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart
- package:dj_tilbud_app/features/jobs/domain/dj_bid_status.dart
- package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/job.dart
- package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- package:dj_tilbud_app/features/jobs/domain/job_duration.dart
- package:dj_tilbud_app/features/jobs/domain/musician_job_availability.dart
- package:dj_tilbud_app/features/jobs/domain/offer_form_validation.dart
- package:dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart
- package:flutter_test/flutter_test.dart

## Open questions
- _none_
