import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Terms & conditions ("Handelsbetingelser") links.
///
/// Every musician gets two links: the customer terms (the vilkår the customer
/// accepts) and their own role-specific terms (DJ or instrumentalist/sax).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, required this.role});

  final MusicianRole role;

  // Mirrors the web-app terms URLs (SickDisclaimer.tsx + dj/faq customer link).
  static const _customerTermsUrl =
      'https://djtilbud.dk/kunde-handelsebetingelser/';
  static const _djTermsUrl = 'https://djtilbud.dk/dj-handelsbetingelser/';
  static const _musicianTermsUrl =
      'https://djtilbud.dk/handelsbetingelser-instrumentalister/';

  String get _ownTermsUrl =>
      role == MusicianRole.dj ? _djTermsUrl : _musicianTermsUrl;

  String get _ownTermsSubtitle =>
      role == MusicianRole.dj
          ? 'Vilkårene der gælder for dig som DJ'
          : 'Vilkårene der gælder for dig som musiker';

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Handelsbetingelser'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4,
          DSSpacing.s4,
          DSSpacing.s4,
          DSSpacing.s8,
        ),
        children: [
          Text(
            'Her finder du vores handelsbetingelser.',
            style: DSTextStyle.labelMd.copyWith(
              color: _c.text.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: DSSpacing.s4),
          _TermsRow(
            icon: LucideIcons.users,
            title: 'Kundens handelsbetingelser',
            subtitle: 'Vilkårene som kunden accepterer',
            onTap: () => _open(_customerTermsUrl),
          ),
          const SizedBox(height: DSSpacing.s2),
          _TermsRow(
            icon: LucideIcons.fileText,
            title: 'Mine handelsbetingelser',
            subtitle: _ownTermsSubtitle,
            onTap: () => _open(_ownTermsUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
        ),
        padding: const EdgeInsets.all(DSSpacing.s4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _c.brand.primaryActive),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DSTextStyle.labelMd.copyWith(
                      color: _c.text.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            Icon(LucideIcons.externalLink, size: 18, color: _c.text.muted),
          ],
        ),
      ),
    );
  }
}
