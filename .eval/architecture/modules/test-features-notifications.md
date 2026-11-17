# Module: test/features/notifications

Unit tests verifying stale notification evaluation logic (isBidInvitationStale) for DJ and Saxophonist job invitations across various job statuses and notification types.

## Key files
- `test/features/notifications/stale_bid_notifications_test.dart`: Unit test suite testing staleness rules for bid invitations (new_job, another_round, new_ext_job) versus non-invitation notification types.

## Public interface
- void main()

## Dependencies
- package:dj_tilbud_app/features/notifications/domain/stale_bid_notifications.dart
- package:flutter_test/flutter_test.dart

## Open questions
- _none_
