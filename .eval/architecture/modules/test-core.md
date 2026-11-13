# Module: test/core

Unit and widget test suites verifying core Flutter utility functions, notification reference resolution, design system keyboard interaction, and business logic calculations such as DJ budget deductions and saxophone high-season pricing parity.

## Key files
- `test/core/design_system/ds_input_keyboard_test.dart`: Widget tests verifying that tall DSInput text fields (such as quote sales pitches) scroll clear of the onscreen keyboard when tapped.
- `test/core/notifications/extract_reference_id_test.dart`: Unit tests verifying reference ID extraction across notification payloads for marking notification feed rows as read.
- `test/core/utils/budget_utils_test.dart`: Unit tests asserting parity between mobile and web business logic for DJ-facing budget adjustments, saxophone deductions, tier windows, and minimum price floors.
- `test/core/utils/sax_high_season_test.dart`: Unit tests verifying saxophone seasonal pricing dates, musician offer payout calculations, and customer pricing tables.
- `test/core/utils/phone_utils_test.dart`: Unit tests verifying phone number sanitation and formatting for SMS and dialer links.
- `test/core/utils/customer_name_test.dart`: Unit tests verifying extraction of customer first names from unstructured lead form input.
- `test/core/utils/birthday_person_age_test.dart`: Unit tests verifying age formatting and suffix conventions for birthday lead events.
- `test/core/utils/planned_contact_test.dart`: Unit tests verifying calculation of whether a planned contact date/time is due.

## Public interface
- main() in test/core/design_system/ds_input_keyboard_test.dart
- main() in test/core/notifications/extract_reference_id_test.dart
- main() in test/core/utils/birthday_person_age_test.dart
- main() in test/core/utils/budget_utils_test.dart
- main() in test/core/utils/customer_name_test.dart
- main() in test/core/utils/phone_utils_test.dart
- main() in test/core/utils/planned_contact_test.dart
- main() in test/core/utils/sax_high_season_test.dart

## Dependencies
- package:flutter/material.dart
- package:flutter_test/flutter_test.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/utils/birthday_person_age.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/core/utils/customer_name.dart
- package:dj_tilbud_app/core/utils/musician_price.dart
- package:dj_tilbud_app/core/utils/phone_utils.dart
- package:dj_tilbud_app/core/utils/planned_contact.dart
- package:dj_tilbud_app/core/utils/sax_high_season.dart

## Open questions
- _none_
