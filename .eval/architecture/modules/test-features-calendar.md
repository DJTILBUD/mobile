# Module: test/features/calendar

Unit tests for CalendarEventModel JSON parsing, verifying that calendar event budget display calculations (such as saxophonist deductions, tier adjustments, and musician payout fallbacks) remain consistent with the job list and never expose raw customer budgets incorrectly.

## Key files
- `test/features/calendar/data/models/calendar_event_model_test.dart`: Tests factory constructors CalendarEventModel.fromDjQuoteJson, fromMusicianJobOfferJson, and fromMusicianExtJobOfferJson for correct budget formatting and payout handling.

## Public interface
- void main()

## Dependencies
- package:flutter_test/flutter_test.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/features/calendar/data/models/calendar_event_model.dart

## Open questions
- _none_
