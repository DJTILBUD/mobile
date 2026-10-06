import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dj_tilbud_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

/// Regression test for the crash a DJ hit on EVERY admin message they opened:
///
///   Bad state: Tried to use MarkAdminMessageReadNotifier after `dispose` was called.
///
/// `markAdminMessageReadProvider` is `autoDispose` and nothing watches it — the
/// screen only `ref.read`s the notifier — so Riverpod disposes this instance
/// while the Supabase round-trip is still in flight. Writing `state` after that
/// throws. The DB write itself always landed, which is why the message really
/// did get marked read while the app logged an unhandled exception.
///
/// This test drives the notifier directly (no container/provider needed) and
/// disposes it mid-flight, which is exactly the situation autoDispose creates.
void main() {
  test(
    'mark() survives being disposed mid-request and reports success',
    () async {
      final completer = Completer<void>();
      final notifier = MarkAdminMessageReadNotifier(
        _FakeProfileRepository(completer.future),
      );

      final future = notifier.mark(messageId: 1, userId: 'u1', isDj: true);

      // Riverpod disposes the un-listened autoDispose notifier before the
      // repository call comes back.
      notifier.dispose();
      completer.complete();

      // Unguarded, this line threw StateError instead of returning.
      expect(await future, isTrue);
    },
  );

  test('mark() reports failure instead of throwing when disposed', () async {
    final completer = Completer<void>();
    final notifier = MarkAdminMessageReadNotifier(
      _FakeProfileRepository(completer.future),
    );

    final future = notifier.mark(messageId: 1, userId: 'u1', isDj: true);
    notifier.dispose();
    completer.completeError(StateError('supabase down'));

    expect(await future, isFalse);
  });

  test('mark() still publishes state while it IS mounted', () async {
    final notifier = MarkAdminMessageReadNotifier(
      _FakeProfileRepository(Future<void>.value()),
    );
    expect(await notifier.mark(messageId: 1, userId: 'u1', isDj: true), isTrue);
    expect(notifier.state, isA<AsyncData<void>>());
  });
}

/// Only `markAdminMessageRead` is exercised; every other member is unreachable
/// here, so `noSuchMethod` stands in for the rest of the wide repository
/// interface rather than 30 lines of stubs.
class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._result);
  final Future<void> _result;

  @override
  Future<void> markAdminMessageRead({
    required int messageId,
    required String userId,
    required bool isDj,
  }) => _result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        '${invocation.memberName} not used in this test',
      );
}
