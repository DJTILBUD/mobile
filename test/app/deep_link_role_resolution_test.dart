import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two ways a notification deep-link used to land on the wrong screen:
///
/// 1. `state.extra` is dropped by any router re-parse (Android activity restore, a
///    Router remount, a push issued before the Router mounted). Every role-only route
///    then fell into `_MissingRouteDataScreen` — "Mangler data".
/// 2. `notify-admin-message` sends ONE multicast for `target_audience: 'both'`, so the
///    payload carries no `role` at all. Reading that as "dj" put musicians in the DJ
///    shell with the DJ's admin-message list.
///
/// Both are now resolved from `RoleCache`, which `main()` loads before `runApp`.

Future<void> _signInAs(MusicianRole? role) async {
  SharedPreferences.setMockInitialValues(
    role == null ? {} : {'djtilbud_user_role': role.name},
  );
  await RoleCache.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('roleFromExtra (role-only routes)', () {
    test('an explicit extra always wins over the cache', () async {
      await _signInAs(MusicianRole.dj);
      expect(
        roleFromExtra(MusicianRole.instrumentalist),
        MusicianRole.instrumentalist,
      );
    });

    test('a dropped extra resolves to the signed-in role, not "Mangler data"', () async {
      await _signInAs(MusicianRole.instrumentalist);
      expect(roleFromExtra(null), MusicianRole.instrumentalist);
    });

    test('a wrongly-typed extra (the raw role String) also resolves', () async {
      // The original admin_message bug passed data['role'] straight through as a
      // String; the route's `is! MusicianRole` test then showed "Mangler data".
      await _signInAs(MusicianRole.dj);
      expect(roleFromExtra('musician'), MusicianRole.dj);
    });

    test('no cached role (signed out) still yields the fallback screen', () async {
      await _signInAs(null);
      expect(roleFromExtra(null), isNull);
    });
  });

  group('NotificationsService.effectiveRole', () {
    test('uses the payload role when it is present', () async {
      await _signInAs(MusicianRole.dj);
      expect(
        NotificationsService.effectiveRole({
          'type': 'admin_message',
          'role': 'musician',
        }),
        'musician',
      );
    });

    test('a role-less admin_message resolves to the musician, not "dj"', () async {
      // target_audience: 'both' → the Edge Function omits `role` entirely.
      await _signInAs(MusicianRole.instrumentalist);
      expect(
        NotificationsService.effectiveRole({'type': 'admin_message'}),
        'musician',
      );
    });

    test('a role-less payload resolves to dj for a signed-in DJ', () async {
      await _signInAs(MusicianRole.dj);
      expect(
        NotificationsService.effectiveRole({'type': 'admin_message'}),
        'dj',
      );
    });

    test('a junk role value falls back to the cache', () async {
      await _signInAs(MusicianRole.instrumentalist);
      expect(
        NotificationsService.effectiveRole({
          'type': 'admin_message',
          'role': 'both',
        }),
        'musician',
      );
    });

    test('null when nothing knows the role', () async {
      await _signInAs(null);
      expect(
        NotificationsService.effectiveRole({'type': 'admin_message'}),
        isNull,
      );
    });
  });
}
