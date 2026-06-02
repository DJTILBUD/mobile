import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/app.dart' show rootNavigatorKey;
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/app_config/presentation/providers/app_config_provider.dart';
import 'package:dj_tilbud_app/features/app_config/presentation/screens/force_update_screen.dart';

/// Top-level wrapper that:
///  - blocks the entire app with [ForceUpdateScreen] when the user is below
///    the configured minimum version,
///  - shows a one-time soft prompt when a newer (non-mandatory) version is
///    available,
///  - otherwise renders [child] unchanged.
///
/// Must sit ABOVE the GoRouter/MaterialApp content so the blocker covers
/// every route, including modal sheets and dialogs from the routed tree.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate>
    with WidgetsBindingObserver {
  bool _softPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check on resume so a user who left the app open across a release
    // gets caught when they switch back to it.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(updateStatusProvider);
    }
  }

  Future<void> _showSoftPrompt(String title, String message, String url) async {
    _softPromptShown = true;
    // Defer until after the current frame so we don't open a dialog mid-build,
    // and route through the root navigator key — UpdateGate sits ABOVE the
    // GoRouter Navigator in the widget tree (it lives in MaterialApp.builder),
    // so showDialog with this widget's context can't find a Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null) return;
      await showDSDialog<void>(
        navCtx,
        title: title,
        message: message,
        actions: (ctx) => [
          DSButton(
            label: 'Senere',
            variant: DSButtonVariant.ghost,
            size: DSButtonSize.sm,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          DSButton(
            label: 'Opdatér',
            variant: DSButtonVariant.primary,
            size: DSButtonSize.sm,
            onTap: () async {
              Navigator.of(ctx).pop();
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(updateStatusProvider);
    return statusAsync.when(
      // Don't block on the initial fetch — render the app and let the
      // gate slide in once the result lands. Avoids a flash of loading
      // state on every cold start.
      loading: () => widget.child,
      error: (_, __) => widget.child,
      data: (status) {
        switch (status.level) {
          case RequiredUpdateLevel.forced:
            return ForceUpdateScreen(
              config: status.config!,
              currentVersion: status.currentVersion,
              storeUrl: status.storeUrl!,
            );
          case RequiredUpdateLevel.optional:
            if (!_softPromptShown && status.config != null) {
              _showSoftPrompt(
                status.config!.optionalUpdateTitle ??
                    'Ny version tilgængelig',
                status.config!.optionalUpdateMessage ??
                    'En ny version af DJTilbud er klar. Opdatér for de nyeste funktioner.',
                status.storeUrl!,
              );
            }
            return widget.child;
          case RequiredUpdateLevel.none:
            return widget.child;
        }
      },
    );
  }
}
