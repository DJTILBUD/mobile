import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/performer_stats.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/stats_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/stats_screen.dart';

/// Render tests for the stats screen.
///
/// These exist because `flutter analyze` cannot see layout errors: the first cut of
/// this screen put `CrossAxisAlignment.stretch` on a Row inside a ListView, which
/// analyses clean but throws "BoxConstraints forces an infinite height" the moment
/// it is rendered. `tester.takeException()` is the assertion that catches that class
/// of bug, so keep it on every state below.
void main() {
  Widget harness(
    List<StatEntry> entries,
    MusicianRole role, {
    int excluded = 0,
    bool hasSession = true,
  }) {
    return ProviderScope(
      overrides: [
        // Overriding the source cascades into performerStats/statsYears providers.
        statEntriesProvider.overrideWith(
          (ref, _) => AsyncValue.data(
            StatEntries(entries: entries, excluded: excluded),
          ),
        ),
        statsYearProvider.overrideWith(
          (ref) => null,
        ), // "Alle" — no date coupling
        // The real impl reads supabase.auth, which is not booted in tests.
        hasSessionProvider.overrideWith((ref) => hasSession),
      ],
      child: MaterialApp(home: StatsScreen(role: role)),
    );
  }

  final entries = [
    StatEntry(
      date: DateTime(2026, 6, 1),
      payoutDkk: 12400,
      eventType: 'Bryllup',
      region: 'Hovedstaden',
      guestsAmount: 95,
      genres: const ['Pop'],
    ),
    StatEntry(
      date: DateTime(2026, 5, 3),
      payoutDkk: 7800,
      eventType: 'Firmafest',
      region: 'Fyn',
      guestsAmount: 60,
    ),
  ];

  testWidgets('renders a populated page with no layout exception', (
    tester,
  ) async {
    await tester.pumpWidget(harness(entries, MusicianRole.dj));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Statistik'), findsOneWidget);
    // Summary + sections are present.
    expect(find.text('Tjent i alt'), findsOneWidget);
    expect(find.text('Kommende'), findsOneWidget);
    expect(find.text('Indtjening måned for måned'), findsOneWidget);
    expect(find.text('Eventtyper'), findsOneWidget);
    expect(find.text('Hvor i landet'), findsOneWidget);
    // Danish thousands grouping, summed across both (past) entries: 12400 + 7800.
    expect(find.text('20.200 kr.'), findsOneWidget);
  });

  testWidgets('a future booking reads as "kommende", not as earned', (
    tester,
  ) async {
    // The bug this guards: ready_for_billing does NOT mean played. A job dated far
    // ahead must land in "Kommende" and be tagged in the month list — never counted
    // as "Tjent".
    final future = DateTime.now().add(const Duration(days: 120));
    await tester.pumpWidget(
      harness([
        StatEntry(
          date: DateTime.now().subtract(const Duration(days: 30)),
          payoutDkk: 5000,
          eventType: 'Bryllup',
          region: 'Fyn',
        ),
        StatEntry(
          date: future,
          payoutDkk: 4000,
          eventType: 'Firmafest',
          region: 'Fyn',
        ),
      ], MusicianRole.dj),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Each amount appears in its summary card AND its month row, hence findsWidgets.
    // The load-bearing assertion is the absence of 9.000: the two must never be
    // summed into one "Tjent" figure.
    expect(find.text('5.000 kr.'), findsWidgets); // Tjent = the played one
    expect(find.text('4.000 kr.'), findsWidgets); // Kommende = the one ahead
    expect(find.text('9.000 kr.'), findsNothing);
    expect(find.text('1 spillet'), findsOneWidget);
    expect(find.text('1 booket'), findsOneWidget);
    // The legend is what makes the two bar colours mean anything — it must appear
    // whenever there is upcoming money to distinguish.
    expect(find.text('Spillet'), findsOneWidget); // legend swatch
    expect(find.text('Kommende'), findsWidgets); // legend + summary card
    // The explainer spells out why the two differ.
    expect(find.textContaining('endnu ikke spillet'), findsOneWidget);
  });

  testWidgets('renders for a saxophonist too', (tester) async {
    await tester.pumpWidget(harness(entries, MusicianRole.instrumentalist));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Statistik'), findsOneWidget);
  });

  // Regression: on sign-out this pushed screen rebuilt before the router redirected,
  // and the session-scoped providers (which resolve currentUser!.id) threw
  // "Null check operator used on a null value". It must render nothing instead.
  testWidgets('renders nothing, and does not throw, once signed out', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(entries, MusicianRole.dj, hasSession: false),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Statistik'), findsNothing);
  });

  testWidgets(
    'hides the legend when nothing is upcoming (no grey bars to explain)',
    (tester) async {
      // `entries` are all in the past, so every bar is lime and a key would be noise.
      await tester.pumpWidget(harness(entries, MusicianRole.dj));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Spillet'), findsNothing); // legend swatch absent
    },
  );

  testWidgets('renders the empty state with no exception', (tester) async {
    await tester.pumpWidget(harness(const [], MusicianRole.dj));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ingen spillede jobs endnu'), findsOneWidget);
  });

  // The note lives at the bottom of a ListView, which only builds what is visible,
  // so these have to scroll to it rather than assert on a fresh pump.
  testWidgets('shows the missing-payout note when something was excluded', (
    tester,
  ) async {
    await tester.pumpWidget(harness(entries, MusicianRole.dj, excluded: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.textContaining('honorar-data'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('honorar-data'), findsOneWidget);
  });

  testWidgets('hides the missing-payout note when nothing was excluded', (
    tester,
  ) async {
    await tester.pumpWidget(harness(entries, MusicianRole.dj));
    await tester.pumpAndSettle();

    // Scroll to the very bottom so "not found" means genuinely absent, not just
    // un-built below the fold.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('honorar-data'), findsNothing);
  });

  testWidgets('survives a narrow screen (three summary cards in one row)', (
    tester,
  ) async {
    // The infinite-height bug was in the 3-card summary Row; check a small phone
    // where those cards are tightest.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(entries, MusicianRole.dj));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
