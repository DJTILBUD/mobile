import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job_action.dart';

class ServiceOfferCard extends StatelessWidget {
  const ServiceOfferCard({super.key, required this.offer, this.onTap, this.isPlayed = false});

  final ServiceOffer offer;
  final VoidCallback? onTap;
  final bool isPlayed;

  static DateTime _deadline(ServiceOffer o) {
    if (o.job.deadlineExtendedUntil != null) return o.job.deadlineExtendedUntil!;
    final sevenDays = o.createdAt.add(const Duration(days: 7));
    final twoDaysBefore = o.job.date.subtract(const Duration(days: 2));
    return sevenDays.isBefore(twoDaysBefore) ? sevenDays : twoDaysBefore;
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final job = offer.job;

    final accentColor = switch (offer.status) {
      ServiceOfferStatus.sent => c.state.warning,
      ServiceOfferStatus.won => c.brand.primary,
      ServiceOfferStatus.lost => c.text.muted,
    };

    return GestureDetector(
      onTap: onTap,
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
                // ── Accent bar ──────────────────────────────────────────
                Container(width: 4, color: accentColor),

                // ── Card body ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: event type + meta + date block
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
                                  JobIdBadge(
                                    id: offer.extJobId ?? offer.jobId ?? 0,
                                    isExtJob: offer.isExtJob,
                                  ),
                                  const SizedBox(height: 4),
                                  _MetaList(job: job, c: c),
                                ],
                              ),
                            ),
                            const SizedBox(width: DSSpacing.s3),
                            _DateBlock(
                              date: job.date,
                              bg: isPlayed ? c.bg.inputBg : accentColor,
                              fg: isPlayed ? c.text.muted : c.brand.onPrimary,
                            ),
                          ],
                        ),
                      ),

                      // Bid row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                        child: _BidRow(offer: offer, c: c),
                      ),

                      // Bottom: countdown (sent) / action chip (won) / status badge
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, DSSpacing.s3),
                        child: offer.status == ServiceOfferStatus.sent
                            ? _CountdownRow(
                                deadline: _deadline(offer), c: c)
                            : offer.status == ServiceOfferStatus.won &&
                                    offer.pendingAction != null
                                ? _ActionChip(
                                    action: offer.pendingAction!, c: c)
                                : _StatusRow(offer: offer, c: c),
                      ),
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
      final _c = DSTheme.of(context);
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
  const _MetaList({required this.job, required this.c});

  final dynamic job;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaItem(icon: LucideIcons.mapPin, label: job.region, c: c),
        const SizedBox(height: 3),
        _MetaItem(icon: LucideIcons.clock, label: job.timeDisplay, c: c),
        if (job.guestsAmount > 0) ...[
          const SizedBox(height: 3),
          _MetaItem(
              icon: LucideIcons.users,
              label: '${job.guestsAmount} gæster',
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
      final _c = DSTheme.of(context);
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

// ─── Bid Row ─────────────────────────────────────────────────────────────────

class _BidRow extends StatelessWidget {
  const _BidRow({required this.offer, required this.c});

  final ServiceOffer offer;
  final DSColors c;

  static String _fmt(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final payout = offer.musicianPayoutDkk ?? offer.priceDkk;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: c.brand.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(LucideIcons.banknote, size: 14, color: c.brand.primaryActive),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Din udbetaling: ${_fmt(payout)} kr.',
                  style: DSTextStyle.headingSm.copyWith(
                    color: c.text.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Kundepris: ${_fmt(offer.priceDkk)} kr.',
                  style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Countdown Row ───────────────────────────────────────────────────────────

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.deadline, required this.c});

  final DateTime deadline;
  final DSColors c;

  String _label() {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) return 'Fristen er udløbet';
    if (diff.inDays >= 2) return 'Kunden skal svare inden ${diff.inDays} dage';
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return 'Kunden skal svare inden ${h}t ${m}m';
    }
    return 'Kunden skal svare inden ${diff.inMinutes} min';
  }

  bool get _isExpired => deadline.isBefore(DateTime.now());
  bool get _isUrgent =>
      !_isExpired && deadline.difference(DateTime.now()).inHours < 24;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final color = _isExpired
        ? c.state.danger
        : _isUrgent
            ? c.state.warning
            : c.text.secondary;

    final icon = _isExpired ? LucideIcons.timerOff : LucideIcons.hourglass;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          _label(),
          style: DSTextStyle.labelSm.copyWith(
            color: _isExpired ? color : _c.text.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Status Row ───────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.offer, required this.c});

  final ServiceOffer offer;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final (label, color) = switch (offer.status) {
      ServiceOfferStatus.sent => ('Afventer', c.state.warning),
      ServiceOfferStatus.won => ('Vundet', c.state.success),
      ServiceOfferStatus.lost => ('Tabt', c.text.muted),
    };

    return DSStatusBadge(label: label, color: color);
  }
}

// ─── Action Chip ─────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.c});

  final JobActionType action;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final (label, color, icon) = switch (action) {
      JobActionType.contactCustomer => (
          'Kontakt kunden nu',
          c.state.danger,
          LucideIcons.phone,
        ),
      JobActionType.contactCustomerPlanned => (
          'Kontakt kunden planlagt',
          c.state.warning,
          LucideIcons.calendarClock,
        ),
      JobActionType.readyForBilling => (
          'Luk aftale og send faktura',
          c.state.danger,
          LucideIcons.fileCheck,
        ),
      JobActionType.moveToReady => (
          'Luk aftale og send faktura',
          c.state.danger,
          LucideIcons.fileCheck,
        ),
      JobActionType.confirmReady => (
          'Bekræft klar!',
          c.state.danger,
          LucideIcons.checkCircle,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
