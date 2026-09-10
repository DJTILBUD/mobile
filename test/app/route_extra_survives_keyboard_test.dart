import 'package:dj_tilbud_app/app.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// ⚠️ THE 1.0.37 OUTAGE. Every user, every screen: tapping any text field replaced the page with
/// 'Siden "..." kunne ikke åbnes, fordi nødvendige data mangler'.
///
/// Cause: [ReserveKeyboardDismissBar] returned `child` bare when the keyboard was closed and
/// `MediaQuery(child: child)` when it was open. `MaterialApp.router` hands its `builder` the
/// **Router widget itself**, so that toggle moved the Router to a different depth, Flutter
/// unmounted it, and the fresh Router re-parsed the stack from the URL. go_router carries no
/// `extra` through a re-parse (no `extraCodec`), so every pushed route rebuilt with `extra == null`
/// and fell into its `_MissingRouteDataScreen`.
///
/// The rule: **a wrapper above the router must never change the tree SHAPE — vary the value, keep
/// the wrapper.** The first test below pins exactly that and fails against the 1.0.37 code.

void main() {
  testWidgets('the router child is never unmounted when the keyboard opens', (
    tester,
  ) async {
    // Stands in for the Router: MaterialApp.router passes it to `builder` as `child`, and it is
    // remounting that loses `extra`. Comparing State identity is the direct assertion — a new
    // State object here means a new Router in the real app, which means a re-parsed stack.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppressKeyboardDismissBarProvider.overrideWith((ref) => false),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: const ReserveKeyboardDismissBar(child: _RouterStandIn()),
          ),
        ),
      ),
    );

    final before = tester.state<_RouterStandInState>(find.byType(_RouterStandIn));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppressKeyboardDismissBarProvider.overrideWith((ref) => false),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: const ReserveKeyboardDismissBar(child: _RouterStandIn()),
          ),
        ),
      ),
    );

    final after = tester.state<_RouterStandInState>(find.byType(_RouterStandIn));

    expect(
      identical(before, after),
      isTrue,
      reason:
          'the child was unmounted and rebuilt — in the real app that is the Router, and the '
          'fresh Router re-parses the stack and drops every route\'s extra (the 1.0.37 outage)',
    );
    expect(after.mountCount, 1);
  });

  testWidgets('route extra survives the keyboard opening', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/form',
          name: 'form',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! String) {
              return const Scaffold(body: Text('MISSING DATA'));
            }
            return Scaffold(body: Text('form:$extra'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    Widget app(double keyboardHeight) => ProviderScope(
      overrides: [
        suppressKeyboardDismissBarProvider.overrideWith((ref) => false),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        ),
        child: MaterialApp.router(
          routerConfig: router,
          builder:
              (context, child) =>
                  Stack(children: [ReserveKeyboardDismissBar(child: child!)]),
        ),
      ),
    );

    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();

    router.pushNamed('form', extra: 'job-42');
    await tester.pumpAndSettle();
    expect(find.text('form:job-42'), findsOneWidget);

    // The DJ taps the price field: viewInsets.bottom goes from 0 to the keyboard height.
    // Nothing about the route changed, so the screen must still be there.
    await tester.pumpWidget(app(300));
    await tester.pumpAndSettle();

    expect(
      find.text('MISSING DATA'),
      findsNothing,
      reason:
          'the router remounted and lost state.extra — the 1.0.37 quote-form outage',
    );
    expect(find.text('form:job-42'), findsOneWidget);
  });
}

class _RouterStandIn extends StatefulWidget {
  const _RouterStandIn();

  @override
  State<_RouterStandIn> createState() => _RouterStandInState();
}

class _RouterStandInState extends State<_RouterStandIn> {
  int mountCount = 0;

  @override
  void initState() {
    super.initState();
    mountCount++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
