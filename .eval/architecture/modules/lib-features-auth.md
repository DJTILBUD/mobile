# Module: lib/features/auth

Manages user authentication and account lifecycle for musicians (DJs and instrumentalists), including sign-in, registration, password reset, role detection between DjInfos and Musicians tables, and initial profile setup routing.

## Key files
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`: Interacts directly with Supabase GoTrue client for authentication actions (sign in, sign up, magic link verification, password reset, session checks) and table queries for role detection.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: Implements AuthRepository by mapping Supabase Auth responses and errors to domain results and detecting musician roles from profile tables.
- `lib/features/auth/domain/entities/musician_role.dart`: Defines the MusicianRole enum distinguishing DJ from instrumentalist.
- `lib/features/auth/domain/repositories/auth_repository.dart`: Defines the abstract interface for authentication and sign-up results.
- `lib/features/auth/presentation/providers/auth_provider.dart`: Provides Riverpod providers for AuthRepository and auth state changes.
- `lib/features/auth/presentation/screens/login_screen.dart`: Renders the musician login form, handles authentication state transitions, role caching, and navigation.
- `lib/features/auth/presentation/screens/signup_screen.dart`: Renders the account creation form and routes to profile setup or shows confirmation requirements.
- `lib/features/auth/presentation/screens/profile_setup_screen.dart`: Initial onboarding setup screen allowing newly registered users to select role (DJ or instrumentalist) and fill in core profile information.
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`: Renders the password recovery form and triggers password reset emails.

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
- package:flutter/material.dart
- package:flutter_riverpod/flutter_riverpod.dart
- package:go_router/go_router.dart
- package:supabase_flutter/supabase_flutter.dart
- package:lucide_icons/lucide_icons.dart
- package:url_launcher/url_launcher.dart
- dj_tilbud_app/core/notifications/notifications_service.dart
- dj_tilbud_app/core/error/app_exception.dart
- dj_tilbud_app/core/error/error_messages.dart
- dj_tilbud_app/core/config/role_cache.dart
- dj_tilbud_app/core/router/app_routes.dart
- dj_tilbud_app/core/design_system/components.dart
- dj_tilbud_app/core/supabase/supabase_provider.dart
- dj_tilbud_app/core/supabase/supabase_client.dart
- dj_tilbud_app/core/analytics/analytics_service.dart
- dj_tilbud_app/features/profile/domain/entities/dj_profile.dart
- dj_tilbud_app/features/profile/domain/entities/musician_profile.dart
- dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart

## Open questions
- _none_
