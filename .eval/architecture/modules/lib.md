# Module: lib

Serves as the root entry point and top-level application configuration for the DJTILBUD Flutter mobile app, initializing core services (Firebase, Supabase, push notifications, analytics, env config, and role caching) and configuring the root application widget and router.

## Key files
- `lib/main.dart`: Application entry point (main) and background Firebase push notification handler.
- `lib/app.dart`: Root application widget and route configuration, managing theme, auth/onboarding gating, and shell navigation.
- `lib/firebase_options.dart`: Platform-specific Firebase configuration options for Android and iOS.

## Public interface
- main()
- markOnboardingComplete()
- DefaultFirebaseOptions

## Dependencies
- firebase_core
- firebase_messaging
- flutter_dotenv
- flutter_riverpod
- flutter_localizations
- go_router
- supabase_flutter
- http
- intl
- dj_tilbud_app/core
- dj_tilbud_app/features

## Open questions
- _none_
