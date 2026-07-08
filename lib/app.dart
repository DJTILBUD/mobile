import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/navigation/main_shell.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/theme/app_theme.dart';
import 'package:dj_tilbud_app/core/theme/theme_provider.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/first_win/presentation/providers/first_win_provider.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/login_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dj_tilbud_app/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:dj_tilbud_app/features/chat/domain/entities/conversation.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/conversation_detail_screen.dart';
import 'package:dj_tilbud_app/features/chat/data/datasources/admin_support_datasource.dart';
import 'package:dj_tilbud_app/features/chat/presentation/screens/admin_support_thread_screen.dart';
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
import 'package:dj_tilbud_app/features/profile/presentation/screens/my_content_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/job_content_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/standard_messages_screen.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/dj_job_filters_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/musician_job_filters_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/payment_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/profile_preview_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/admin_messages_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/feedback_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/faq_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/terms_screen.dart';
import 'package:dj_tilbud_app/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:dj_tilbud_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dj_tilbud_app/core/widgets/dev_env_banner.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_banner.dart';
import 'package:dj_tilbud_app/core/notifications/in_app_notification_provider.dart';
import 'package:dj_tilbud_app/features/app_config/presentation/widgets/update_gate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';

/// Tracks whether the current user has completed onboarding so GoRouter
/// can gate the rest of the app until onboarding_completed_at is set.
class _OnboardingNotifier extends ChangeNotifier {
  bool _completed = false;
  bool _resolved = false;

  bool get onboardingCompleted => _completed;

  /// True once we actually know this session's role + onboarding status.
  /// Until then the router must NOT route to /profile-setup or /onboarding,
  /// otherwise logging in briefly flashes the role-selection screen while the
  /// role is still being cached.
  bool get resolved => _resolved;

  Future<void> checkStatus() async {
    final session = supabase.auth.currentSession;
    if (session == null || RoleCache.role == null) {
      // Can't check yet — role not cached. Leave gate closed AND unresolved;
      // the explicit re-check after RoleCache.save() (or the auth listener)
      // will retry once the role is known.
      return;
    }
    try {
      final table = RoleCache.role == MusicianRole.dj ? 'DjInfos' : 'Musicians';
      final data =
          await supabase
              .from(table)
              .select('onboarding_completed_at')
              .eq('id', session.user.id)
              .maybeSingle();
      _completed = data?['onboarding_completed_at'] != null;
    } catch (_) {
      // Network error — leave current state unchanged so we don't
      // accidentally gate a user who has already completed onboarding.
    }
    // Role was known and we attempted the lookup → status is now resolved.
    _resolved = true;
    notifyListeners();
  }

  void markComplete() {
    _completed = true;
    _resolved = true;
    notifyListeners();
  }

  void reset() {
    _completed = false;
    _resolved = false;
    notifyListeners();
  }
}

final _onboardingNotifier = _OnboardingNotifier();

/// Called by [OnboardingScreen] after persisting onboarding_completed_at to the DB.
void markOnboardingComplete() => _onboardingNotifier.markComplete();

/// Converts Supabase auth state stream into a [Listenable]
/// so GoRouter can react to changes without being rebuilt.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.initialSession) {
        if (event.session != null) {
          NotificationsService.registerToken();
          await _onboardingNotifier.checkStatus();
        }
      }
      if (event.event == AuthChangeEvent.signedOut) {
        RoleCache.clear();
        _onboardingNotifier.reset();
      }
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

/// Call once in main() after Supabase is initialized so _authNotifier is
/// subscribed before recoverSession() fires its background events.
void authNotifierEarlyInit() => _authNotifier;

/// Call once in main() after authNotifierEarlyInit() to eagerly resolve the
/// onboarding status before GoRouter is created, so the initial redirect is
/// correct without relying on an async re-evaluation after the first frame.
Future<void> initOnboardingStatus() => _onboardingNotifier.checkStatus();

String _defaultHomePath() {
  final role = RoleCache.role;
  if (role == MusicianRole.dj) return '/dj/home';
  if (role == MusicianRole.instrumentalist) return '/instrumentalist/home';
  return '/login';
}

