# Module: test/app

Unit and widget regression tests verifying deep-link routing, role resolution, GoRouter shell readiness, and keyboard dismiss bar view inset reservation in the mobile app.

## Key files
- `test/app/deep_link_role_resolution_test.dart`: Tests role derivation logic for notification payloads and route parameters using RoleCache and NotificationsService
- `test/app/deep_link_router_readiness_test.dart`: Widget tests guarding router readiness and shell tab persistence during push navigation cold starts
- `test/app/keyboard_dismiss_bar_reservation_test.dart`: Widget tests asserting proper layout insets calculation by ReserveKeyboardDismissBar across different keyboard states
- `test/app/route_extra_survives_keyboard_test.dart`: Regression widget tests ensuring ReserveKeyboardDismissBar preserves widget tree structure without unmounting the Router or dropping route extra parameters when the keyboard toggles

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
