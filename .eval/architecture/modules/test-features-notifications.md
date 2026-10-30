# Module: test/features/notifications

Unit tests for the logic that decides when a musician's 'new job' notification invitation (e.g. the DJ 'Nyt job' alert) should be cleared because the underlying job in the feed is no longer open to quotes. It encodes the business rule that invitations to quote stay visible while a job can still take quotes, and clear once it's booked, dead, or won by someone else, with special handling for saxophonist slots on jobs a DJ already closed.

## Key files
- `test/features/notifications/stale_bid_notifications_test.dart`: Test suite exercising isBidInvitationStale across job statuses, invitation types (new_job, another_round, new_ext_job), and roles (dj, musician, saxophonist via musician role, unknown role) to pin down staleness rules for quote invitations.

## Public interface
- isBidInvitationStale
- JobBidState
- kJobStatusesOpenToQuotes

## Dependencies
- dj_tilbud_app/features/notifications/domain/stale_bid_notifications.dart
- flutter_test

## Open questions
- Why does an unknown role fall back to the wider (DJ) status set, causing it to under-clear invitations for musicians whose role isn't resolved?
- Is the asymmetry between DJ and musician (saxophonist) status handling for 'closed' jobs intentional long-term, or a stopgap until sax slots get their own status model?
- How are 'new_ext_job' invitations and their hasWonOffer/assignedMusicianId fields populated upstream, and is that logic covered elsewhere?
