# Module: test/core

Unit and widget tests for the core foundation layer of the DJTILBUD mobile app, validating design system component ergonomics and color contrast, push notification reference ID resolution, and business utility functions including budget adjustments, saxophone high-season pricing, phone sanitization, and equipment formatting.

## Key files
- `test/core/design_system/color_contrast_test.dart`: Verifies design system color tokens and contrast ratios (WCAG accessibility) across themes and text fills
- `test/core/design_system/ds_input_keyboard_test.dart`: Widget test verifying that tall multiline inputs (like quote sales pitches) scroll clear of the onscreen keyboard when tapped
- `test/core/notifications/extract_reference_id_test.dart`: Unit tests ensuring NotificationsService extracts the appropriate entity reference IDs from incoming push payloads
- `test/core/utils/budget_utils_test.dart`: Parity tests verifying DJ-facing budget calculations, deductions (sax, tier, equipment status), and floors match the web app helper logic
- `test/core/utils/sax_high_season_test.dart`: Tests calendar date rules and price calculations for saxophone high season across historical cutoff dates
- `test/core/utils/birthday_person_age_test.dart`: Unit tests for birthday person age string formatting and suffixing
- `test/core/utils/customer_name_test.dart`: Unit tests for parsing customer first names from form inputs
- `test/core/utils/equipment_description_test.dart`: Unit tests for serializing and parsing equipment description JSON payloads
- `test/core/utils/phone_utils_test.dart`: Unit tests validating dialable phone number extraction and sms: scheme sanitization
- `test/core/utils/planned_contact_test.dart`: Unit tests checking planned contact schedule due dates

## Public interface
- void main() in test/core/design_system/color_contrast_test.dart
- void main() in test/core/design_system/ds_input_keyboard_test.dart
- void main() in test/core/notifications/extract_reference_id_test.dart
- void main() in test/core/utils/birthday_person_age_test.dart
- void main() in test/core/utils/budget_utils_test.dart
- void main() in test/core/utils/customer_name_test.dart
- void main() in test/core/utils/equipment_description_test.dart
- void main() in test/core/utils/phone_utils_test.dart
- void main() in test/core/utils/planned_contact_test.dart
- void main() in test/core/utils/sax_high_season_test.dart

## Dependencies
- flutter/material.dart
- flutter_test/flutter_test.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/utils/birthday_person_age.dart
- package:dj_tilbud_app/core/utils/budget_utils.dart
- package:dj_tilbud_app/core/utils/customer_name.dart
- package:dj_tilbud_app/core/utils/equipment_description.dart
- package:dj_tilbud_app/core/utils/musician_price.dart
- package:dj_tilbud_app/core/utils/phone_utils.dart
- package:dj_tilbud_app/core/utils/planned_contact.dart
- package:dj_tilbud_app/core/utils/sax_high_season.dart

## Open questions
- _none_
