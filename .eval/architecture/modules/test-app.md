# Module: test/app

Regression and unit test suite verifying app-level routing stability, deep-link role resolution, router readiness on cold starts, and keyboard dismiss bar view inset reservation.

## Key files
- `test/app/deep_link_role_resolution_test.dart`: Tests role determination and fallback via RoleCache and NotificationsService when processing deep links and notification payloads.
- `test/app/deep_link_router_readiness_test.dart`: Tests that waiting for GoRouter to mount and parse its initial configuration preserves the shell route and navigation stack upon push/deep link.
- `test/app/keyboard_dismiss_bar_reservation_test.dart`: Tests ReserveKeyboardDismissBar bottom viewInsets reservation behavior when the keyboard is open, closed, or suppressed.
- `test/app/route_extra_survives_keyboard_test.dart`: Tests that ReserveKeyboardDismissBar maintains widget tree structure without unmounting the Router or dropping GoRouter state.extra when the keyboard toggles.

## Public interface
- void main()

## Dependencies
- package:dj_tilbud_app/app.dart
- package:dj_tilbud_app/core/config/role_cache.dart
- package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:flutter_test/flutter_test.dart
- package:go_router/go_router.dart
- package:shared_preferences/shared_preferences.dart

## Open questions
- _none_
