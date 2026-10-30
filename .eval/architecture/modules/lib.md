# Module: lib

Flutter app entrypoint: initializes platform services (Supabase, Firebase/FCM, analytics, role cache, onboarding status) and builds the GoRouter configuration that wires together all feature screens (auth, jobs, chat, profile, calendar, notifications, referrals, featured jobs, onboarding) into the single candidate app.

## Key files
- `lib/main.dart`: App bootstrap: loads env config, role cache, Supabase client, Firebase, date formatting, analytics gating, and notification service before running the app
- `lib/app.dart`: Defines the root App widget, GoRouter route table linking to feature screens, and auth/onboarding state notifiers (_OnboardingNotifier, _AuthNotifier) that gate navigation
- `lib/firebase_options.dart`: Generated Firebase platform configuration (Android/iOS) consumed by Firebase.initializeApp

## Public interface
- main()
- markOnboardingComplete()
- DefaultFirebaseOptions.currentPlatform

## Dependencies
- flutter
- flutter_riverpod
- flutter_localizations
- go_router
- supabase_flutter
- firebase_core
- firebase_messaging
- flutter_dotenv
- http
- intl
- dj_tilbud_app/core/* (notifications, navigation, router, config, supabase, design_system, theme, analytics, widgets)
- dj_tilbud_app/features/* (auth, chat, featured_jobs, jobs, profile, calendar, referrals, notifications, onboarding, app_config, first_win)

## Open questions
- Where are authNotifierEarlyInit() and initOnboardingStatus(), called from lib/main.dart, actually defined? They are not visible in the (truncated) lib/app.dart excerpt shown here.
- The business description mentions an 'AI agent for profiles and sales pitches' — no prompt files or model API calls are visible in lib/app.dart, lib/main.dart, or lib/firebase_options.dart; that logic must live in a feature module not included here (possibly features/first_win or features/profile, which are only referenced via imports).
- The full content of lib/app.dart is truncated after _AuthNotifier's constructor, so some route definitions and provider wiring are not inspectable.
