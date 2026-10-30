# Module: test/features/jobs

Test suite for the jobs feature's domain logic and data models in the musician-facing app: parsing quotes/jobs from the API, computing a musician's payout, deciding whether a job is biddable or already held by another musician, validating quote/offer form input, formatting job location and duration for job cards, and gating a job's 'ready for billing' transition on musicians having contacted the customer — i.e. the rules behind musicians finding and quoting on jobs in the feed and viewing their won quotes.

## Key files
- `test/features/jobs/data/models/dj_quote_model_test.dart`: Tests DjQuoteModel.fromJson parsing (bare quote vs. quote with joined job) and the toEntity() payout calculation, including dj_payout_override precedence and the 71.5% standard commission fallback
- `test/features/jobs/domain/dj_bid_status_test.dart`: Tests DjBidStatus.fromJson parsing of the can-bid check response, its fail-open behavior on malformed bodies, and the per-reason title text shown to the musician
- `test/features/jobs/domain/entities/ext_job_test.dart`: Tests ExtJob.budgetDisplay, asserting it shows only the honorar and never falls back to full_amount or budgetTarget (which would expose the company's cut to the musician)
- `test/features/jobs/domain/entities/job_card_location_test.dart`: Tests Job.cardLocationLabel, the shared location line used on new-job, quote and service-offer cards, combining region/postal code/city with fallbacks
- `test/features/jobs/domain/musician_job_availability_test.dart`: Tests resolveMusicianJobAvailability, the rule set deciding per job/musician whether bidding is open, already bid, held/won by another musician, closed, or blocked as a partner booking
- `test/features/jobs/domain/offer_form_validation_test.dart`: Tests validateDjQuoteInput and validateMusicianOfferInput, the quote/offer submission form validation (price, equipment selection, minimum sales-pitch length)
- `test/features/jobs/domain/ready_for_billing_gate_test.dart`: Tests isBlockedByMusicianContact, musicianContactBlockedMessage, and readyForBillingErrorMessage — the client-side gate mirroring the server rule that all winning musicians must contact the customer before a job can be marked ready for billing
- `test/features/jobs/job_duration_test.dart`: Tests jobDurationHours and formatJobDuration, computing and formatting job duration including past-midnight jobs, mirrored against the web app's identical helper

## Public interface
- DjQuoteModel.fromJson
- DjQuoteModel.toEntity
- DjBidStatus.fromJson
- DjBidStatus.title
- ExtJob.budgetDisplay
- Job.cardLocationLabel
- resolveMusicianJobAvailability
- musicianJobAvailabilityMessage
- validateDjQuoteInput
- validateMusicianOfferInput
- isBlockedByMusicianContact
- musicianContactBlockedMessage
- readyForBillingErrorMessage
- jobDurationHours
- formatJobDuration

## Dependencies
- flutter_test
- dj_tilbud_app/features/jobs/data/models/dj_quote_model.dart
- dj_tilbud_app/features/jobs/domain/dj_bid_status.dart
- dj_tilbud_app/features/jobs/domain/entities/ext_job.dart
- dj_tilbud_app/features/jobs/domain/entities/job.dart
- dj_tilbud_app/features/jobs/domain/entities/service_offer.dart
- dj_tilbud_app/features/jobs/domain/musician_job_availability.dart
- dj_tilbud_app/features/jobs/domain/offer_form_validation.dart
- dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart
- dj_tilbud_app/features/jobs/domain/job_duration.dart
- dj_tilbud_app/core/error/app_exception.dart

## Open questions
- What server-side endpoint(s) correspond to the dj_bid_status check (can_bid/reason/message) exercised in dj_bid_status_test.dart?
- How is dj_payout_override set/administered, and is there any UI elsewhere in the app that must also respect it?
- Is the 71.5%/28.5% commission split and its 2026-07-06 rate-change boundary implemented/tested anywhere else besides the fallback described in the quote test comments?
- What determines isPartnerBooking (is_partner / recurring_customer_id) for an ext job, and where is that flag populated?
