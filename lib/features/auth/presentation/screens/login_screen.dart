import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:dj_tilbud_app/app.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  // One-shot staggered entrance — content fades + slides up over the canvas
  // background, giving a smooth hand-off from the launch splash. Matches the
  // app's `AnimatedCard` idiom (ease-out fade + slide).
  late final AnimationController _entranceController;
  late final List<Animation<double>> _stagger;

  static const int _entranceSteps = 6;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _stagger = List.generate(_entranceSteps, (i) {
      final start = (0.07 * i).clamp(0.0, 0.5);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          start,
          (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });
    _entranceController.forward();
  }

  /// Wraps [child] in the entrance fade + slide for the given stagger [step].
  Widget _appear(int step, Widget child) {
    final anim = _stagger[step.clamp(0, _entranceSteps - 1)];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
      final role = await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      await RoleCache.save(role);
      await initOnboardingStatus();

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
    final _c = DSTheme.of(context);
    return Scaffold(
      backgroundColor: _c.bg.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6),
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _appear(
                      0,
                      Center(
                        // The logo PNG ships with a baked-in white background.
                        // Multiplying it with the canvas colour turns that white
                        // into the exact page background (so the "square"
                        // disappears), and ClipOval rounds it — it reads as a
                        // logo mark that blends into the screen, not a white tile.
                        child: ClipOval(
                          child: Container(
                            color: _c.bg.canvas,
                            child: Image.asset(
                              'assets/images/primary-logo.png',
                              width: 160,
                              height: 160,
                              color: _c.bg.canvas,
                              colorBlendMode: BlendMode.multiply,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s6),
                    _appear(
                      1,
                      Text(
                        'Log ind',
                        style: DSTextStyle.displayMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _c.text.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s6),

                    // Error banner — animates in smoothly when it appears.
                    AnimatedSize(
                      duration: DSMotion.normal,
                      curve: Curves.easeOut,
                      child:
                          _errorMessage == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                padding: const EdgeInsets.only(
                                  bottom: DSSpacing.s4,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(DSSpacing.s3),
                                  decoration: BoxDecoration(
                                    color: _c.state.danger.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      DSRadius.sm,
                                    ),
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

                    _appear(
                      2,
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
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    _appear(
                      3,
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
                    ),
                    const SizedBox(height: DSSpacing.s6),

                    _appear(
                      4,
                      DSButton(
                        label: 'Log ind',
                        variant: DSButtonVariant.primary,
                        expand: true,
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _handleSignIn,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s4),

                    _appear(
                      5,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () => context.pushNamed(AppRoutes.signup),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Har du ikke en konto? ',
                                  style: DSTextStyle.bodyMd.copyWith(
                                    color: _c.text.secondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Opret konto',
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
                          const SizedBox(height: DSSpacing.s3),
                          Center(
                            child: GestureDetector(
                              onTap:
                                  () => context.pushNamed(
                                    AppRoutes.forgotPassword,
                                  ),
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
                              onTap:
                                  () => launchUrl(
                                    Uri.parse(
                                      'https://djtilbud.dk/privacy-policy/',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                              child: Text(
                                'Privatlivspolitik',
                                style: DSTextStyle.bodySm.copyWith(
                                  color: _c.text.muted,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _c.text.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
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
