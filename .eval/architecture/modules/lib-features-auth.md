# Module: lib/features/auth

Manages user authentication, account registration, role detection (DJ vs instrumentalist musician), password resets, super-owner impersonation, and initial profile setup routing.

## Key files
- `lib/features/auth/domain/entities/musician_role.dart`: Defines the MusicianRole enum distinguishing DJ and instrumentalist users.
- `lib/features/auth/domain/repositories/auth_repository.dart`: Defines the abstract interface for authentication, password reset, sign-up, and magic token verification.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`: Communicates with Supabase Auth (GoTrueClient) and checks profile table existence ('DjInfos' vs 'Musicians').
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: Implements AuthRepository, maps Supabase authentication exceptions into domain exceptions, and handles role detection.
- `lib/features/auth/presentation/providers/auth_provider.dart`: Provides Riverpod providers for authRepositoryProvider and authStateProvider.
- `lib/features/auth/presentation/screens/login_screen.dart`: Presents email/password login UI, logs analytics, and routes to respective role home or profile setup.
- `lib/features/auth/presentation/screens/signup_screen.dart`: Presents new account registration UI and routes users to profile setup or confirms email verification requirement.
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`: Presents password recovery form to trigger password reset emails.
- `lib/features/auth/presentation/screens/profile_setup_screen.dart`: Initial setup form for new accounts to choose role (DJ or instrumentalist) and populate profile information.

## Public interface
- enum MusicianRole { dj, instrumentalist }
- enum SignUpResult { signedInNeedsSetup, needsEmailConfirmation }
- abstract class AuthRepository
- class AuthRepositoryImpl implements AuthRepository
- class AuthRemoteDatasource
- final authRepositoryProvider = Provider<AuthRepository>
- final authStateProvider = StreamProvider<bool>
- class LoginScreen extends ConsumerStatefulWidget
- class SignupScreen extends ConsumerStatefulWidget
- class ForgotPasswordScreen extends ConsumerStatefulWidget
- class ProfileSetupScreen extends ConsumerStatefulWidget

## Dependencies
- package:flutter/foundation.dart
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:supabase_flutter/supabase_flutter.dart
- package:lucide_icons/lucide_icons.dart
- package:url_launcher/url_launcher.dart
- package:dj_tilbud_app/core/notifications/notifications_service.dart
- package:dj_tilbud_app/core/error/app_exception.dart
- package:dj_tilbud_app/core/error/error_messages.dart
- package:dj_tilbud_app/core/design_system/components.dart
- package:dj_tilbud_app/core/config/role_cache.dart
- package:dj_tilbud_app/core/router/app_routes.dart
- package:dj_tilbud_app/core/supabase/supabase_client.dart
- package:dj_tilbud_app/core/supabase/supabase_provider.dart
- package:dj_tilbud_app/core/analytics/analytics_service.dart
- package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## Open questions
- _none_
