import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/theme/app_theme.dart';
import 'package:dj_tilbud_app/features/auth/presentation/auth_provider.dart';
import 'package:dj_tilbud_app/features/auth/presentation/login_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/forgot_password_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.whenOrNull(
        data: (data) => data.session != null,
      ) ?? false;

      final isOnLogin = state.matchedLocation == '/login';
      final isOnForgotPassword = state.matchedLocation == '/forgot-password';

      if (isAuthenticated && (isOnLogin || isOnForgotPassword)) {
        return '/home';
      }

      if (!isAuthenticated && !isOnLogin && !isOnForgotPassword) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomeScreen(),
      ),
    ],
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DJ Tilbud',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Placeholder home screen — will be replaced with the real app shell.
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ Tilbud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Du er logget ind!'),
      ),
    );
  }
}
