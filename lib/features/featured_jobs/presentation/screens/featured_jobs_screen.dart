import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/widgets/animated_card.dart';
import 'package:dj_tilbud_app/core/widgets/skeleton_loading.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/empty_jobs_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class FeaturedJobsScreen extends ConsumerWidget {
  const FeaturedJobsScreen({super.key});

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extJobsAsync = ref.watch(djExtJobsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _c.bg.canvas,
        appBar: AppBar(
          title: const Text('Udvalgte jobs'),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          bottom: DSTabBar(
            tabs: [
              DSTabItem(
                label: 'Kommende',
                activeColor: _c.state.success,
              ),
              DSTabItem(
                label: 'Spillet',
                activeColor: _c.text.muted,
              ),
            ],
          ),
        ),
        body: extJobsAsync.when(
          loading: () => const SkeletonListView(),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(djExtJobsProvider),
          ),
          data: (extJobs) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final kommende = extJobs
                .where((j) =>
                    !DateTime(j.date.year, j.date.month, j.date.day)
                        .isBefore(today))
                .toList();
            final spillet = extJobs
                .where((j) =>
                    DateTime(j.date.year, j.date.month, j.date.day)
                        .isBefore(today))
                .toList();

            return TabBarView(
              children: [
                _JobList(
                  jobs: kommende,
                  emptyMessage: 'Ingen kommende udvalgte jobs.',
                  onRefresh: () async => ref.invalidate(djExtJobsProvider),
                ),
                _JobList(
                  jobs: spillet,
                  emptyMessage: 'Du har ingen spillede jobs endnu.',
                  onRefresh: () async => ref.invalidate(djExtJobsProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Job List ────────────────────────────────────────────────────────────────

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final List<ExtJob> jobs;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return EmptyJobsView(message: emptyMessage, icon: LucideIcons.star);
    }
    return RefreshIndicator(
      color: lightColors.brand.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: jobs.length,
        itemBuilder: (context, index) => AnimatedCard(
          index: index,
          child: _ExtJobCard(
            extJob: jobs[index],
            onTap: () => context.pushNamed(
              AppRoutes.extJobDetail,
              extra: jobs[index],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ext Job Card ────────────────────────────────────────────────────────────

class _ExtJobCard extends StatelessWidget {
  const _ExtJobCard({required this.extJob, required this.onTap});

  final ExtJob extJob;
  final VoidCallback onTap;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final accentColor = _c.state.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s4, vertical: DSSpacing.s2),
        decoration: BoxDecoration(
          color: _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(color: _c.border.subtle, width: 1),
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
                // ── Accent bar ─────────────────────────────────────────────
                Container(width: 4, color: accentColor),

                // ── Card body ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: event type + date block
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          eventTypeLabel(extJob.displayEventType),
                                          style: DSTextStyle.headingMd
                                              .copyWith(color: _c.text.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      JobIdBadge(id: extJob.id, isExtJob: true),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _MetaList(extJob: extJob, c: _c),
                                ],
                              ),
                            ),
                            const SizedBox(width: DSSpacing.s3),
                            _DateBlock(
                              date: extJob.date,
                              bg: _c.brand.primary,
                              fg: _c.brand.onPrimary,
                            ),
                          ],
                        ),
                      ),

                      // Price row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                        child: _PriceRow(extJob: extJob, c: _c),
                      ),

                      const SizedBox(height: DSSpacing.s3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date Block ──────────────────────────────────────────────────────────────

class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.date,
    required this.bg,
    required this.fg,
  });

  final DateTime date;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString();
    final month = DateFormat('MMM', 'da_DK')
        .format(date)
        .replaceAll('.', '')
        .toUpperCase();
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
              color: fg,
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
              color: fg.withValues(alpha: 0.75),
            ),
          ),
          Text(
            year,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: fg.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta List ───────────────────────────────────────────────────────────────

class _MetaList extends StatelessWidget {
  const _MetaList({required this.extJob, required this.c});

  final ExtJob extJob;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaItem(
            icon: LucideIcons.mapPin,
            label: extJob.displayLocation,
            c: c),
        const SizedBox(height: 3),
        _MetaItem(
            icon: LucideIcons.clock,
            label: extJob.timeDisplay,
            c: c),
        if (extJob.guestsAmount != null) ...[
          const SizedBox(height: 3),
          _MetaItem(
              icon: LucideIcons.users,
              label: '${extJob.guestsAmount} gæster',
              c: c),
        ],
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, required this.c});

  final IconData icon;
  final String label;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: c.text.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Price Row ───────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.extJob, required this.c});

  final ExtJob extJob;
  final DSColors c;

  static String _fmt(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  String get _priceLabel {
    if (extJob.honorar != null) return '${_fmt(extJob.honorar!.toInt())} kr. (honorar)';
    if (extJob.fullAmount != null) return '${_fmt(extJob.fullAmount!.toInt())} kr.';
    if (extJob.budgetTarget != null && extJob.budgetTarget!.isNotEmpty) {
      return extJob.budgetTarget!;
    }
    return 'Ikke angivet';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: c.brand.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.banknote, size: 14, color: c.brand.primaryActive),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _priceLabel,
              style: DSTextStyle.headingSm.copyWith(
                color: c.text.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: _c.state.danger),
            const SizedBox(height: DSSpacing.s4),
            Text(
              'Noget gik galt',
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              message,
              style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.s4),
            DSButton(
              label: 'Prøv igen',
              variant: DSButtonVariant.primary,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
