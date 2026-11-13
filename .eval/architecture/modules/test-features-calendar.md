# Module: test/features/calendar

Unit tests verifying budget and payout formatting logic in CalendarEventModel across DJ quotes and musician offers to ensure calendar events match job list pricing displays.

## Key files
- `test/features/calendar/data/models/calendar_event_model_test.dart`: Tests CalendarEventModel JSON factory methods (fromDjQuoteJson, fromMusicianJobOfferJson, fromMusicianExtJobOfferJson) for proper budgetDisplay deduction, tier adjustment, and payout formatting

## Public interface
- void main()

## Dependencies
- package:flutter_test/flutter_test.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/features/calendar/data/models/calendar_event_model.dart

## Open questions
- _none_
