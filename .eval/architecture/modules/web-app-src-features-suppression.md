# Module: web-app/src/features/suppression

Provides test suites validating DJ suppression behavior, ensuring musicians with the is_suppressed flag set to true are blocked from viewing jobs, submitting quotes, and appearing in DJ availability queries.

## Key files
- `web-app/src/features/suppression/suppression.test.ts`: Unit and type safety tests verifying DjInfo.is_suppressed behavior, job filtering logic, quote form input disabling, and backward compatibility.

## Public interface
- _none_

## Dependencies
- vitest
- @/types/database.types

## Open questions
- Are the production suppression hooks/components (such as useUnbidJobsFromMyRegions or QuoteForm logic) meant to be co-located in this feature directory or maintained in other feature folders?
