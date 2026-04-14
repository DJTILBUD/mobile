import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dj_tilbud_app/core/config/env_config.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/widgets/restart_widget.dart';

/// Floating env switcher — only visible in debug builds.
/// Shows current env as a pill (orange = local, blue = dev).
/// Tap to toggle between local ↔ dev with sign-out + full restart.
class DevEnvBanner extends StatefulWidget {
  const DevEnvBanner({super.key});

  @override
  State<DevEnvBanner> createState() => _DevEnvBannerState();
}

class _DevEnvBannerState extends State<DevEnvBanner> {
  bool _panelOpen = false;
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final currentEnv = EnvConfig.env;
    final isLocal = currentEnv == 'local';
    final color = isLocal ? const Color(0xFFFF8C00) : const Color(0xFF2563EB);
    final nextEnv = isLocal ? 'dev' : 'local';

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
                  SizedBox(
                    width: 160,
                    child: _switching
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _switchEnv(context, nextEnv),
                            child: Text(
                              'Skift til ${nextEnv.toUpperCase()}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                  ),
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
