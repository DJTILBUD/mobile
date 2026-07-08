import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Create-account screen. With email confirmation disabled (project default) a
/// successful sign-up returns a session and the new — role-less — user is sent to
/// profile setup, where mobile's existing flow takes over (role select → profile
/// → onboarding). If confirmations are ever enabled, we instead show a
/// "check your mail" state (mirrors the web register flow).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _confirmationSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      switch (result) {
        case SignUpResult.signedInNeedsSetup:
          // Brand-new account, session active, no role yet → mobile's existing
          // new-user path. profile-setup is a public route, so the router won't
          // bounce us to onboarding before the profile exists.
          context.goNamed(AppRoutes.profileSetup);
        case SignUpResult.needsEmailConfirmation:
          setState(() => _confirmationSent = true);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('Sign-up error (${e.runtimeType}): $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Noget gik galt. Prøv igen senere.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        backgroundColor: _c.bg.canvas,
        surfaceTintColor: _c.bg.canvas,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6),
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child:
                  _confirmationSent
                      ? _buildConfirmationSent(_c)
                      : _buildForm(_c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(DSColors _c) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Opret konto',
            style: DSTextStyle.displayMd.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.text.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Opret en konto for at byde på jobs som DJ eller musiker.',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.s6),

          AnimatedSize(
            duration: DSMotion.normal,
            curve: Curves.easeOut,
            child:
                _errorMessage == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                      padding: const EdgeInsets.only(bottom: DSSpacing.s4),
                      child: Container(
                        padding: const EdgeInsets.all(DSSpacing.s3),
                        decoration: BoxDecoration(
                          color: _c.state.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(color: _c.state.danger),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: DSTextStyle.bodyMd.copyWith(
                            color: _c.state.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
          ),

          DSInput(
            label: 'Email',
            hint: 'eksempel@eksempel.dk',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Indtast din email';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Indtast en gyldig email';
              }
              return null;
            },
          ),
          const SizedBox(height: DSSpacing.s4),
          DSInput(
            label: 'Adgangskode',
            hint: 'Mindst 6 tegn',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Indtast en adgangskode';
              }
              if (value.length < 6) {
                return 'Adgangskoden skal være mindst 6 tegn';
              }
              return null;
            },
          ),
          const SizedBox(height: DSSpacing.s4),
          DSInput(
            label: 'Gentag adgangskode',
            hint: 'Gentag adgangskode',
            controller: _confirmController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignUp(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Gentag din adgangskode';
              }
              if (value != _passwordController.text) {
                return 'Adgangskoderne er ikke ens';
              }
              return null;
            },
          ),
          const SizedBox(height: DSSpacing.s6),

          DSButton(
            label: 'Opret konto',
            variant: DSButtonVariant.primary,
            expand: true,
            isLoading: _isLoading,
            onTap: _isLoading ? null : _handleSignUp,
          ),
          const SizedBox(height: DSSpacing.s4),

          Center(
            child: GestureDetector(
              onTap:
                  () =>
                      context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.login),
              child: Text.rich(
                TextSpan(
                  text: 'Har du allerede en konto? ',
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                  children: [
                    TextSpan(
                      text: 'Log ind',
                      style: DSTextStyle.bodyMd.copyWith(
                        color: _c.brand.primaryActive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSent(DSColors _c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(LucideIcons.mailOpen, size: 56, color: _c.brand.primaryActive),
        const SizedBox(height: DSSpacing.s4),
        Text(
          'Tjek din mail',
          style: DSTextStyle.headingMd.copyWith(
            fontWeight: FontWeight.w700,
            color: _c.text.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Vi har sendt dig et link til at bekræfte din konto. '
          'Når du har bekræftet, kan du logge ind.',
          style: DSTextStyle.bodyMd.copyWith(
            color: _c.text.secondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.s6),
        DSButton(
          label: 'Tilbage til log ind',
          variant: DSButtonVariant.primary,
          expand: true,
          onTap: () => context.goNamed(AppRoutes.login),
        ),
      ],
    );
  }
}
