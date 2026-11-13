# Module: test/core

Unit and widget test suite verifying core business logic, utility helpers, notification reference ID parsing, and design system input behavior to maintain parity with web calculations and form rules.

## Key files
- `test/core/design_system/ds_input_keyboard_test.dart`: Widget tests verifying DSInput scrolling behavior and viewport height reservation above the virtual keyboard
- `test/core/notifications/extract_reference_id_test.dart`: Unit tests ensuring notification payloads correctly resolve target reference IDs across various job and message types
- `test/core/utils/budget_utils_test.dart`: Parity unit tests verifying DJ-facing budget deductions, tier fees, saxophonist deductions, and budget floor calculations against the web app
- `test/core/utils/sax_high_season_test.dart`: Parity unit tests validating high-season dates, cutoff periods, customer pricing, and musician payouts for saxophone bookings
- `test/core/utils/customer_name_test.dart`: Unit tests verifying parsing, whitespace trimming, and punctuation handling for customer first names
- `test/core/utils/phone_utils_test.dart`: Unit tests validating phone number sanitization and dialable SMS recipient string formatting
- `test/core/utils/birthday_person_age_test.dart`: Unit tests for formatting birthday person age strings and suffixes
- `test/core/utils/planned_contact_test.dart`: Unit tests verifying due date logic for planned customer contact dates

## Public interface
- void main()

## Dependencies
- package:flutter_test/flutter_test.dart
- package:flutter/material.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/utils/birthday_person_age.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/core/utils/customer_name.dart
- package:dj_tilbud_app/core/utils/phone_utils.dart
- package:dj_tilbud_app/core/utils/planned_contact.dart
- package:dj_tilbud_app/core/utils/sax_high_season.dart
- package:dj_tilbud_app/core/utils/musician_price.dart

## Open questions
- _none_
