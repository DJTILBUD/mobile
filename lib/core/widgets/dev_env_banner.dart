import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:dj_tilbud_app/app.dart' show rootNavigatorKey;
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/config/role_cache.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/widgets/restart_widget.dart';
import 'package:dj_tilbud_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dj_tilbud_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Floating dev tool — only visible in debug builds.
/// Shows current env as a pill (orange = local, blue = dev, red = prod).
/// Tap to open a panel that can: switch DB env, and impersonate any user
/// (super-owner debug login — see [NotificationsService] impersonation guard).
class DevEnvBanner extends StatefulWidget {
  const DevEnvBanner({super.key});

  @override
  State<DevEnvBanner> createState() => _DevEnvBannerState();
}

class _DevEnvBannerState extends State<DevEnvBanner> {
  bool _panelOpen = false;
  bool _switching = false;

  static const _envs = ['local', 'dev', 'prod'];

  Color _colorFor(String env) => switch (env) {
    'local' => const Color(0xFFFF8C00),
    'dev' => const Color(0xFF2563EB),
    'prod' => const Color(0xFFDC2626),
    _ => const Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final currentEnv = EnvConfig.env;
    final color = _colorFor(currentEnv);
    final others = _envs.where((e) => e != currentEnv).toList();

    return Positioned(
      bottom: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_panelOpen) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nuværende DB',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentEnv.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_switching)
                    const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children:
                          others
                              .map(
                                (env) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: SizedBox(
                                    width: 180,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: _colorFor(env),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _switchEnv(context, env),
                                      child: Text(
                                        'Skift til ${env.toUpperCase()}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const Divider(height: 18),
                    _buildImpersonateSection(context),
                  ],
                ],
              ),
            ),
          ],
          GestureDetector(
            onTap: () => setState(() => _panelOpen = !_panelOpen),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                currentEnv.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpersonateSection(BuildContext context) {
    final isImpersonating = NotificationsService.isImpersonating;
    final email = supabase.auth.currentUser?.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Impersonate',
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 6),
        if (isImpersonating) ...[
          SizedBox(
            width: 180,
            child: Text(
              'Logget ind som\n${email ?? 'ukendt'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 180,
            child: TextButton(
              style: _btnStyle(const Color(0xFF374151)),
              onPressed: () => _logOut(context),
              child: const Text('Log ud', style: TextStyle(fontSize: 13)),
            ),
          ),
        ] else
          SizedBox(
            width: 180,
            child: TextButton(
              style: _btnStyle(const Color(0xFF7C3AED)),
              onPressed: _showImpersonateDialog,
              child: const Text(
                'Log ind som bruger…',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  ButtonStyle _btnStyle(Color bg) => TextButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(0, 0),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Future<void> _showImpersonateDialog() async {
    // DevEnvBanner sits ABOVE the router's Navigator (it's a sibling of the
    // navigator in MaterialApp.builder), so its own context has no Navigator.
    // Push the dialog through the app's root navigator instead, and run the
    // whole flow inside the dialog so errors show inline (no ScaffoldMessenger).
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final controller = TextEditingController();
    final success = await showDialog<bool>(
      context: navContext,
      builder: (ctx) {
        final c = DSTheme.of(ctx);
        String? error;
        bool busy = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              final email = controller.text.trim();
              if (email.isEmpty) {
                setLocal(() => error = 'Indtast en email');
                return;
              }
              setLocal(() {
                busy = true;
                error = null;
              });
              try {
                final tokenHash = await _fetchTokenHash(email);
                // Enter impersonation mode BEFORE establishing the session so
                // the `signedIn` event skips device-token registration.
                await NotificationsService.setImpersonating(true);
                final repo = AuthRepositoryImpl(AuthRemoteDatasource(supabase));
                try {
                  final role = await repo.signInWithMagicTokenHash(tokenHash);
                  await RoleCache.save(role);
                } on NeedsProfileSetupException {
                  // Session established but no DJ/Musician profile — restart
                  // routes to profile-setup. Leave RoleCache cleared.
                  await RoleCache.clear();
                }
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              } catch (e) {
                await NotificationsService.setImpersonating(false);
                final msg = e is AppException ? e.message : e.toString();
                setLocal(() {
                  busy = false;
                  error = msg.isEmpty ? 'Impersonation fejlede' : msg;
                });
              }
            }

            return DSDialog(
              title: 'Impersonate bruger',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logger ind SOM en bruger i "${EnvConfig.env.toUpperCase()}". '
                    'Handlinger er ægte skrivninger; push-token røres ikke.',
                    style: DSTextStyle.bodySm.copyWith(color: c.text.secondary),
                  ),
                  const SizedBox(height: DSSpacing.s4),
                  DSInput(
                    label: 'Brugerens email',
                    hint: 'dj@eksempel.dk',
                    controller: controller,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    errorText: error,
                    state:
                        error != null
                            ? DSInputState.error
                            : DSInputState.normal,
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
              actions: [
                DSButton(
                  label: 'Annullér',
                  variant: DSButtonVariant.ghost,
                  size: DSButtonSize.sm,
                  onTap: busy ? null : () => Navigator.of(ctx).pop(false),
                ),
                DSButton(
                  label: 'Log ind',
                  variant: DSButtonVariant.primary,
                  size: DSButtonSize.sm,
                  isLoading: busy,
                  onTap: busy ? null : submit,
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true && mounted) {
      RestartWidget.restartApp(context);
    }
  }

  /// Resolves the web-app base URL, mapping localhost → 10.0.2.2 on the
  /// Android emulator (mirrors supabase_client + jobs datasource).
  String get _webAppBaseUrl {
    var url = EnvConfig.webAppUrl;
    if (EnvConfig.isLocal && Platform.isAndroid) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  Future<String> _fetchTokenHash(String email) async {
    final apiKey = EnvConfig.adminApiKey;
    if (apiKey.isEmpty) {
      throw const AuthException(
        'ADMIN_API_KEY mangler i .env — sæt den for at impersonate.',
      );
    }
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$_webAppBaseUrl/api/admin/magic/token'),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: jsonEncode({'email': email}),
      );
    } catch (e) {
      throw NetworkException('Kunne ikke nå serveren: $e');
    }
    if (res.statusCode != 200) {
      String detail = '';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        detail = (body['error'] ?? body['message'] ?? '').toString();
      } catch (_) {}
      throw AuthException(
        'Token-fejl (${res.statusCode})${detail.isEmpty ? '' : ': $detail'}',
      );
    }
    final tokenHash =
        (jsonDecode(res.body) as Map<String, dynamic>)['tokenHash'] as String?;
    if (tokenHash == null || tokenHash.isEmpty) {
      throw const AuthException('Tomt token modtaget fra serveren.');
    }
    return tokenHash;
  }

  Future<void> _logOut(BuildContext context) async {
    setState(() => _switching = true);
    // Clears the impersonation flag too (see AuthRemoteDatasource.signOut).
    await AuthRepositoryImpl(AuthRemoteDatasource(supabase)).signOut();
    await RoleCache.clear();
    if (context.mounted) RestartWidget.restartApp(context);
  }

  Future<void> _switchEnv(BuildContext context, String newEnv) async {
    setState(() => _switching = true);

    try {
      await supabase.auth.signOut();
    } catch (_) {}

    await EnvConfig.saveEnvPreference(newEnv);

    await Supabase.instance.dispose();
    await EnvConfig.load();
    await initSupabase();

    if (context.mounted) {
      RestartWidget.restartApp(context);
    }
  }
}
