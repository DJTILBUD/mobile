import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/ical_generator.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _webAppBaseUrl = 'app.djtilbud.dk';

Future<void> showIcalExportBottomSheet(
  BuildContext context, {
  required List<CalendarEvent> events,
  required bool isDj,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ICalExportBottomSheet(events: events, isDj: isDj),
  );
}

class _ICalExportBottomSheet extends ConsumerStatefulWidget {
  const _ICalExportBottomSheet({
    required this.events,
    required this.isDj,
  });

  final List<CalendarEvent> events;
  final bool isDj;

  @override
  ConsumerState<_ICalExportBottomSheet> createState() =>
      _ICalExportBottomSheetState();
}

class _ICalExportBottomSheetState
    extends ConsumerState<_ICalExportBottomSheet> {
  static const _c = lightColors;

  bool _isExporting = false;

  Future<void> _handleDownload() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final ics = generateIcal(widget.events);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/djtilbud-kalender.ics');
      await file.writeAsString(ics);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/calendar')],
        subject: 'Mine jobs – DJ Tilbud',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleGenerateToken() async {
    final token = await ref
        .read(generateIcalTokenProvider.notifier)
        .generate(isDj: widget.isDj);
    if (!mounted) return;
    if (token == null) {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Kunne ikke oprette link. Prøv igen.');
    }
  }

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    DSToast.show(context,
        variant: DSToastVariant.success, title: 'Link kopieret!');
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(icalTokenProvider(widget.isDj));
    final generateState = ref.watch(generateIcalTokenProvider);
    final isGenerating = generateState is AsyncLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: _c.bg.canvas,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
          ),
          child: Column(
            children: [
              const SizedBox(height: DSSpacing.s2),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _c.border.subtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s8),
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.calendarDays,
                            color: _c.text.primary, size: 20),
                        const SizedBox(width: DSSpacing.s2),
                        Text(
                          'Eksporter kalender',
                          style: DSTextStyle.headingMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _c.text.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DSSpacing.s6),

                    // ── Section 1: One-time download ──
                    _SectionHeader(
                      icon: LucideIcons.download,
                      title: 'Éngangs-download',
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    Text(
                      'Download en .ics-fil med dine ${widget.events.length} aktiviteter. '
                      'Dette er et snapshot — nye jobs dukker ikke automatisk op efterfølgende.',
                      style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                    ),
                    const SizedBox(height: DSSpacing.s3),
                    DSButton(
                      label: 'Del .ics-fil (${widget.events.length} aktiviteter)',
                      variant: DSButtonVariant.primary,
                      expand: true,
                      isLoading: _isExporting,
                      onTap: widget.events.isEmpty || _isExporting
                          ? null
                          : _handleDownload,
                    ),

                    const SizedBox(height: DSSpacing.s4),
                    Divider(height: 1, color: _c.border.subtle),
                    const SizedBox(height: DSSpacing.s4),

                    // ── Section 2: Subscription link ──
                    _SectionHeader(
                      icon: LucideIcons.refreshCw,
                      title: 'Automatisk synkronisering',
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    Text(
                      'Opret et personligt abonnements-link. Din kalender-app henter '
                      'automatisk opdateringer ca. hver 12. time.',
                      style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                    ),
                    const SizedBox(height: DSSpacing.s3),

                    tokenAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (_, __) => DSButton(
                        label: 'Prøv igen',
                        variant: DSButtonVariant.secondary,
                        onTap: () =>
                            ref.invalidate(icalTokenProvider(widget.isDj)),
                      ),
                      data: (token) {
                        if (token == null) {
                          // No token yet
                          return DSButton(
                            label: 'Opret abonnements-link',
                            variant: DSButtonVariant.secondary,
                            expand: true,
                            isLoading: isGenerating,
                            onTap: isGenerating ? null : _handleGenerateToken,
                          );
                        }

                        final webcalUrl =
                            'webcal://$_webAppBaseUrl/api/calendar/ical?token=$token';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(DSSpacing.s3),
                              decoration: BoxDecoration(
                                color: _c.bg.surface,
                                borderRadius:
                                    BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: _c.border.subtle),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      webcalUrl,
                                      style: DSTextStyle.bodySm.copyWith(
                                        color: _c.text.secondary,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: DSSpacing.s2),
                                  DSIconButton(
                                    icon: LucideIcons.copy,
                                    variant: DSIconButtonVariant.ghost,
                                    size: DSButtonSize.sm,
                                    onTap: () => _copyToClipboard(webcalUrl),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: DSSpacing.s3),
                            DSButton(
                              label: 'Regenerér link (invaliderer det gamle)',
                              variant: DSButtonVariant.tertiary,
                              expand: true,
                              isLoading: isGenerating,
                              onTap:
                                  isGenerating ? null : _handleGenerateToken,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: DSSpacing.s4),
                    Divider(height: 1, color: _c.border.subtle),
                    const SizedBox(height: DSSpacing.s4),

                    // ── Instructions ──
                    _SectionHeader(
                      icon: LucideIcons.info,
                      title: 'Sådan importerer du',
                    ),
                    const SizedBox(height: DSSpacing.s3),
                    _AppBox(
                      icon: LucideIcons.smartphone,
                      title: 'Apple Kalender (iPhone / Mac)',
                      body:
                          'Del filen → åbn den → vælg "Tilføj alle". '
                          'For abonnement: Indstillinger → Kalender → Konti → Tilføj konto → Andet → Tilføj abonneret kalender.',
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    _AppBox(
                      icon: LucideIcons.calendar,
                      title: 'Google Kalender',
                      body:
                          'Download: calendar.google.com → Indstillinger → Importer. '
                          'Abonnement: klik + ved "Andre kalendere" → Fra URL.',
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    _AppBox(
                      icon: LucideIcons.mail,
                      title: 'Outlook',
                      body:
                          'Download: Filer → Åbn og Eksporter → Importer/Eksporter → iCalendar-fil. '
                          'Abonnement: Tilføj kalender → Abonner fra web.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _c.text.secondary),
        const SizedBox(width: DSSpacing.s2),
        Text(
          title,
          style: DSTextStyle.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: _c.text.primary,
          ),
        ),
      ],
    );
  }
}

class _AppBox extends StatelessWidget {
  const _AppBox({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _c.text.secondary),
              const SizedBox(width: DSSpacing.s2),
              Text(
                title,
                style: DSTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _c.text.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            body,
            style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary),
          ),
        ],
      ),
    );
  }
}
