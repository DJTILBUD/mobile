# Module: lib/features/auth

Handles account creation, sign-in/out, password reset, and first-time profile setup for musicians (DJs and instrumentalists/saxophonists) using the app — determining their role from existing profile rows so they can be routed into their role-specific home feed where they quote on jobs.

## Key files
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`: Wraps Supabase GoTrue calls (password sign-in/sign-up, magic-link token verification for debug/super-owner impersonation, sign-out, password reset) and checks whether a profile row exists for a user in the DjInfos or Musicians tables.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: Implements AuthRepository: maps Supabase AuthExceptions to user-facing Danish error messages, detects the user's MusicianRole (dj vs instrumentalist) after sign-in by checking DjInfos/Musicians tables, and throws NeedsProfileSetupException when no role is found yet.
- `lib/features/auth/domain/entities/musician_role.dart`: Defines the MusicianRole enum (dj, instrumentalist) used to route users to the correct profile type and home feed.
- `lib/features/auth/domain/repositories/auth_repository.dart`: Abstract domain contract for auth operations (signIn, signInWithMagicTokenHash, signUp, signOut, resetPassword) and the SignUpResult enum distinguishing immediate session vs. pending email confirmation.
- `lib/features/auth/presentation/providers/auth_provider.dart`: Riverpod providers wiring AuthRepositoryImpl to the Supabase client and exposing authStateProvider as a stream of signed-in/out state.
- `lib/features/auth/presentation/screens/login_screen.dart`: Login UI; on success caches the detected role (RoleCache), initializes onboarding status, logs analytics, and routes to djHome or instrumentalistHome, or to profileSetup if the account has no profile yet.
- `lib/features/auth/presentation/screens/signup_screen.dart`: Account creation UI; routes newly created (role-less) accounts to profile setup, or shows an email-confirmation-sent state if confirmations are enabled.
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`: Password reset request UI calling AuthRepository.resetPassword and showing a confirmation state.
- `lib/features/auth/presentation/screens/profile_setup_screen.dart`: First-time profile creation flow letting a new user pick a role (DJ or musician/instrumentalist) and fill out profile fields (name, phone, about, regions, genres, instrument, rates) before being routed into their home feed; also redirects returning users who already have a profile straight home.

## Public interface
- AuthRepository (signIn, signInWithMagicTokenHash, signUp, signOut, resetPassword, isAuthenticated, authStateChanges)
- SignUpResult enum (signedInNeedsSetup, needsEmailConfirmation)
- MusicianRole enum (dj, instrumentalist)
- AuthRemoteDatasource (signInWithPassword, signUpWithPassword, verifyMagicTokenHash, signOut, resetPasswordForEmail, hasProfileInTable, isAuthenticated, authStateChanges)
- authRepositoryProvider
- authStateProvider

## Dependencies
- supabase_flutter
- flutter_riverpod
- go_router
- lib/core/notifications/notifications_service.dart
- lib/core/supabase/supabase_provider.dart
- lib/core/supabase/supabase_client.dart
- lib/core/error/app_exception.dart
- lib/core/error/error_messages.dart
- lib/core/config/role_cache.dart
- lib/core/router/app_routes.dart
- lib/core/analytics/analytics_service.dart
- lib/app.dart
- lib/features/profile/domain/entities/dj_profile.dart
- lib/features/profile/domain/entities/musician_profile.dart
- lib/features/profile/presentation/providers/profile_provider.dart
- lib/core/design_system/components.dart
- lucide_icons
- url_launcher

## Open questions
- No AI/LLM-related code (prompt files, model calls, agent logic) appears in this module — the 'AI agent for profiles and sales pitches' selling point is not implemented here.
- The magic-link token verification path is described as debug-only super-owner impersonation — is this gated behind a build flag or environment check anywhere outside this module?
- Role detection relies on row existence in DjInfos/Musicians tables rather than an explicit role column — what happens if a user somehow has rows in both tables?
- Email confirmation behavior branches on a 'project default' (disabled) assumption in signup_screen.dart and auth_repository_impl.dart — where is this configured, and is it consistent across environments?
