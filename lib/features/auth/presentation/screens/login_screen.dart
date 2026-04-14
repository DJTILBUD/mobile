import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  static const _c = lightColors;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final role = await ref.read(authRepositoryProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await RoleCache.save(role);

      if (!mounted) return;

      switch (role) {
        case MusicianRole.dj:
          context.goNamed(AppRoutes.djHome);
        case MusicianRole.instrumentalist:
          context.goNamed(AppRoutes.instrumentalistHome);
      }
    } on NeedsProfileSetupException {
      if (!mounted) return;
      context.goNamed(AppRoutes.profileSetup);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('Login error (${e.runtimeType}): $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Noget gik galt. Prøv igen senere.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/primary-logo.png',
                        width: 160,
                        height: 160,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s6),
                    Text(
                      'Log ind',
                      style: DSTextStyle.displayMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _c.text.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DSSpacing.s6),

                    // Error banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(DSSpacing.s3),
                        decoration: BoxDecoration(
                          color: _c.state.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(color: _c.state.danger),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s4),
                    ],

                    DSInput(
                      label: 'Email',
                      hint: 'eksempel@eksempel.dk',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Indtast din email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    DSInput(
                      label: 'Adgangskode',
                      hint: 'Adgangskode',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSignIn(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Indtast din adgangskode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DSSpacing.s6),

                    DSButton(
                      label: 'Log ind',
                      variant: DSButtonVariant.primary,
                      expand: true,
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _handleSignIn,
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    Center(
                      child: GestureDetector(
                        onTap: () => context.pushNamed(AppRoutes.forgotPassword),
                        child: Text(
                          'Glemt adgangskode?',
                          style: DSTextStyle.bodyMd.copyWith(
                            color: _c.text.secondary,
                            decoration: TextDecoration.underline,
                            decorationColor: _c.text.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pushNamed(AppRoutes.designSystem),
                        child: Text(
                          'Design System',
                          style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
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
