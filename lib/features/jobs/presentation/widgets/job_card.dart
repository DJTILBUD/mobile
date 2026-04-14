import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/job_summary_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.isColliding = false,
    this.djTier,
    this.musicianPrice,
  });

  final Job job;
  final VoidCallback? onTap;
  final bool isColliding;
  final String? djTier;
  final int? musicianPrice;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final isAnotherRound = job.status == JobStatus.anotherRound;
    final isHighSeason = job.quoteSendMode == 'first_quote_only';
    final showBudgetIncrease = hasBTierBudgetIncreaseAfter24h(
      budget: job.budgetEnd ?? job.budgetStart,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );

    // Left-edge accent colour — the only colour on the card
    final accentColor = isColliding
        ? c.state.danger
        : isAnotherRound
            ? c.state.warning
            : c.brand.accent;

    final hasChips = job.requestedSaxophonist || isHighSeason;

    return GestureDetector(
      onTap: isColliding ? null : onTap,
      child: Opacity(
        opacity: isColliding ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s4, vertical: DSSpacing.s2),
          decoration: BoxDecoration(
            color: c.bg.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(color: c.border.subtle, width: 1),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: const Color(0xFF000000).withValues(alpha: 0.06),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.lg - 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Accent bar ─────────────────────────────────────────
                  Container(width: 4, color: accentColor),

                  // ── Card body ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: title + date
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eventTypeLabel(job.eventType),
                                      style: DSTextStyle.headingMd
                                          .copyWith(color: c.text.primary),
                                    ),
                                    const SizedBox(height: 3),
                                    JobIdBadge(id: job.id),
                                    const SizedBox(height: 4),
                                    _MetaLine(job: job, colors: c),
                                  ],
                                ),
                              ),
                              const SizedBox(width: DSSpacing.s3),
                              _DateBlock(date: job.date, colors: c, bg: accentColor),
                            ],
                          ),
                        ),

                        // Price row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                          child: _PriceRow(
                            job: job,
                            musicianPrice: musicianPrice,
                            showBudgetIncrease: showBudgetIncrease,
                            colors: c,
                          ),
                        ),

                        // Chips
                        if (hasChips)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, 0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (isColliding)
                                  DSStatusBadge(
                                      label: 'Dato-konflikt',
                                      color: c.state.danger),
                                if (isAnotherRound)
                                  DSStatusBadge(
                                      label: 'Ny runde',
                                      color: c.state.warning),
                                if (job.requestedSaxophonist)
                                  DSStatusBadge(
                                      label: 'Sax søges',
                                      color: c.state.info),
                                if (isHighSeason)
                                  DSStatusBadge(
                                      label: 'Højsæson',
                                      color: c.state.info),
                              ],
                            ),
                          )
                        else if (isColliding || isAnotherRound)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, 0),
                            child: Wrap(
                              spacing: 6,
                              children: [
                                if (isColliding)
                                  DSStatusBadge(
                                      label: 'Dato-konflikt',
                                      color: c.state.danger),
                                if (isAnotherRound)
                                  DSStatusBadge(
                                      label: 'Ny runde',
                                      color: c.state.warning),
                              ],
                            ),
                          ),

                        // Action row
                        _ActionRow(job: job, colors: c),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date Block ─────────────────────────────────────────────────────────────

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.colors, required this.bg});
  final DateTime date;
  final DSColors colors;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final day = date.day.toString();
    final month =
        DateFormat('MMM', 'da_DK').format(date).replaceAll('.', '').toUpperCase();
    final year = date.year.toString();

    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
              color: c.brand.onPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              height: 1.1,
              color: c.brand.onPrimary.withValues(alpha: 0.75),
            ),
          ),
          Text(
            year,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: c.brand.onPrimary.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta Details ────────────────────────────────────────────────────────────

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.job, required this.colors});
  final Job job;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaItem(
          icon: LucideIcons.mapPin,
          label: job.city,
          colors: c,
        ),
        const SizedBox(height: 3),
        _MetaItem(
          icon: LucideIcons.clock,
          label: job.timeDisplay,
          colors: c,
        ),
        if (job.guestsAmount > 0) ...[
          const SizedBox(height: 3),
          _MetaItem(
            icon: LucideIcons.users,
            label: '${job.guestsAmount} gæster',
            colors: c,
          ),
        ],
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.text.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: DSTextStyle.bodyMd.copyWith(color: colors.text.secondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Price Row ───────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.job,
    required this.musicianPrice,
    required this.showBudgetIncrease,
    required this.colors,
  });

  final Job job;
  final int? musicianPrice;
  final bool showBudgetIncrease;
  final DSColors colors;

  String get _price {
    if (musicianPrice != null) return '${_fmt(musicianPrice!)} kr.';
    if (job.budgetStart == null) return 'Budget ikke angivet';
    final start = _fmt(job.budgetStart!.toInt());
    if (job.budgetEnd == null || job.budgetEnd == job.budgetStart) {
      return '$start kr.';
    }
    return '$start – ${_fmt(job.budgetEnd!.toInt())} kr.';
  }

  static String _fmt(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _price,
          style: DSTextStyle.headingSm.copyWith(
            color: c.text.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showBudgetIncrease && musicianPrice == null) ...[
          const SizedBox(width: 6),
          _BudgetIncreasePulse(colors: c),
        ],
      ],
    );
  }
}

// ─── Action Row ─────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.job, required this.colors});

  final Job job;
  final DSColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, DSSpacing.s3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => JobSummaryBottomSheet(job: job),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkle,
                size: 14, color: c.brand.primaryActive),
            const SizedBox(width: 5),
            Text(
              'AI oversigt',
              style: DSTextStyle.labelSm.copyWith(
                color: c.brand.primaryActive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Budget Increase Pulse ───────────────────────────────────────────────────

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
      builder: (_, __) => Row(
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
