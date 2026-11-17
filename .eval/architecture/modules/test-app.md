# Module: test/app

Provides unit and widget regression tests for the core application layer, verifying deep-link role resolution, router readiness on cold starts, and keyboard dismiss bar view inset reservation to prevent route extra data loss and UI obstruction.

## Key files
- `test/app/deep_link_role_resolution_test.dart`: Tests role determination for deep links and notifications via RoleCache fallback when router extra is missing or untyped.
- `test/app/deep_link_router_readiness_test.dart`: Tests that deep link navigation waits for router readiness and initial location parsing so navigation shells and back stacks are preserved.
- `test/app/keyboard_dismiss_bar_reservation_test.dart`: Tests ReserveKeyboardDismissBar to verify viewInsets.bottom expansion and prevention of input field occlusion by the dismiss bar.
- `test/app/route_extra_survives_keyboard_test.dart`: Tests that widget tree hierarchy remains stable during keyboard opening to avoid router remounting and dropped GoRouter route extra data.

## Public interface
- main() in test/app/deep_link_role_resolution_test.dart (test suite for roleFromExtra and NotificationsService.effectiveRole)
- main() in test/app/deep_link_router_readiness_test.dart (test suite for GoRouter push and shell preservation during cold starts)
- main() in test/app/keyboard_dismiss_bar_reservation_test.dart (test suite for ReserveKeyboardDismissBar)
- main() in test/app/route_extra_survives_keyboard_test.dart (test suite for route extra persistence during keyboard view insets changes)

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
