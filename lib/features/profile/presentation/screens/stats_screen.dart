import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/performer_stats.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/stats_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Danish thousands grouping ("12.400 kr."). Done by hand rather than via intl's
/// locale data so it cannot depend on locale initialisation being set up.
String _fmtKr(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buf kr.';
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);

    // On sign-out this pushed screen can rebuild before the router redirects away.
    // The session-scoped providers below resolve `supabase.auth.currentUser!.id` in
    // their factories, so they throw the moment the session is gone. Render nothing
    // until the redirect catches up. Same guard, same reason, as main_shell.dart.
    if (!ref.watch(hasSessionProvider)) return const SizedBox.shrink();

    final statsAsync = ref.watch(performerStatsProvider(role));
    final years = ref.watch(statsYearsProvider(role));
    final selectedYear = ref.watch(statsYearProvider);
    final excluded =
        ref.watch(statEntriesProvider(role)).valueOrNull?.excluded ?? 0;

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        title: Text(
          'Statistik',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        actions: [
          _YearFilter(years: years, selected: selectedYear),
          const SizedBox(width: DSSpacing.s2),
        ],
      ),
      body: statsAsync.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(color: c.brand.primary),
            ),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(DSSpacing.s6),
                child: Text(
                  'Kunne ikke hente din statistik. Prøv igen.',
                  style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        data: (stats) {
          if (stats.isEmpty) {
            return _EmptyState(
              hasOtherYears: years.isNotEmpty && selectedYear != null,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(DSSpacing.s4),
            children: [
              _SummaryRow(stats: stats, isYearScoped: selectedYear != null),
              const SizedBox(height: DSSpacing.s3),
              _Basis(hasUpcoming: stats.hasUpcoming),
              const SizedBox(height: DSSpacing.s6),
              _MonthlyEarnings(stats: stats),
              if (stats.byEventType.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.s6),
                _CategorySection(
                  title: 'Eventtyper',
                  buckets: stats.byEventType,
                  humanize: eventTypeLabel,
                ),
              ],
              if (stats.byRegion.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.s6),
                _CategorySection(
                  title: 'Hvor i landet',
                  buckets: stats.byRegion,
                ),
              ],
              const SizedBox(height: DSSpacing.s6),
              _GoodToKnow(stats: stats),
              if (excluded > 0) ...[
                const SizedBox(height: DSSpacing.s4),
                _ExcludedNote(count: excluded),
              ],
              const SizedBox(height: DSSpacing.s6),
            ],
          );
        },
      ),
    );
  }
}

class _YearFilter extends ConsumerWidget {
  const _YearFilter({required this.years, required this.selected});

  final List<int> years;
  final int? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final thisYear = DateTime.now().year;
    final label =
        selected == null
            ? 'Alle'
            : (selected == thisYear ? 'I år' : selected.toString());

    return PopupMenuButton<int?>(
      onSelected: (v) => ref.read(statsYearProvider.notifier).state = v,
      itemBuilder:
          (_) => [
            for (final y in years)
              PopupMenuItem<int?>(
                value: y,
                child: Text(y == thisYear ? 'I år ($y)' : y.toString()),
              ),
            const PopupMenuItem<int?>(value: null, child: Text('Alle')),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: DSTextStyle.labelMd.copyWith(color: c.text.primary),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 16, color: c.text.secondary),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats, required this.isYearScoped});

  final PerformerStats stats;
  final bool isYearScoped;

  @override
  Widget build(BuildContext context) {
    // "Tjent" is ONLY the bookings whose event has passed. ready_for_billing jobs can
    // sit months ahead, so lumping those in and calling it earned would overstate the
    // performer's money — hence the separate "Kommende" card.
    //
    // IntrinsicHeight is what makes CrossAxisAlignment.stretch legal here: a Row's
    // cross axis is vertical, and inside a ListView the height is unbounded, so
    // stretch alone asks for infinite height and throws. IntrinsicHeight bounds the
    // Row to its tallest card, which is also what we want visually — equal-height
    // cards even when one value wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              value: _fmtKr(stats.earnedDkk),
              label: isYearScoped ? 'Tjent' : 'Tjent i alt',
              sublabel: '${stats.earnedJobCount} spillet',
            ),
          ),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: _StatCard(
              value: _fmtKr(stats.upcomingDkk),
              label: 'Kommende',
              sublabel: '${stats.upcomingJobCount} booket',
              muted: true,
            ),
          ),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: _StatCard(
              value: _fmtKr(stats.avgPerJobDkk),
              label: 'Snit pr. job',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.sublabel,
    this.muted = false,
  });

  final String value;
  final String label;

  /// Small qualifier under the label (e.g. how many jobs the figure covers).
  final String? sublabel;

  /// Dims the value — used for money that is booked but not yet earned.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return DSSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: DSTextStyle.headingSm.copyWith(
                color: muted ? c.text.secondary : c.text.primary,
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(label, style: DSTextStyle.bodySm.copyWith(color: c.text.muted)),
          if (sublabel != null)
            Text(
              sublabel!,
              style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DSTextStyle.labelLg.copyWith(color: c.text.primary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
          ),
        ],
        const SizedBox(height: DSSpacing.s3),
      ],
    );
  }
}

