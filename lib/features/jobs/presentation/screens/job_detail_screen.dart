import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  static final _numFmt = NumberFormat('#,###', 'da_DK');
  static String _fmt(int n) => _numFmt.format(n).replaceAll(',', '.');

  String _adjustedBudgetDisplay(String? djTier) {
    final noBudget = job.budgetStart == null && job.budgetEnd == null;

    // B-tier fallback: show fixed range when no budget is provided
    if (djTier == 'B' && noBudget) {
      return '${_fmt(3500)} – ${_fmt(6500)} kr.';
    }

    final adjEnd = adjustBudgetForDjView(
      budget: job.budgetEnd ?? job.budgetStart,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );
    if (adjEnd == null) return 'Ikke angivet';

    if (job.budgetStart != null && job.budgetStart != job.budgetEnd) {
      final adjStart = adjustBudgetForDjView(
        budget: job.budgetStart,
        requestedSaxophonist: job.requestedSaxophonist,
        requestedMusicianHours: job.requestedMusicianHours,
        djTier: djTier,
        maxBudget: job.budgetEnd,
        jobCreatedAt: job.createdAt,
      );
      if (adjStart != null) {
        final adjEndClamped = adjEnd > adjStart ? adjEnd : adjStart;
        return '${_fmt(adjStart.toInt())} – ${_fmt(adjEndClamped.toInt())} kr.';
      }
    }
    return '${_fmt(adjEnd.toInt())} kr.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final noBudget = job.budgetStart == null && job.budgetEnd == null;
    final showBTierFallback = djTier == 'B' && noBudget;
    final showBudgetIncrease =
        !showBTierFallback &&
        hasBTierBudgetIncreaseAfter24h(
          budget: job.budgetEnd ?? job.budgetStart,
          djTier: djTier,
          maxBudget: job.budgetEnd,
          jobCreatedAt: job.createdAt,
        );

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
            JobIdBadge(
              id: job.isExtJob ? (job.extJobId ?? job.id) : job.id,
              isExtJob: job.isExtJob,
            ),
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
                DSSpacing.s4,
                DSSpacing.s3,
                DSSpacing.s4,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: _c.text.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  // Region
                  Row(
                    children: [
                      Icon(LucideIcons.flag, size: 14, color: _c.text.muted),
                      const SizedBox(width: 6),
                      Text(
                        job.region,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                  if (job.city.isNotEmpty) ...[
                    const SizedBox(height: DSSpacing.s1),
                    // Lokation (venue)
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: _c.text.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            job.city,
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DSSpacing.s3),
                ],
              ),
            ),

            // ── Budget band ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.s4,
                vertical: DSSpacing.s3,
              ),
              decoration: BoxDecoration(
                color: _c.brand.primary.withValues(alpha: 0.12),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: _c.brand.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.banknote,
                        size: 16,
                        color: _c.brand.primaryActive,
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Text(
                        _adjustedBudgetDisplay(djTier),
                        style: DSTextStyle.headingSm.copyWith(
                          color: _c.brand.primaryActive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showBudgetIncrease) ...[
                        const SizedBox(width: 6),
                        _BudgetIncreasePulse(colors: _c),
                      ],
                      const Spacer(),
                      Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: _c.text.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        job.timeDisplay,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s3),
                      Icon(
                        LucideIcons.users,
                        size: 15,
                        color: _c.text.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${job.guestsAmount} gæster',
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                  if (job.requestedSaxophonist) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Budgettet gælder kun DJ. Saxofonist afregnes separat.',
                      style: DSTextStyle.bodySm.copyWith(
                        color: _c.brand.primaryActive.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Badges ───────────────────────────────────────────────────────
            if (job.requestedSaxophonist ||
                job.status == JobStatus.anotherRound)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4,
                  DSSpacing.s3,
                  DSSpacing.s4,
                  0,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (job.requestedSaxophonist)
                      DSStatusBadge(
                        label: 'Saxofonist søges',
                        color: _c.state.info,
                      ),
                    if (job.status == JobStatus.anotherRound)
                      DSStatusBadge(
                        label: 'Kan bydes på igen',
                        color: _c.state.warning,
                      ),
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
                  children:
                      job.genres!
                          .map((g) => DSChip(label: g, tinted: true))
                          .toList(),
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Musician request ─────────────────────────────────────────────
            if (job.requestedSaxophonist ||
                (job.requestedMusicianHours != null &&
                    job.requestedMusicianHours! > 0) ||
                job.musicianStartTime != null ||
                job.saxType != null) ...[
              _SectionCard(
                title: 'Musikerforespørgsel',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.requestedSaxophonist)
                      _InfoRow(
                        icon: LucideIcons.music2,
                        label: 'Saxofonist',
                        value: 'Ja',
                      ),
                    if (job.saxType != null && job.saxType!.isNotEmpty) ...[
                      if (job.requestedSaxophonist)
                        const SizedBox(height: DSSpacing.s2),
                      _InfoRow(
                        icon: LucideIcons.music,
                        label: 'Spiltype',
                        value:
                            job.saxType == 'lounge'
                                ? 'Lounge'
                                : job.saxType == 'party'
                                ? 'Party'
                                : '${job.saxType![0].toUpperCase()}${job.saxType!.substring(1)}',
                      ),
                      const SizedBox(height: DSSpacing.s2),
                      _SaxTypeDescription(saxType: job.saxType!),
                    ],
                    if (job.requestedMusicianHours != null) ...[
                      const SizedBox(height: DSSpacing.s2),
                      _InfoRow(
                        icon: LucideIcons.timer,
                        label: 'Timer',
                        value: '${job.musicianHoursDisplay} timer',
                      ),
                    ],
                    if (job.musicianStartTime != null) ...[
                      const SizedBox(height: DSSpacing.s2),
                      _InfoRow(
                        icon: LucideIcons.clock,
                        label: 'Saxofonist starter',
                        value: job.musicianStartTime!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Musician special request ──────────────────────────────────────
            if (job.musicianSpecialRequest != null &&
                job.musicianSpecialRequest!.isNotEmpty) ...[
              _SectionCard(
                title: 'Særligt ønske til musikeren',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.star, size: 15, color: _c.state.warning),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        job.musicianSpecialRequest!,
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
            ],

            // ── Customer request ─────────────────────────────────────────────
            if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
              _SectionCard(
                title: 'Kundens ønske',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.leadRequest!,
                      style: DSTextStyle.bodyMd.copyWith(
                        color: _c.text.secondary,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: job.leadRequest!),
                        );
                        DSToast.show(
                          context,
                          variant: DSToastVariant.success,
                          title: 'Kundens ønske kopieret',
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.copy,
                            size: 13,
                            color: _c.text.muted,
                          ),
                          const SizedBox(width: DSSpacing.s1),
                          Text(
                            'Kopier',
                            style: DSTextStyle.labelSm.copyWith(
                              color: _c.text.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  value: job.birthdayPersonAge!,
                ),
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

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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
            color: _c.text.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SaxTypeDescription extends StatefulWidget {
  const _SaxTypeDescription({required this.saxType});
  final String saxType;

  @override
  State<_SaxTypeDescription> createState() => _SaxTypeDescriptionState();
}

class _SaxTypeDescriptionState extends State<_SaxTypeDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final (IconData icon, Color color, String description) = switch (widget
        .saxType) {
      'lounge' => (
        LucideIcons.coffee,
        c.state.info,
        'Du spiller blød baggrundsmusik – jazz, bossa nova og rolige melodier. Du er ikke centrum for opmærksomhed, men sætter stemningen diskret.',
      ),
      'party' => (
        LucideIcons.partyPopper,
        c.state.warning,
        'Du er centrum for opmærksomhed – spil kendte hits, bring energi og dansevibes til festen. Tænd for salen og giv den gas.',
      ),
      _ => (LucideIcons.music, c.text.muted, ''),
    };

    if (description.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: DSSpacing.s2),
            Expanded(
              child:
                  _expanded
                      ? Text(
                        description,
                        style: DSTextStyle.bodySm.copyWith(
                          color: c.text.secondary,
                        ),
                      )
                      : Text(
                        'Tryk for at læse mere',
                        style: DSTextStyle.bodySm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
            Icon(
              _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetIncreasePulse extends StatefulWidget {
  const _BudgetIncreasePulse({required this.colors});
  final DSColors colors;

  @override
  State<_BudgetIncreasePulse> createState() => _BudgetIncreasePulseState();
}

class _BudgetIncreasePulseState extends State<_BudgetIncreasePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_anim.value - i * 0.25).clamp(0.0, 1.0);
              final opacity = Curves.easeInOut.transform(t);
              return Opacity(
                opacity: opacity < 0.4 ? 0.3 : opacity,
                child: Icon(
                  LucideIcons.chevronUp,
                  size: 14,
                  color: c.state.success,
                ),
              );
            }),
          ),
    );
  }
}
