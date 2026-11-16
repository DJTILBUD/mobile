import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/equipment_delivery.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_delivery_form.dart';

/// "Levering af udstyr" on a non-equipped DJ's won internal job: our delivery partner (WKNDS)
/// brings the gear, and the DJ collects the logistics from the customer and fills them in here.
/// Kept short on purpose: one status line, the form grouped by deadline, and the gear list +
/// checklist folded away. Everything comes from `GET /api/deliveries/job/{job_id}`
/// ([equipmentDeliveryProvider]); the section renders nothing when the job has no delivery or the
/// lookup failed. Carries its own bottom gap so a hidden section leaves no hole. Plan:
/// `web-app/documentation/non-equipped-djs-plan.md`, "Opgave 4 og 5, v1".
class EquipmentDeliverySection extends ConsumerWidget {
  const EquipmentDeliverySection({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivery = ref.watch(equipmentDeliveryProvider(jobId)).valueOrNull;
    if (delivery == null) return const SizedBox.shrink();
    final c = DSTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DSSpacing.s4),
            decoration: BoxDecoration(
              color: c.bg.surface,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: c.border.subtle),
              boxShadow: DSShadow.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.truck, size: 18, color: c.text.secondary),
                    const SizedBox(width: DSSpacing.s2),
                    Text(
                      'Leveringsdetaljer',
                      style: DSTextStyle.headingSm.copyWith(
                        fontSize: 15,
                        color: c.text.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.s3),
                _StatusLine(delivery: delivery),
                const SizedBox(height: DSSpacing.s4),
                EquipmentDeliveryForm(
                  key: ValueKey('delivery-form-${delivery.id}'),
                  delivery: delivery,
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          _GearAndChecklist(delivery: delivery),
        ],
      ),
    );
  }
}

/// One line: cancelled, all filled in, or the next deadline.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.delivery});
  final EquipmentDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    if (delivery.isCanceled) {
      return _Pill(
        icon: LucideIcons.xCircle,
        color: c.state.danger,
        text: 'Leveringen er aflyst',
      );
    }
    if (delivery.missing.isEmpty) {
      return _Pill(
        icon: LucideIcons.checkCircle,
        color: c.state.success,
        text: 'Alle detaljer er udfyldt',
      );
    }
    final due = delivery.dueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = due != null && due.isBefore(today);
    return _Pill(
      icon: LucideIcons.alertCircle,
      color: overdue ? c.state.danger : c.state.warning,
      text:
          overdue
              ? 'Fristen er passeret. Udfyld hurtigst muligt'
              : due != null
              ? 'Udfyld senest ${DateFormat('EEEE d. MMMM', 'da_DK').format(due)}'
              : 'Udfyld detaljerne nedenfor',
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Text(
              text,
              style: DSTextStyle.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: c.text.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What gets delivered + the day's checklist, folded by default: useful once, noise every visit.
class _GearAndChecklist extends StatelessWidget {
  const _GearAndChecklist({required this.delivery});
  final EquipmentDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
          childrenPadding: const EdgeInsets.fromLTRB(
            DSSpacing.s4,
            0,
            DSSpacing.s4,
            DSSpacing.s4,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(LucideIcons.package, size: 16, color: c.text.muted),
          title: Text(
            'Udstyr og tjekliste',
            style: DSTextStyle.labelMd.copyWith(
              color: c.text.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            if (delivery.gear.isNotEmpty) ...[
              const _Label('Vi leverer'),
              for (final item in delivery.gear) _Bullet(item),
            ],
            if (delivery.djBrings.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.s3),
              const _Label('Du medbringer'),
              _Bullet(delivery.djBrings),
            ],
            if (delivery.checklist.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.s3),
              const _Label('På dagen'),
              for (final item in delivery.checklist) _Bullet(item),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s1),
      child: Text(
        text,
        style: DSTextStyle.labelMd.copyWith(
          fontWeight: FontWeight.w600,
          color: c.text.primary,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '• $text',
        style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
      ),
    );
  }
}