/// A labelled progress bar. [fraction] is 0..1 of the section's max value.
///
/// TWO-TONE: [fraction] is drawn in the "upcoming" colour and [earnedFraction] is
/// drawn in lime on top, so a month reads instantly as fully earned, fully ahead, or
/// part-and-part. Pass earnedFraction == fraction for a plain solid bar.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
    this.earnedFraction,
    this.trailing,
    this.splitEarned,
    this.splitUpcoming,
  });

  final String label;
  final String value;
  final double fraction;

  /// Lime (earned) portion. Defaults to the whole bar (nothing upcoming).
  final double? earnedFraction;
  final String? trailing;

  /// When a row is part earned / part upcoming, the one total above is ambiguous —
  /// these render the two amounts under the bar, colour-matched to its segments.
  final String? splitEarned;
  final String? splitUpcoming;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: DSTextStyle.bodySm.copyWith(color: c.text.secondary),
                ),
              ),
              Text(
                value,
                style: DSTextStyle.labelMd.copyWith(color: c.text.primary),
              ),
              if (trailing != null) ...[
                Text(
                  ' · $trailing',
                  style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // TWO colours, and nothing else. There is deliberately NO track behind the
          // bar: the empty remainder carried no meaning, and being grey it collided
          // with the grey that DOES mean something. Bar length alone carries the
          // amount (a track is a progress-bar idiom, not a chart one), so now every
          // coloured pixel means exactly one thing.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              width: double.infinity,
              child: Stack(
                children: [
                  // Grey = kommende: the part of this month still to be played.
                  // Softened so it sits behind the green rather than competing with
                  // it. Alpha is safe for the grey (it just lightens toward the
                  // surface and stays unmistakably grey) — it was NOT safe for the
                  // lime, which is a light tint and vanished when faded.
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(
                      color: c.text.muted.withValues(alpha: 0.6),
                    ),
                  ),
                  // Green = tjent, drawn over the left of it.
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (earnedFraction ?? fraction).clamp(0.0, 1.0),
                    child: Container(color: c.brand.primary),
                  ),
                ],
              ),
            ),
          ),
          if (splitEarned != null || splitUpcoming != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                if (splitEarned != null)
                  Text(
                    splitEarned!,
                    // primaryActive, not primary: the lime is a background token and
                    // is unreadable as text on a light surface.
                    style: DSTextStyle.bodySm.copyWith(
                      color: c.brand.primaryActive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (splitEarned != null && splitUpcoming != null)
                  Text(
                    '  ·  ',
                    style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
                  ),
                if (splitUpcoming != null)
                  Text(
                    splitUpcoming!,
                    // text.secondary, not the accent: #66D0F2 is a poor contrast for
                    // small text on a light surface, and a second loud colour here
                    // fights the bar. The order (earned, then upcoming) plus the
                    // legend already maps each number to its segment.
                    style: DSTextStyle.bodySm.copyWith(
                      color: c.text.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyEarnings extends StatelessWidget {
  const _MonthlyEarnings({required this.stats});

  final PerformerStats stats;

  @override
  Widget build(BuildContext context) {
    // Newest month first reads better on a phone than a chronological axis.
    final months = stats.byMonth.reversed.toList();
    final max = months.fold<int>(0, (m, b) => b.totalDkk > m ? b.totalDkk : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Indtjening måned for måned',
          // Be explicit: this is not a payout statement, it is grouped by when
          // the performer plays.
          subtitle: 'Efter eventdato',
        ),
        // Without this key the two bar colours mean nothing — a grey bar just reads
        // as "wrong". Only shown when there IS something upcoming to distinguish.
        if (stats.hasUpcoming) ...[
          const _BarLegend(),
          const SizedBox(height: DSSpacing.s3),
        ],
        for (final b in months)
          _BarRow(
            label: '${danishMonthName(b.month)} ${b.year}',
            value: _fmtKr(b.totalDkk),
            trailing: '${b.jobs} ${b.jobs == 1 ? 'job' : 'jobs'}',
            fraction: max == 0 ? 0 : b.totalDkk / max,
            earnedFraction: max == 0 ? 0 : (b.totalDkk - b.upcomingDkk) / max,
            // Only a MIXED month needs the amounts spelled out — for an all-earned or
            // all-upcoming month the single total above already is that number.
            splitEarned:
                b.isPartlyUpcoming ? _fmtKr(b.totalDkk - b.upcomingDkk) : null,
            splitUpcoming: b.isPartlyUpcoming ? _fmtKr(b.upcomingDkk) : null,
          ),
      ],
    );
  }
}

/// Key for the two-tone bars. Uses the exact same colours as [_BarRow], so the
/// swatches can never drift from what is drawn.
class _BarLegend extends StatelessWidget {
  const _BarLegend();

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Row(
      children: [
        // "Spillet", not "Tjent": this key covers the category bars too, and those are
        // scaled by JOB COUNT — green there means jobs played, not kroner earned.
        _LegendSwatch(color: c.brand.primary, label: 'Spillet'),
        const SizedBox(width: DSSpacing.s4),
        // Must be the exact colour the bar uses, softening included, or the key lies.
        _LegendSwatch(
          color: c.text.muted.withValues(alpha: 0.6),
          label: 'Kommende',
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: DSTextStyle.bodySm.copyWith(color: c.text.muted)),
      ],
    );
  }
}

/// Explains the basis of every number on the page: these are ready_for_billing
/// bookings, which can include events that have not happened yet.
class _Basis extends StatelessWidget {
  const _Basis({required this.hasUpcoming});

  final bool hasUpcoming;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 14, color: c.text.muted),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            hasUpcoming
                ? 'Tallene dækker jobs, der er klar til fakturering. "Kommende" er '
                    'booket, men endnu ikke spillet — og derfor ikke tjent endnu.'
                : 'Tallene dækker jobs, der er klar til fakturering.',
            style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.buckets,
    this.humanize,
  });

  final String title;
  final List<CategoryBucket> buckets;
  final String Function(String)? humanize;

  @override
  Widget build(BuildContext context) {
    final max = buckets.fold<int>(0, (m, b) => b.jobs > m ? b.jobs : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        for (final b in buckets)
          _BarRow(
            label: humanize?.call(b.label) ?? b.label,
            value: '${b.jobs} ${b.jobs == 1 ? 'job' : 'jobs'}',
            trailing: _fmtKr(b.totalDkk),
            // These bars are scaled by JOB COUNT (not kr.), so the earned split must
            // be counted in jobs too.
            fraction: max == 0 ? 0 : b.jobs / max,
            // Green means "tjent" on every section of this screen. Without this the
            // same unplayed job rendered grey under the month list and full green
            // here — the page contradicting itself.
            earnedFraction: max == 0 ? 0 : (b.jobs - b.upcomingJobs) / max,
          ),
      ],
    );
  }
}

