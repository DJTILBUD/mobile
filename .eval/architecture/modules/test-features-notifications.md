# Module: test/features/notifications

Unit test suite verifying the staleness detection logic for job bid invitation notifications across DJ and saxophonist (musician) roles for internal and external jobs.

## Key files
- `test/features/notifications/stale_bid_notifications_test.dart`: Contains unit tests asserting when notification invitations (new_job, another_round, new_ext_job) become stale or remain active based on job status, user role, and assignment state.

## Public interface
- main()

## Dependencies
- package:dj_tilbud_app/features/notifications/domain/stale_bid_notifications.dart
- package:flutter_test/flutter_test.dart

## Open questions
- _none_
