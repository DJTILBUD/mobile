# Module: lib

Root application module that bootstraps the Flutter app, initializes environment, notifications, Supabase, and Firebase configurations, handles background push notifications, and orchestrates root app state and navigation routing.

## Key files
- `lib/main.dart`: Application entry point running initialization for environment configs, Firebase, Supabase, analytics, notifications, and the top-level background notification isolate handler.
- `lib/app.dart`: Root application widget and router state manager, tracking onboarding and authentication state changes to control screen transitions.
- `lib/firebase_options.dart`: Platform-specific Firebase configuration options for Android and iOS targets.

## Public interface
- void main()
- void markOnboardingComplete()
- DefaultFirebaseOptions.currentPlatform
- DefaultFirebaseOptions.android
- DefaultFirebaseOptions.ios

## Dependencies
- firebase_core
- firebase_messaging
- flutter/foundation.dart
- flutter/material.dart
- flutter_dotenv
- flutter_localizations
- flutter_riverpod
- go_router
- http
- intl/date_symbol_data_local.dart
- supabase_flutter

## Open questions
- The full implementations of _AuthNotifier, App widget, and GoRouter configuration are truncated in lib/app.dart.
