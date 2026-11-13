# Module: lib/features/auth

Manages user authentication and initial onboarding profile setup for musicians (DJs and instrumentalists), including password-based login, signup, password reset, admin impersonation token handling, and role detection between DjInfos and Musicians tables.

## Key files
- `lib/features/auth/domain/entities/musician_role.dart`: Defines the MusicianRole enum distinguishing between DJ and instrumentalist accounts.
- `lib/features/auth/domain/repositories/auth_repository.dart`: Declares the authentication repository contract and SignUpResult states.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`: Wraps Supabase GoTrue client operations and checks profile existence in the database.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: Implements AuthRepository, mapping Supabase exceptions to domain errors and detecting musician roles.
- `lib/features/auth/presentation/providers/auth_provider.dart`: Exposes Riverpod providers for the AuthRepository and authentication state stream.
- `lib/features/auth/presentation/screens/login_screen.dart`: UI screen handling credential login, error display, role-based navigation, and profile setup routing.
- `lib/features/auth/presentation/screens/signup_screen.dart`: UI screen for creating new musician accounts with email and password.
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`: UI screen allowing users to request password reset emails.
- `lib/features/auth/presentation/screens/profile_setup_screen.dart`: UI screen guiding new users to establish their DJ or instrumentalist profiles after initial authentication.

## Public interface
- MusicianRole
- SignUpResult
- AuthRepository
- AuthRepositoryImpl
- AuthRemoteDatasource
- authRepositoryProvider
- authStateProvider
- LoginScreen
- SignupScreen
- ForgotPasswordScreen
- ProfileSetupScreen

## Dependencies
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:supabase_flutter/supabase_flutter.dart
- package:go_router/go_router.dart
- package:lucide_icons/lucide_icons.dart
- package:url_launcher/url_launcher.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/error/error_messages.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/config/role_cache.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/analytics/analytics_service.dart
- package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart
- package:dj_tilbud_app/app.dart

## Open questions
- _none_
