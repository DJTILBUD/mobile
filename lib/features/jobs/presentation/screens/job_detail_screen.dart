import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTypeLabel(job.eventType),
                style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobIdBadge(id: job.id),
          ],
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: _c.bg.surface,
              padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 14, color: _c.text.muted),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: DSTextStyle.labelMd
                            .copyWith(color: _c.text.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  // Location
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin,
                          size: 14, color: _c.text.muted),
                      const SizedBox(width: 6),
                      Text(
                        '${job.city}, ${job.region}',
                        style: DSTextStyle.labelMd
                            .copyWith(color: _c.text.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s3),
                ],
              ),
            ),

            // ── Budget band ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
              decoration: BoxDecoration(
                color: _c.brand.primary.withValues(alpha: 0.12),
                border: Border.symmetric(
                  horizontal: BorderSide(
                      color: _c.brand.primary.withValues(alpha: 0.25)),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.banknote,
                      size: 16, color: _c.brand.primaryActive),
                  const SizedBox(width: DSSpacing.s2),
                  Text(
                    job.budgetDisplay,
                    style: DSTextStyle.headingSm.copyWith(
                        color: _c.brand.primaryActive,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.clock,
                      size: 15, color: _c.text.secondary),
                  const SizedBox(width: 6),
                  Text(
                    job.timeDisplay,
                    style: DSTextStyle.labelMd
                        .copyWith(color: _c.text.secondary),
                  ),
                  const SizedBox(width: DSSpacing.s3),
                  Icon(LucideIcons.users, size: 15, color: _c.text.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${job.guestsAmount} gæster',
                    style: DSTextStyle.labelMd
                        .copyWith(color: _c.text.secondary),
                  ),
                ],
              ),
            ),

            // ── Badges ───────────────────────────────────────────────────────
            if (job.requestedSaxophonist || job.status == JobStatus.anotherRound)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (job.requestedSaxophonist)
                      DSStatusBadge(
                          label: 'Saxofonist søges', color: _c.state.info),
                    if (job.status == JobStatus.anotherRound)
                      DSStatusBadge(
                          label: 'Kan bydes på igen',
                          color: _c.state.warning),
                  ],
                ),
              ),

            const SizedBox(height: DSSpacing.s4),

            // ── Genres ───────────────────────────────────────────────────────
            if (job.genres != null && job.genres!.isNotEmpty) ...[
              _SectionCard(
                title: 'Musikgenrer',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: job.genres!
                      .map((g) => DSChip(label: g, tinted: true))
                      .toList(),
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Musician request ─────────────────────────────────────────────
            if (job.requestedSaxophonist ||
                (job.requestedMusicianHours != null &&
                    job.requestedMusicianHours! > 0)) ...[
              _SectionCard(
                title: 'Musikerforespørgsel',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.requestedSaxophonist)
                      _InfoRow(
                          icon: LucideIcons.mic,
                          label: 'Saxofonist',
                          value: 'Ja'),
                    if (job.requestedSaxophonist &&
                        job.requestedMusicianHours != null)
                      const SizedBox(height: DSSpacing.s2),
                    if (job.requestedMusicianHours != null)
                      _InfoRow(
                          icon: LucideIcons.timer,
                          label: 'Timer',
                          value:
                              '${job.requestedMusicianHours!.toStringAsFixed(1)} timer'),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Customer request ─────────────────────────────────────────────
            if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
              _SectionCard(
                title: 'Kundens ønske',
                child: Text(
                  job.leadRequest!,
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Additional information ────────────────────────────────────────
            if (job.additionalInformation != null &&
                job.additionalInformation!.isNotEmpty) ...[
              _SectionCard(
                title: 'Yderligere information',
                child: Text(
                  job.additionalInformation!,
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Birthday info ─────────────────────────────────────────────────
            if (job.birthdayPersonAge != null) ...[
              _SectionCard(
                title: 'Fødselsdagsdetaljer',
                child: _InfoRow(
                    icon: LucideIcons.cake,
                    label: 'Alder',
                    value: job.birthdayPersonAge!),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            const SizedBox(height: DSSpacing.s8),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DSTextStyle.labelLg.copyWith(
              fontWeight: FontWeight.w700,
              color: _c.text.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _c.text.muted),
        const SizedBox(width: DSSpacing.s2),
        Text(
          label,
          style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
        ),
        const Spacer(),
        Text(
          value,
          style: DSTextStyle.labelMd.copyWith(
              color: _c.text.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
