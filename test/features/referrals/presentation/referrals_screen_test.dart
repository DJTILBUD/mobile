import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral_terms.dart';
import 'package:dj_tilbud_app/features/referrals/domain/repositories/referrals_repository.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/providers/referrals_provider.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/screens/referrals_screen.dart';

/// Render tests for the "Henvis en kunde" screen: two tabs ("Ny henvisning" / "Mine
/// henvisninger"). Loading, empty, populated and error states must all lay out without an
/// exception (the ListView + DSSurface combination is exactly the kind of tree `flutter analyze`
/// cannot check), and the submit button must start disabled.
class FakeReferralsRepo implements ReferralsRepository {
  FakeReferralsRepo(this.items, {this.termsAccepted = true});
  final List<Referral> items;
  ReferralInput? submitted;
  bool termsAccepted;
  int acceptCalls = 0;

  @override
  Future<ReferralTermsStatus> fetchReferralTerms() async =>
      ReferralTermsStatus(accepted: termsAccepted);

  @override
  Future<ReferralTermsStatus> acceptReferralTerms() async {
    acceptCalls++;
    termsAccepted = true;
    return const ReferralTermsStatus(accepted: true);
  }

  @override
  Future<List<Referral>> fetchMyReferrals() async => items;

  @override
  Future<Referral> createReferral(ReferralInput input) async {
    submitted = input;
    return items.first;
  }
}

Widget harness(FakeReferralsRepo repo, {AsyncValue<List<Referral>>? list}) {
  return ProviderScope(
    overrides: [
      referralsRepositoryProvider.overrideWithValue(repo),
      if (list != null)
        referralsProvider.overrideWith(
          (ref) => list.when(
            data: (d) async => d,
            error: (e, st) => Future<List<Referral>>.error(e, st),
            loading: () => Completer<List<Referral>>().future,
          ),
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: const ReferralsScreen(role: MusicianRole.dj),
    ),
  );
}

final _closed = Referral(
  id: 1,
  type: ReferralType.djReferral,
  status: ReferralStatus.closed,
  rewardDkk: 500,
  createdAt: DateTime(2026, 9, 14),
  payoutStatus: 'paid',
  job: ReferralJob(
    id: 9,
    leadName: 'Mette Hansen',
    date: DateTime(2026, 11, 21),
    status: 'ready_for_billing',
    eventType: 'Bryllup',
  ),
);

void main() {
  // The form tab is taller than the default 600px test viewport; a lazy ListView never builds
  // what is out of view, so the whole page gets a tall surface.
  Future<void> tall(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  // TabBarView only builds the current page; "Mine henvisninger" content isn't in the tree until
  // the tab is actually switched to.
  Future<void> openMyReferralsTab(WidgetTester tester) async {
    await tester.tap(find.text('Mine henvisninger'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows both tabs, the bold reward line, and starts on "Ny henvisning" with a disabled submit button',
    (tester) async {
      await tall(tester);
      await tester.pumpWidget(harness(FakeReferralsRepo([])));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ny henvisning'), findsWidgets);
      expect(find.text('Mine henvisninger'), findsWidgets);
      expect(
        find.text('Tjen 500 kr., når jobbet er gennemført.'),
        findsOneWidget,
      );
      final button = tester.widget<DSButton>(
        find.widgetWithText(DSButton, 'Giv jobbet videre'),
      );
      expect(button.enabled, isFalse);
    },
  );

  testWidgets('shows the empty state on "Mine henvisninger"', (tester) async {
    await tall(tester);
    await tester.pumpWidget(harness(FakeReferralsRepo([])));
    await tester.pumpAndSettle();
    await openMyReferralsTab(tester);
    expect(tester.takeException(), isNull);
    expect(
      find.text('Du har ikke givet nogen jobs videre endnu.'),
      findsOneWidget,
    );
  });

  testWidgets('renders a closed referral with its job ref and reward line', (
    tester,
  ) async {
    await tall(tester);
    await tester.pumpWidget(harness(FakeReferralsRepo([_closed])));
    await tester.pumpAndSettle();
    await openMyReferralsTab(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Mette Hansen'), findsOneWidget);
    expect(find.text('#E9'), findsOneWidget);
    expect(find.text('Gennemført'), findsOneWidget);
    expect(find.text('500 kr. er udbetalt'), findsOneWidget);
  });

  testWidgets('renders the error state', (tester) async {
    await tall(tester);
    await tester.pumpWidget(
      harness(
        FakeReferralsRepo([]),
        list: AsyncValue.error(Exception('x'), StackTrace.empty),
      ),
    );
    await tester.pumpAndSettle();
    await openMyReferralsTab(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Kunne ikke hente dine henvisninger.'), findsOneWidget);
  });

  testWidgets('renders the loading state', (tester) async {
    await tall(tester);
    await tester.pumpWidget(
      harness(FakeReferralsRepo([]), list: const AsyncValue.loading()),
    );
    await tester.pumpAndSettle();
    // NOT openMyReferralsTab/pumpAndSettle here: once the tab shows an indeterminate
    // CircularProgressIndicator its animation never settles, so pumpAndSettle would hang. A tap
    // plus enough pumps to finish the tab-switch transition is enough to reach the loading state.
    await tester.tap(find.text('Mine henvisninger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // The referral terms must be accepted before the form and the list show.
  testWidgets('shows the terms gate (no tabs) until the terms are accepted', (
    tester,
  ) async {
    await tall(tester);
    await tester.pumpWidget(
      harness(FakeReferralsRepo([_closed], termsAccepted: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vilkår for henvisninger'), findsOneWidget);
    expect(find.text('Læs vilkårene for henvisninger'), findsOneWidget);
    expect(find.text('Jeg har læst og accepterer vilkårene'), findsOneWidget);
    expect(find.text('Ny henvisning'), findsNothing);
    expect(find.text('Mine henvisninger'), findsNothing);
  });

  testWidgets('accepting the terms records it and opens the referral tabs', (
    tester,
  ) async {
    await tall(tester);
    final repo = FakeReferralsRepo([_closed], termsAccepted: false);
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // The button does nothing until the tick box is ticked.
    await tester.tap(find.text('Jeg har læst og accepterer vilkårene'));
    await tester.pumpAndSettle();
    expect(repo.acceptCalls, 0);

    await tester.tap(find.text('Jeg har læst vilkårene for henvisninger'));
    await tester.pump();
    await tester.tap(find.text('Jeg har læst og accepterer vilkårene'));
    await tester.pumpAndSettle();

    expect(repo.acceptCalls, 1);
    expect(find.text('Ny henvisning'), findsOneWidget);
    expect(find.text('Vilkår for henvisninger'), findsNothing);
  });
}
