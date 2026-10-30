# Module: test/core

Unit tests for the core utilities and shared UI components of the musician-facing app (dj_tilbud_app), locking down business rules such as the budget figure a DJ/musician sees on a job, saxophone high-season pricing used when quoting, phone-number handling for contacting a customer, which push-notification types clear a feed row, customer first-name parsing from lead forms, and the keyboard behavior of the sales-pitch textarea used when a musician writes or polishes their profile/quote.

## Key files
- `test/core/design_system/ds_input_keyboard_test.dart`: Regression test ensuring the DSInput textarea (used for the musician's 'Salgstale'/sales pitch, 100-450 chars) scrolls clear of the keyboard instead of being written through a one-line sliver.
- `test/core/notifications/extract_reference_id_test.dart`: Tests NotificationsService.extractReferenceId, which maps a push notification's type to the job/ext-job/quote/offer/conversation/message id so a tapped push marks the matching UserNotifications row read.
- `test/core/utils/birthday_person_age_test.dart`: Tests formatBirthdayPersonAge, formatting the free-text birthday-person age field from lead forms, mirroring the web app's useFormatBirthdayPersonAge.
- `test/core/utils/budget_utils_test.dart`: Parity tests for adjustBudgetForDjView and djBudgetFloorDkk, the job budget figure shown to a musician in the feed/quote flow, mirroring web-app/src/helpers/adjustBudgetForDjView.ts.
- `test/core/utils/customer_name_test.dart`: Tests customerFirstName, extracting a usable first name from the free-text lead_name field filled via WordPress customer forms.
- `test/core/utils/phone_utils_test.dart`: Tests dialablePhoneNumber, turning free-text lead_phone_number values into a valid sms: recipient for contacting the customer.
- `test/core/utils/planned_contact_test.dart`: Tests isPlannedContactDue, determining whether a musician's planned contact date with a customer is due.
- `test/core/utils/sax_high_season_test.dart`: Parity tests for isSaxHighSeason, isSaxSeasonPricingActive, calculateMusicianOfferPrice and calculateCustomerMusicianPrice, the saxophone high-season quoting/payout rules mirrored from the web app's pricing helpers.

## Public interface
- adjustBudgetForDjView
- djBudgetFloorDkk
- isSaxHighSeason
- isSaxSeasonPricingActive
- saxSeasonPricingStart
- saxHighSeasonExtraDates
- calculateMusicianOfferPrice
- calculateCustomerMusicianPrice
- dialablePhoneNumber
- customerFirstName
- formatBirthdayPersonAge
- isPlannedContactDue
- NotificationsService.extractReferenceId
- DSInput

## Dependencies
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/notifications/notifications_service.dart
- dj_tilbud_app/core/utils/birthday_person_age.dart
- dj_tilbud_app/core/utils/budget_utils.dart
- dj_tilbud_app/core/utils/customer_name.dart
- dj_tilbud_app/core/utils/phone_utils.dart
- dj_tilbud_app/core/utils/planned_contact.dart
- dj_tilbud_app/core/utils/sax_high_season.dart
- dj_tilbud_app/core/utils/musician_price.dart
- flutter_test
- flutter/material.dart

## Open questions
- sax_high_season_test.dart is truncated in the provided content — what further margin/parity assertions does it contain beyond the ~23% check shown?
- Several helpers (budget, sax pricing) are explicitly duplicated from a web-app TypeScript source of truth — how is drift between the two implementations detected outside of manually updated test fixtures?
- The DSInput keyboard fix is tied to a specific field (Salgstale/sales pitch); are there other long-text fields in the app (e.g. profile bio) that need the same scroll-padding guarantee but lack a test here?
