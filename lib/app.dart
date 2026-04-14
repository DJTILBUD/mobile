import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/navigation/main_shell.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/theme/app_theme.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/conversation_detail_screen.dart';
import 'package:dj_tilbud_app/features/featured_jobs/presentation/screens/featured_jobs_screen.dart';
import 'package:dj_tilbud_app/features/featured_jobs/presentation/screens/ext_job_detail_screen.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/jobs_shell_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/dj_quote_form_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/instrumentalist_offer_form_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/quote_detail_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/service_offer_detail_screen.dart';
import 'package:dj_tilbud_app/core/design_system/showcase_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/reviews_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/media_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/standard_messages_screen.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/dj_job_filters_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/payment_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/profile_preview_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/admin_messages_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/feedback_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/faq_screen.dart';
import 'package:dj_tilbud_app/core/widgets/dev_env_banner.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_banner.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Converts Supabase auth state stream into a [Listenable]
/// so GoRouter can react to changes without being rebuilt.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.initialSession) {
        if (event.session != null) {
          NotificationsService.registerToken();
        }
      }
      if (event.event == AuthChangeEvent.signedOut) {
        RoleCache.clear();
      }
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isAuthenticated = supabase.auth.currentSession != null;
      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/login' || loc == '/forgot-password' || loc == '/design-system' || loc == '/profile-setup';

      if (!isAuthenticated && !isPublicRoute) return '/login';

      // Restore session: redirect away from login if already authenticated
      if (isAuthenticated && loc == '/login') {
        final role = RoleCache.role;
        if (role == MusicianRole.dj) return '/dj/home';
        if (role == MusicianRole.instrumentalist) return '/instrumentalist/home';
        // No cached role — sign out and re-authenticate
        supabase.auth.signOut();
        return null;
      }

      return null;
    },
    routes: [
      // ── Auth routes ──
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/design-system',
        name: AppRoutes.designSystem,
        builder: (context, state) => const DesignSystemShowcase(),
      ),

      // ── DJ shell (4 bottom tabs) ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          role: MusicianRole.dj,
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dj/home',
              name: AppRoutes.djHome,
              builder: (context, state) =>
                  const JobsShellScreen(role: MusicianRole.dj),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dj/featured',
              name: AppRoutes.featuredJobs,
              builder: (context, state) => const FeaturedJobsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dj/chat',
              name: '${AppRoutes.chat}-dj',
              builder: (context, state) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dj/profile',
              name: '${AppRoutes.profile}-dj',
              builder: (context, state) => const ProfileScreen(role: MusicianRole.dj),
            ),
          ]),
        ],
      ),

      // ── Instrumentalist shell (3 bottom tabs) ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          role: MusicianRole.instrumentalist,
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/instrumentalist/home',
              name: AppRoutes.instrumentalistHome,
              builder: (context, state) =>
                  const JobsShellScreen(role: MusicianRole.instrumentalist),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/instrumentalist/chat',
              name: '${AppRoutes.chat}-instrumentalist',
              builder: (context, state) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/instrumentalist/profile',
              name: '${AppRoutes.profile}-instrumentalist',
              builder: (context, state) => const ProfileScreen(role: MusicianRole.instrumentalist),
            ),
          ]),
        ],
      ),

      // ── Detail / form routes (push on top, no bottom nav) ──
      GoRoute(
        path: '/job-detail',
        name: AppRoutes.jobDetail,
        builder: (context, state) {
          final job = state.extra as Job;
          return JobDetailScreen(job: job);
        },
      ),
      GoRoute(
        path: '/dj/quote-form',
        name: AppRoutes.djQuoteForm,
        builder: (context, state) {
          final job = state.extra as Job;
          return DjQuoteFormScreen(job: job);
        },
      ),
      GoRoute(
        path: '/instrumentalist/offer-form',
        name: AppRoutes.instrumentalistOfferForm,
        builder: (context, state) {
          final job = state.extra as Job;
          return InstrumentalistOfferFormScreen(job: job);
        },
      ),
      GoRoute(
        path: '/quote-detail',
        name: AppRoutes.quoteDetail,
        builder: (context, state) {
          final quote = state.extra as DjQuote;
          return QuoteDetailScreen(quote: quote);
        },
      ),
      GoRoute(
        path: '/service-offer-detail',
        name: AppRoutes.serviceOfferDetail,
        builder: (context, state) {
          final offer = state.extra as ServiceOffer;
          return ServiceOfferDetailScreen(offer: offer);
        },
      ),

      GoRoute(
        path: '/ext-job-detail',
        name: AppRoutes.extJobDetail,
        builder: (context, state) {
          final extJob = state.extra as ExtJob;
          return ExtJobDetailScreen(extJob: extJob);
        },
      ),
      GoRoute(
        path: '/conversation-detail',
        name: AppRoutes.conversationDetail,
        builder: (context, state) {
          final conversation = state.extra as Conversation;
          return ConversationDetailScreen(conversation: conversation);
        },
      ),

      // ── Profile sub-screens ──
      GoRoute(
        path: '/edit-profile',
        name: AppRoutes.editProfile,
        builder: (context, state) {
          final role = state.extra as MusicianRole;
          return EditProfileScreen(role: role);
        },
      ),
      GoRoute(
        path: '/reviews',
        name: AppRoutes.reviews,
        builder: (context, state) {
          final role = state.extra as MusicianRole;
          return ReviewsScreen(role: role);
        },
      ),
      GoRoute(
        path: '/media',
        name: AppRoutes.media,
        builder: (context, state) => const MediaScreen(),
      ),
      GoRoute(
        path: '/standard-messages',
        name: AppRoutes.standardMessages,
        builder: (context, state) => const StandardMessagesScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: AppRoutes.payment,
        builder: (context, state) {
          final role = state.extra as MusicianRole;
          return PaymentScreen(role: role);
        },
      ),
      GoRoute(
        path: '/dj/job-filters',
        name: AppRoutes.djJobFilters,
        builder: (context, state) {
          final djId = state.extra as String;
          return DjJobFiltersScreen(djId: djId);
        },
      ),
      GoRoute(
        path: '/profile-preview',
        name: AppRoutes.profilePreview,
        builder: (context, state) {
          final role = (state.extra as MusicianRole?) ?? MusicianRole.dj;
          return ProfilePreviewScreen(role: role);
        },
      ),
      GoRoute(
        path: '/dj/calendar',
        name: AppRoutes.djCalendar,
        builder: (context, state) =>
            const CalendarScreen(role: MusicianRole.dj),
      ),
      GoRoute(
        path: '/instrumentalist/calendar',
        name: AppRoutes.instrumentalistCalendar,
        builder: (context, state) =>
            const CalendarScreen(role: MusicianRole.instrumentalist),
      ),
      GoRoute(
        path: '/admin-messages',
        name: AppRoutes.adminMessages,
        builder: (context, state) {
          final role = state.extra as MusicianRole;
          return AdminMessagesScreen(role: role);
        },
      ),
      GoRoute(
        path: '/feedback',
        name: AppRoutes.feedback,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/faq',
        name: AppRoutes.faq,
        builder: (context, state) => const FaqScreen(),
      ),
    ],
  );
});

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _notificationsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationsReady) {
      _notificationsReady = true;
      final router = ref.read(routerProvider);
      NotificationsService.setupNavigationHandlers(router);
      NotificationsService.handleInitialMessage(router);
      // Show in-app banner when the app is in the foreground
      FirebaseMessaging.onMessage.listen((message) {
        ref.read(inAppNotificationProvider.notifier).state = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DJ Tilbud',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            child!,
            const InAppNotificationBanner(),
            const DevEnvBanner(),
          ],
        ),
      ),
    );
  }
}