class _MissingRouteDataScreen extends StatelessWidget {
  const _MissingRouteDataScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mangler data')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Siden "$label" kunne ikke åbnes, fordi nødvendige data mangler.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(_defaultHomePath()),
                child: const Text('Gå til forsiden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Root navigator key shared with the GoRouter so widgets that sit above
/// the router (e.g. the force-update gate) can still push dialogs/routes
/// onto the same navigator the routed tree uses.
final rootNavigatorKey = GlobalKey<NavigatorState>();

String _resolveInitialLocation() {
  final session = supabase.auth.currentSession;
  if (session == null) return '/login';
  return switch (RoleCache.role) {
    MusicianRole.dj => '/dj/home',
    MusicianRole.instrumentalist => '/instrumentalist/home',
    _ => '/profile-setup',
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: _resolveInitialLocation(),
    refreshListenable: Listenable.merge([_authNotifier, _onboardingNotifier]),
    observers: [AnalyticsService.observer],
    redirect: (context, state) {
      final isAuthenticated = supabase.auth.currentSession != null;
      final loc = state.matchedLocation;
      final isPublicRoute =
          loc == '/login' ||
          loc == '/signup' ||
          loc == '/forgot-password' ||
          loc == '/design-system' ||
          loc == '/profile-setup' ||
          loc == '/onboarding';

      if (!isAuthenticated && !isPublicRoute) return '/login';

      // Brief window during login / session recovery where the session exists
      // but the role + onboarding status aren't resolved yet. Don't route to
      // setup/onboarding here — that flashed the role-selection screen for ~0.5s
      // before bouncing to home. Stay put until resolution notifies the router.
      if (isAuthenticated && !_onboardingNotifier.resolved) {
        return null;
      }

      if (isAuthenticated && loc == '/login') {
        final role = RoleCache.role;
        if (role == MusicianRole.dj) {
          if (!_onboardingNotifier.onboardingCompleted) return '/onboarding';
          return '/dj/home';
        }
        if (role == MusicianRole.instrumentalist) {
          if (!_onboardingNotifier.onboardingCompleted) return '/onboarding';
          return '/instrumentalist/home';
        }
        return '/profile-setup';
      }

      // Gate the entire authenticated app behind onboarding completion
      if (isAuthenticated &&
          !isPublicRoute &&
          !_onboardingNotifier.onboardingCompleted) {
        return '/onboarding';
      }

      // Once onboarding is confirmed complete, leave the onboarding screen.
      if (isAuthenticated &&
          loc == '/onboarding' &&
          _onboardingNotifier.onboardingCompleted) {
        return _defaultHomePath();
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
        path: '/signup',
        name: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
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
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/design-system',
        name: AppRoutes.designSystem,
        builder: (context, state) => const DesignSystemShowcase(),
      ),

      // ── DJ shell (4 bottom tabs) ──
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) => MainShell(
              role: MusicianRole.dj,
              navigationShell: navigationShell,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dj/home',
                name: AppRoutes.djHome,
                builder:
                    (context, state) =>
                        const JobsShellScreen(role: MusicianRole.dj),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dj/featured',
                name: AppRoutes.featuredJobs,
                builder: (context, state) => const FeaturedJobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dj/chat',
                name: '${AppRoutes.chat}-dj',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dj/profile',
                name: '${AppRoutes.profile}-dj',
                builder:
                    (context, state) =>
                        const ProfileScreen(role: MusicianRole.dj),
              ),
            ],
          ),
        ],
      ),

      // ── Instrumentalist shell (3 bottom tabs) ──
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) => MainShell(
              role: MusicianRole.instrumentalist,
              navigationShell: navigationShell,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/instrumentalist/home',
                name: AppRoutes.instrumentalistHome,
                builder:
                    (context, state) => const JobsShellScreen(
                      role: MusicianRole.instrumentalist,
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/instrumentalist/chat',
                name: '${AppRoutes.chat}-instrumentalist',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/instrumentalist/profile',
                name: '${AppRoutes.profile}-instrumentalist',
                builder:
                    (context, state) =>
                        const ProfileScreen(role: MusicianRole.instrumentalist),
              ),
            ],
          ),
        ],
      ),

      // ── Detail / form routes (push on top, no bottom nav) ──
      GoRoute(
        path: '/job-detail',
        name: AppRoutes.jobDetail,
        builder: (context, state) {
          final job = state.extra;
          if (job is! Job) {
            return const _MissingRouteDataScreen(label: 'job-detaljer');
          }
          AnalyticsService.logJobViewed(
            job.id,
            job.eventType,
            jobStatus: job.status.name,
          );
          return JobDetailScreen(job: job);
        },
      ),
      GoRoute(
        path: '/dj/quote-form',
        name: AppRoutes.djQuoteForm,
        builder: (context, state) {
          final job = state.extra;
          if (job is! Job) {
            return const _MissingRouteDataScreen(label: 'tilbudsformular');
          }
          AnalyticsService.logOfferFormOpened(
            job.id,
            job.eventType,
            role: 'dj',
          );
          return DjQuoteFormScreen(job: job);
        },
      ),
      GoRoute(
        path: '/instrumentalist/offer-form',
        name: AppRoutes.instrumentalistOfferForm,
        builder: (context, state) {
          final job = state.extra;
          if (job is! Job) {
            return const _MissingRouteDataScreen(label: 'jobtilbudsformular');
          }
          AnalyticsService.logOfferFormOpened(
            job.id,
            job.eventType,
            role: 'musician',
          );
          return InstrumentalistOfferFormScreen(job: job);
        },
      ),
      GoRoute(
        path: '/quote-detail',
        name: AppRoutes.quoteDetail,
        builder: (context, state) {
          final quote = state.extra;
          if (quote is! DjQuote) {
            return const _MissingRouteDataScreen(label: 'tilbudsdetaljer');
          }
          return QuoteDetailScreen(quote: quote);
        },
      ),
      GoRoute(
        path: '/service-offer-detail',
        name: AppRoutes.serviceOfferDetail,
        builder: (context, state) {
          final offer = state.extra;
          if (offer is! ServiceOffer) {
            return const _MissingRouteDataScreen(
              label: 'service offer detaljer',
            );
          }
          return ServiceOfferDetailScreen(offer: offer);
        },
      ),

      GoRoute(
        path: '/ext-job-detail',
        name: AppRoutes.extJobDetail,
        builder: (context, state) {
          final extJob = state.extra;
          if (extJob is! ExtJob) {
            return const _MissingRouteDataScreen(label: 'eksternt job');
          }
          return ExtJobDetailScreen(extJob: extJob);
        },
      ),
      GoRoute(
        path: '/conversation-detail',
        name: AppRoutes.conversationDetail,
        builder: (context, state) {
          final conversation = state.extra;
          if (conversation is! Conversation) {
            return const _MissingRouteDataScreen(label: 'samtale');
          }
          return ConversationDetailScreen(conversation: conversation);
        },
      ),
      GoRoute(
        path: '/admin-support-thread',
        name: AppRoutes.adminSupportThread,
        builder: (context, state) {
          final thread = state.extra;
          if (thread is! AdminSupportThread) {
            return const _MissingRouteDataScreen(label: 'support-samtale');
          }
          return AdminSupportThreadScreen(thread: thread);
        },
      ),

      // ── Profile sub-screens ──
      GoRoute(
        path: '/edit-profile',
        name: AppRoutes.editProfile,
        builder: (context, state) {
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(label: 'rediger profil');
          }
          return EditProfileScreen(role: role);
        },
      ),
      GoRoute(
        path: '/reviews',
        name: AppRoutes.reviews,
        builder: (context, state) {
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(label: 'anmeldelser');
          }
          return ReviewsScreen(role: role);
        },
      ),
      GoRoute(
        path: '/media',
        name: AppRoutes.media,
        builder: (context, state) => const MediaScreen(),
      ),
      GoRoute(
        path: '/my-content',
        name: AppRoutes.myContent,
        builder: (context, state) {
          final scope =
              state.extra is JobContentKey
                  ? state.extra as JobContentKey
                  : null;
          return MyContentScreen(scope: scope);
        },
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
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(label: 'betaling');
          }
          return PaymentScreen(role: role);
        },
      ),
      GoRoute(
        path: '/dj/job-filters',
        name: AppRoutes.djJobFilters,
        builder: (context, state) {
          final djId = state.extra;
          if (djId is! String) {
            return const _MissingRouteDataScreen(label: 'jobfiltre');
          }
          return DjJobFiltersScreen(djId: djId);
        },
      ),
      GoRoute(
        path: '/instrumentalist/job-filters',
        name: AppRoutes.musicianJobFilters,
        builder: (context, state) {
          final musicianId = state.extra;
          if (musicianId is! String) {
            return const _MissingRouteDataScreen(label: 'jobfiltre');
          }
          return MusicianJobFiltersScreen(musicianId: musicianId);
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
        builder:
            (context, state) => const CalendarScreen(role: MusicianRole.dj),
      ),
      GoRoute(
        path: '/instrumentalist/calendar',
        name: AppRoutes.instrumentalistCalendar,
        builder:
            (context, state) =>
                const CalendarScreen(role: MusicianRole.instrumentalist),
      ),
      GoRoute(
        path: '/admin-messages',
        name: AppRoutes.adminMessages,
        builder: (context, state) {
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(label: 'adminbeskeder');
          }
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
        builder:
            (context, state) => FaqScreen(role: state.extra as MusicianRole),
      ),
      GoRoute(
        path: '/terms',
        name: AppRoutes.terms,
        builder: (context, state) {
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(label: 'handelsbetingelser');
          }
          return TermsScreen(role: role);
        },
      ),
      GoRoute(
        path: '/notification-settings',
        name: AppRoutes.notificationSettings,
        builder: (context, state) {
          final role = state.extra;
          if (role is! MusicianRole) {
            return const _MissingRouteDataScreen(
              label: 'notifikationsindstillinger',
            );
          }
          return NotificationSettingsScreen(role: role);
        },
      ),
    ],
  );
});

