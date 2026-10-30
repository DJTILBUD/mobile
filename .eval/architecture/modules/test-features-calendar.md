# Module: test/features/calendar

Test suite verifying that calendar events for musicians show a single, consistent budget figure that matches the job list's budget calculation (via djBudgetLabelFromParts), rather than the raw customer budget, and that for direct/ext-job offers the calendar shows the musician's payout rather than the customer price or budget target.

## Key files
- `test/features/calendar/data/models/calendar_event_model_test.dart`: Unit tests for CalendarEventModel's budgetDisplay logic across DJ quotes, musician job offers, and musician ext-job offers

## Public interface
- _none_

## Dependencies
- dj_tilbud_app/core/utils/budget_utils.dart
- dj_tilbud_app/features/calendar/data/models/calendar_event_model.dart

## Open questions
- What other DJ tiers besides 'A' and 'B' exist and how do their deduction amounts differ?
- Are there other calendar event sources (e.g., customer-side events) that also need budgetDisplay parity tests?
- Is the 24h window deduction logic (referenced in the B-tier test) documented/tested elsewhere, e.g. in budget_utils tests?
