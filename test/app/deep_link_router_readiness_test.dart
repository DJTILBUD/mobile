import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// ⚠️ WHY `NotificationsService._awaitRouterReady` EXISTS.
///
/// `GoRouter.push` builds the new stack on `routerDelegate.currentConfiguration`
/// **as of the call**, and that is `RouteMatchList.empty` until the `Router` widget
/// has mounted and parsed its initial location. `handleInitialMessage` runs from
/// `App.didChangeDependencies`, i.e. it can win that race on a cold start from a
/// tapped push.
///
/// Pushing onto an empty base does NOT throw. It produces a stack with no shell
/// underneath: no bottom nav, `canPop()` false (Android back exits the app), and the
/// screen vanishes on the next router refresh — which a cold start reliably fires when
/// the auth notifier sees the recovered session. These tests pin both halves so the
/// wait is not "simplified" away.
void main() {
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/instrumentalist/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/instrumentalist/home',
                builder: (_, _) => const Text('i-home'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/instrumentalist/profile',
                builder: (_, _) => const Text('i-profile'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin-messages',
        name: 'adminMessages',
        builder: (_, _) => const Text('admin-messages'),
      ),
    ],
  );

  testWidgets('pushing BEFORE the router has parsed a route loses the shell', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);

    expect(
      router.routerDelegate.currentConfiguration.matches,
      isEmpty,
      reason: 'precondition: this is the state _awaitRouterReady waits out',
    );

    router.go('/instrumentalist/profile');
    router.pushNamed('adminMessages');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('admin-messages'), findsOneWidget);
    expect(
      find.text('i-profile'),
      findsNothing,
      reason:
          'the go() was superseded and the push had no base — there is no shell tab '
          'underneath, so the bottom nav is gone and back has nowhere to go',
    );
    expect(router.routerDelegate.canPop(), isFalse);
  });

  testWidgets('waiting for the first route keeps the shell and a working back', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);

    // What _awaitRouterReady buys: the Router has mounted and parsed its initial
    // location before the deep link is applied.
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.matches, isNotEmpty);

    router.go('/instrumentalist/profile');
    router.pushNamed('adminMessages');
    await tester.pumpAndSettle();

    expect(find.text('admin-messages'), findsOneWidget);
    expect(router.routerDelegate.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(
      find.text('i-profile'),
      findsOneWidget,
      reason: 'back returns to the tab the notification targeted',
    );
  });
}
