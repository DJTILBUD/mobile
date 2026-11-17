# Module: web-app/src/features/suppression

Unit and regression tests validating DJ suppression logic, verifying that suppressed DJs are excluded from job listings and availability queries and disabled from submitting quote forms, while ensuring backward compatibility with unsuppressed profiles.

## Key files
- `web-app/src/features/suppression/suppression.test.ts`: Test suite covering DjInfo typing with is_suppressed, filtering behavior for job availability, quote form input disabling, and edge case handling.

## Public interface
- _none_

## Dependencies
- vitest
- @/types/database.types

## Open questions
- Where is the runtime implementation of the DJ suppression logic encapsulated (e.g., hooks, server endpoints, or shared utility functions)?
