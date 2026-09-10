import 'package:dj_tilbud_app/features/first_win/domain/entities/first_win_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MusicianVariant.rpcValue', () {
    // The DB function raises `Invalid variant for musician: <x>` for anything
    // else, and the RPC error was silently swallowed — which is how the popup
    // ended up reappearing on every app launch. Pin the exact strings.
    test('matches the strings mark_first_win_shown accepts', () {
      expect(MusicianVariant.withDj.rpcValue, 'with_dj');
      expect(MusicianVariant.solo.rpcValue, 'solo');
    });

    test('is not the Dart enum name', () {
      expect(
        MusicianVariant.withDj.rpcValue,
        isNot(MusicianVariant.withDj.name),
      );
    });
  });

  group('pendingMusicianVariant', () {
    test('nothing pending → null', () {
      expect(
        pendingMusicianVariant(
          withDjPending: false,
          soloPending: false,
          hasWithDjWin: true,
          hasSoloWin: true,
        ),
        isNull,
      );
    });

    test('pending but no matching win → null', () {
      expect(
        pendingMusicianVariant(
          withDjPending: true,
          soloPending: true,
          hasWithDjWin: false,
          hasSoloWin: false,
        ),
        isNull,
      );
    });

    test('a solo win never shows the with-DJ walkthrough', () {
      expect(
        pendingMusicianVariant(
          withDjPending: true,
          soloPending: true,
          hasWithDjWin: false,
          hasSoloWin: true,
        ),
        MusicianVariant.solo,
      );
    });

    test('a with-DJ win never shows the solo walkthrough', () {
      expect(
        pendingMusicianVariant(
          withDjPending: true,
          soloPending: true,
          hasWithDjWin: true,
          hasSoloWin: false,
        ),
        MusicianVariant.withDj,
      );
    });

    test('with_dj takes priority when both are pending and both are won', () {
      expect(
        pendingMusicianVariant(
          withDjPending: true,
          soloPending: true,
          hasWithDjWin: true,
          hasSoloWin: true,
        ),
        MusicianVariant.withDj,
      );
    });

    test('already seen with_dj → the solo popup is still owed', () {
      expect(
        pendingMusicianVariant(
          withDjPending: false,
          soloPending: true,
          hasWithDjWin: true,
          hasSoloWin: true,
        ),
        MusicianVariant.solo,
      );
    });
  });
}
