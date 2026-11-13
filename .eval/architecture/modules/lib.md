# Module: lib

Serves as the root entry point and application shell for the DJTILBUD musician mobile app, handling environment initialization, Firebase and Supabase bootstrapping, background push notification handling, routing, and onboarding gating.

## Key files
- `lib/main.dart`: Entrypoint function main() initializing environment, cache, Supabase, Firebase, notification services, analytics gating, and background notification handler before launching the root widget.
- `lib/app.dart`: Defines the root App widget, authentication and onboarding state notifiers (_AuthNotifier, _OnboardingNotifier), and router integration.
- `lib/firebase_options.dart`: Provides platform-specific FirebaseOptions configuration for Android and iOS platforms.

## Public interface
- void main()
- void markOnboardingComplete()
- DefaultFirebaseOptions.currentPlatform
- DefaultFirebaseOptions.android
- DefaultFirebaseOptions.ios

## Dependencies
- package:flutter/material.dart
- package:flutter_localizations/flutter_localizations.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:firebase_core/firebase_core.dart
- package:firebase_messaging/firebase_messaging.dart
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_dotenv/flutter_dotenv.dart
- package:http/http.dart
- package:intl/date_symbol_data_local.dart

## Open questions
- _none_