class _KeyboardDismissBar extends ConsumerWidget {
  const _KeyboardDismissBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(suppressKeyboardDismissBarProvider))
      return const SizedBox.shrink();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight == 0) return const SizedBox.shrink();

    final c = DSTheme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: c.bg.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s4,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s2,
                    vertical: 4,
                  ),
                  child: Text(
                    'Luk',
                    style: DSTextStyle.labelMd.copyWith(
                      color: c.brand.primaryActive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      // Show in-app banner when the app is in the foreground.
      // Suppress chat_message notifications for the conversation already on screen.
      FirebaseMessaging.onMessage.listen((message) {
        final type = message.data['type'] as String?;
        AnalyticsService.logNotificationReceived(
          type ?? 'unknown',
          role: message.data['role'] as String?,
        );
        NotificationsService.logReceivedToSupabase(message.data);
        if (type == 'quote_won') {
          ref.invalidate(firstWinEligibleProvider(MusicianRole.dj));
        } else if (type == 'offer_won') {
          ref.invalidate(
            firstWinEligibleProvider(MusicianRole.instrumentalist),
          );
        }
        if (type == 'chat_message') {
          final convId = int.tryParse(
            message.data['conversation_id']?.toString() ?? '',
          );
          final activeConvId = ref.read(activeConversationIdProvider);
          if (convId != null && convId == activeConvId) return;
        }
        ref.read(inAppNotificationProvider.notifier).state = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DJTilbud',
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('da'), Locale('en')],
      locale: const Locale('da'),
      builder: (context, child) {
        final isDark =
            themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return DSTheme(
          colors: isDark ? darkColors : lightColors,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: UpdateGate(
              child: Stack(
                children: [
                  child!,
                  const InAppNotificationBanner(),
                  const DevEnvBanner(),
                  const _KeyboardDismissBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
