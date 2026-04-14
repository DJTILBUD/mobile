import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job_action.dart';

class ServiceOfferCard extends StatelessWidget {
  const ServiceOfferCard({super.key, required this.offer, this.onTap});

  final ServiceOffer offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final job = offer.job;
    final dateStr = DateFormat('d. MMM yyyy', 'da_DK').format(job.date);

    final statusColor = switch (offer.status) {
      ServiceOfferStatus.sent => c.state.warning,
      ServiceOfferStatus.won => c.state.success,
      ServiceOfferStatus.lost => c.text.muted,
    };

    final statusLabel = switch (offer.status) {
      ServiceOfferStatus.sent => 'Afsendt',
      ServiceOfferStatus.won => 'Accepteret',
      ServiceOfferStatus.lost => 'Tabt',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s4, vertical: DSSpacing.s1),
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.border.subtle),
          boxShadow: DSShadow.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DSRadius.md),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status indicator bar
                Container(width: 4, color: statusColor),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(DSSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + status badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                eventTypeLabel(job.eventType),
                                style: DSTextStyle.headingSm
                                    .copyWith(color: c.text.primary),
                              ),
                            ),
                            const SizedBox(width: DSSpacing.s2),
                            DSStatusBadge(label: statusLabel, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 3),
                        JobIdBadge(
                          id: offer.extJobId ?? offer.jobId ?? 0,
                          isExtJob: offer.isExtJob,
                        ),
                        const SizedBox(height: DSSpacing.s2),

                        // Date + location
                        Row(
                          children: [
                            Icon(LucideIcons.calendar,
                                size: 13, color: c.text.muted),
                            const SizedBox(width: 4),
                            Text(dateStr,
                                style: DSTextStyle.labelSm
                                    .copyWith(color: c.text.secondary)),
                            const SizedBox(width: DSSpacing.s3),
                            Icon(LucideIcons.mapPin,
                                size: 13, color: c.text.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${job.city}, ${job.region}',
                                style: DSTextStyle.labelSm
                                    .copyWith(color: c.text.secondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DSSpacing.s3),

                        // Price + instrument
                        Row(
                          children: [
                            DSInfoChip(
                              icon: LucideIcons.banknote,
                              label: '${offer.priceDkk} kr.',
                              highlight: true,
                            ),
                            const SizedBox(width: DSSpacing.s2),
                            DSInfoChip(
                              icon: LucideIcons.mic,
                              label: offer.instrument,
                            ),
                          ],
                        ),

                        // Action indicator for won offers
                        if (offer.pendingAction != null) ...[
                          const SizedBox(height: DSSpacing.s2),
                          _OfferActionRow(action: offer.pendingAction!, c: c),
                        ],
                      ],
                    ),
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

// ─── Action Row ───────────────────────────────────────────────────────────────

class _OfferActionRow extends StatelessWidget {
  const _OfferActionRow({required this.action, required this.c});

  final JobActionType action;
  final DSColors c;

  @override
  Widget build(BuildContext context) {
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
