import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  static const _c = lightColors;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
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
      appBar: AppBar(
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        leading: DSIconButton(
          icon: LucideIcons.arrowLeft,
          variant: DSIconButtonVariant.ghost,
          onTap: () => context.pop(),
        ),
        title: Text(
          'Glemt adgangskode',
          style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.checkCircle, color: _c.state.success, size: 64),
        const SizedBox(height: DSSpacing.s4),
        Text(
          'Instruktioner til nulstilling af adgangskode er sendt til din email.',
          style: DSTextStyle.bodyLg.copyWith(color: _c.text.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.s6),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Tilbage til login',
            style: DSTextStyle.bodyMd.copyWith(
              color: _c.text.secondary,
              decoration: TextDecoration.underline,
              decorationColor: _c.text.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Indtast din email, og vi sender dig instruktioner til at nulstille din adgangskode.',
            style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.secondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.s6),

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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Indtast din email';
              }
              return null;
            },
          ),
          const SizedBox(height: DSSpacing.s6),

          DSButton(
            label: 'Send instruktioner til nulstilling',
            variant: DSButtonVariant.primary,
            expand: true,
            isLoading: _isLoading,
            onTap: _isLoading ? null : _handleResetPassword,
          ),
        ],
      ),
    );
  }
}