class _GoodToKnow extends StatelessWidget {
  const _GoodToKnow({required this.stats});

  final PerformerStats stats;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final rows = <({IconData icon, String text})>[];

    final busiest = stats.busiestMonth;
    if (busiest != null) {
      rows.add((
        icon: LucideIcons.calendar,
        text:
            'Travleste måned: ${danishMonthName(busiest.month)} ${busiest.year} '
            '(${busiest.jobs} ${busiest.jobs == 1 ? 'job' : 'jobs'})',
      ));
    }
    final weekday = stats.topWeekday;
    final share = stats.topWeekdayShare;
    if (weekday != null && share != null) {
      rows.add((
        icon: LucideIcons.clock,
        text:
            'Du spiller oftest ${danishWeekdayName(weekday)} '
            '(${(share * 100).round()}% af dine jobs)',
      ));
    }
    if (stats.avgGuests != null) {
      rows.add((
        icon: LucideIcons.users,
        text: 'Typisk ca. ${stats.avgGuests} gæster',
      ));
    }
    if (stats.topGenres.isNotEmpty) {
      rows.add((
        icon: LucideIcons.music,
        text: 'Mest efterspurgte genrer: ${stats.topGenres.join(', ')}',
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Godt at vide'),
        DSSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: DSSpacing.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(rows[i].icon, size: 16, color: c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        rows[i].text,
                        style: DSTextStyle.bodySm.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown only when some played bookings have no payout figure stored, so the totals
/// above are knowably incomplete rather than quietly wrong.
class _ExcludedNote extends StatelessWidget {
  const _ExcludedNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 14, color: c.text.muted),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'job mangler' : 'jobs mangler'} honorar-data og '
            'tæller ikke med i beløbene.',
            style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.hasOtherYears});

  final bool hasOtherYears;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.barChart2, size: 48, color: c.border.subtle),
            const SizedBox(height: DSSpacing.s3),
            Text(
              hasOtherYears
                  ? 'Ingen spillede jobs i den valgte periode'
                  : 'Ingen spillede jobs endnu',
              style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s1),
            Text(
              hasOtherYears
                  ? 'Prøv en anden periode.'
                  : 'Når du har spillet dit første job, kan du se din statistik her.',
              style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
              textAlign: TextAlign.center,
            ),
            if (hasOtherYears) ...[
              const SizedBox(height: DSSpacing.s4),
              DSButton(
                label: 'Vis alle',
                size: DSButtonSize.md,
                variant: DSButtonVariant.secondary,
                onTap: () => ref.read(statsYearProvider.notifier).state = null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
