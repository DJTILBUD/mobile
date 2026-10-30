# Module: test/app

Regression tests for the app's root shell: routing/deep-link stability (role resolution for notification deep links, router readiness before pushing routes) and a global UI fix that reserves space above the keyboard-dismiss bar so routed screens and their state.extra survive keyboard open/close without losing navigation data.

## Key files
- `test/app/deep_link_role_resolution_test.dart`: Tests roleFromExtra and NotificationsService.effectiveRole resolve a musician's role for role-only deep-link routes using RoleCache when state.extra or the notification payload's role is missing/dropped/wrongly typed.
- `test/app/deep_link_router_readiness_test.dart`: Tests that pushing a named route before GoRouter has parsed its initial location loses the shell/back-navigation, and that waiting for router readiness preserves the shell and working back navigation.
- `test/app/keyboard_dismiss_bar_reservation_test.dart`: Tests that ReserveKeyboardDismissBar reserves exactly the keyboard-dismiss bar's height when the bar is shown, reserves nothing when it's suppressed (e.g. chat screen) or hidden, and that a Scaffold body lays out above the bar.
- `test/app/route_extra_survives_keyboard_test.dart`: Tests that the router widget is never unmounted when the keyboard opens/closes (tree shape must stay stable) and that a pushed route's state.extra survives a keyboard-triggered rebuild.

## Public interface
- _none_

## Dependencies
- dj_tilbud_app/app.dart
- dj_tilbud_app/core/config/role_cache.dart
- dj_tilbud_app/core/notifications/notifications_service.dart
- dj_tilbud_app/features/auth/domain/entities/musician_role.dart
- dj_tilbud_app/core/notifications/in_app_notification_provider.dart
- flutter_test
- flutter_riverpod
- go_router
- shared_preferences

## Open questions
- What AI/agent logic (e.g. profile polishing, sales pitch generation) exists elsewhere in the app, since none of these tests touch it directly?
- Are there other role-only routes beyond those implied by roleFromExtra that need similar deep-link regression coverage?
