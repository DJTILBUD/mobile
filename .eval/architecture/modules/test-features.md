# Module: test/features

Flutter test suite for the candidate (musician/DJ) mobile app's feature modules, pinning the exact business rules of the jobs feed, quoting, won-offer payouts, profile/billing completeness, stats, referrals and notifications so the app's behavior stays byte-for-byte in sync with the web app's equivalent logic for the same marketplace data.

## Key files
- `test/features/calendar/data/models/calendar_event_model_test.dart`: Pins that the calendar's budget display always goes through the shared djBudgetLabelFromParts builder (sax/tier-adjusted), and that offer-based calendar events show the musician payout, never the raw customer budget
- `test/features/first_win/first_win_decision_test.dart`: Pins the RPC string values and precedence logic for deciding which first-win walkthrough variant (solo vs with-DJ) a musician is shown after winning a job
- `test/features/jobs/data/models/dj_quote_model_test.dart`: Pins DJ quote JSON parsing (with/without joined job) and the DJ payout calculation (override vs standard 71.5% commission split) shown to DJs for a won quote
- `test/features/jobs/domain/dj_bid_status_test.dart`: Pins parsing of the server's can-bid answer and user-facing titles for why a DJ cannot bid on a job
- `test/features/jobs/domain/entities/ext_job_test.dart`: Pins that external-job budget display shows only the musician honorar, never the customer's full amount or budget target
- `test/features/jobs/domain/entities/job_card_location_test.dart`: Pins the single shared location label (region, postal code, place) used across job/quote/offer cards
- `test/features/jobs/domain/musician_job_availability_test.dart`: Pins the rules for whether a musician can quote on a job in the feed (already bid, held/won by another, closed status, partner booking, admin-assigned)
- `test/features/jobs/domain/offer_form_validation_test.dart`: Pins validation rules (price, equipment, pitch length) for musicians submitting a quote on a job
- `test/features/jobs/domain/ready_for_billing_gate_test.dart`: Pins the gate preventing a job from being marked ready for billing until every winning musician has contacted the customer, plus the error messages shown
- `test/features/jobs/job_duration_test.dart`: Pins job duration calculation (including past-midnight jobs) shown in the job feed, mirrored against the web app
- `test/features/notifications/stale_bid_notifications_test.dart`: Pins when a 'new job' invitation notification should be cleared as stale based on job status and role (DJ vs musician/saxophonist)
- `test/features/profile/domain/billing_lock_parsing_test.dart`: Pins billing lock state, secondary billing email, and billing change request parsing used while a musician polishes profile/payment info
- `test/features/profile/domain/performer_stats_test.dart`: Pins the earned-vs-upcoming split and per-month/per-category stats computation shown on a musician's profile stats screen
- `test/features/profile/domain/self_billing_complete_test.dart`: Pins which fields make a musician's self-billing/payment info 'complete' depending on business type and payment method
- `test/features/profile/domain/self_billing_reference_format_test.dart`: Pins self-billing invoice reference format parsing and the isSelfBilled rule
- `test/features/profile/domain/sort_user_files_test.dart`: Pins the sort order for a musician's profile gallery files, including how newly uploaded files are appended
- `test/features/profile/presentation/mark_admin_message_read_test.dart`: Regression test ensuring marking an admin message read does not crash when the autoDispose notifier is disposed mid-request
- `test/features/profile/presentation/self_billing_terms_gate_test.dart`: Pins when the self-billing terms acceptance popup must show to a DJ based on feature flag and payment type
- `test/features/profile/presentation/stats_screen_test.dart`: Render tests for the musician/DJ stats screen ensuring layout does not throw and earned-vs-upcoming money is displayed and labeled correctly
- `test/features/referrals/data/referral_model_test.dart`: Pins referral JSON parsing contract with the referrals API including numeric-string reward handling
- `test/features/referrals/domain/phone_countries_test.dart`: Pins phone number normalization/formatting logic for the referral form, mirrored against the customer booking form
- `test/features/referrals/domain/referral_labels_test.dart`: Pins the referral job-state and reward-state copy/logic shown to a DJ/musician who refers a customer lead
- `test/features/referrals/presentation/referrals_screen_test.dart`: Render tests for the 'refer a customer' screen including the terms-acceptance gate, tabs, and states

## Public interface
- _none_

## Dependencies
- flutter_test
- flutter_riverpod
- dj_tilbud_app (app under test: calendar, jobs, first_win, notifications, profile, referrals features)

## Open questions
- No test file here covers the AI agent for profile polishing or sales pitch generation mentioned in the business description — is that logic untested, tested elsewhere, or not yet implemented in this app?
- Several tests describe themselves as mirrors of a separate 'web-app' codebase (web helpers, QuoteInfo, selfBillingComplete.ts, phoneCountries.ts) — that codebase is not in scope here, so duplication/drift risk between the two is only enforced by convention, not shared code.
