import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/app_config/domain/entities/app_config.dart';

/// Full-screen, non-dismissable blocker shown when the running app version
/// is below the minimum required version reported by Supabase `AppConfig`.
/// Intercepts the system back button (Android) via PopScope.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.config,
    required this.currentVersion,
    required this.storeUrl,
  });

  final AppConfig config;
  final String currentVersion;
  final String storeUrl;

  Future<void> _openStore() async {
    final uri = Uri.parse(storeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: c.bg.canvas,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.s6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: c.brand.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.downloadCloud,
                        size: 44,
                        color: c.brand.primaryActive,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s6),
                    Text(
                      config.forceUpdateTitle ?? 'Opdatering påkrævet',
                      textAlign: TextAlign.center,
                      style: DSTextStyle.headingLg.copyWith(
                        color: c.text.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s3),
                    Text(
                      config.forceUpdateMessage ??
                          'Du skal opdatere DJTilbud for at fortsætte.',
                      textAlign: TextAlign.center,
                      style: DSTextStyle.bodyMd.copyWith(
                        color: c.text.secondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s8),
                    DSButton(
                      label: 'Opdatér nu',
                      size: DSButtonSize.lg,
                      expand: true,
                      onTap: _openStore,
                    ),
                    const SizedBox(height: DSSpacing.s4),
                    Text(
                      'Din version: $currentVersion',
                      style: DSTextStyle.bodySm
                          .copyWith(color: c.text.muted),
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
