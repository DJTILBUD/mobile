import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/theme/app_theme.dart';
import 'package:dj_tilbud_app/features/auth/presentation/auth_provider.dart';

enum MusicianRole { dj, instrumentalist }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  MusicianRole _selectedRole = MusicianRole.dj;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _headingText {
    return switch (_selectedRole) {
      MusicianRole.dj => 'Log ind som DJ',
      MusicianRole.instrumentalist => 'Log ind som Saxofonist',
    };
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Noget gik galt. Prøv igen senere.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapAuthError(AuthException e) {
    if (e.statusCode == '429') {
      return 'Bas lige ned makker! Du kan kun forsøge at logge ind hvert 60. sekund.';
    }
    return 'Forkert email eller adgangskode. Prøv igen.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/primary-logo.svg',
                        width: 160,
                        height: 160,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Heading
                    Text(
                      _headingText,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Role toggle
                    _RoleToggle(
                      selected: _selectedRole,
                      onChanged: (role) => setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.peachRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.peachRed),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.peachRed, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'eksempel@eksempel.dk',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Indtast din email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignIn(),
                      decoration: const InputDecoration(
                        labelText: 'Adgangskode',
                        hintText: 'Adgangskode',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Indtast din adgangskode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign in button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Log ind'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot password link
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text(
                          'Glemt adgangskode?',
                          style: TextStyle(
                            color: AppColors.gray,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({
    required this.selected,
    required this.onChanged,
  });

  final MusicianRole selected;
  final ValueChanged<MusicianRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MusicianRole>(
      segments: const [
        ButtonSegment(
          value: MusicianRole.dj,
          label: Text('DJ'),
        ),
        ButtonSegment(
          value: MusicianRole.instrumentalist,
          label: Text('Instrumentalist'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.boogieBuster;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.eerieBlack;
          }
          return AppColors.darkElectricBlue;
        }),
      ),
    );
  }
}
