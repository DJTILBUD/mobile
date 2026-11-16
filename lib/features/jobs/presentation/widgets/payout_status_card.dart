import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/my_payout.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// "Udbetaling" on the performer's own played job: when the money goes out, when it is at the
/// latest on their account (bank date + 3), and the afregning PDF once it has been emailed.
/// Renders nothing when the job has no self-billing payout. Copy mirrors web
/// `src/components/PayoutStatusCard.tsx`; keep them in step.
class PayoutStatusCard extends ConsumerWidget {
  const PayoutStatusCard({
    super.key,
    this.jobId,
    this.extJobId,
    this.onOpenPaymentInfo,
  });

  /// Exactly one of [jobId] / [extJobId].
  final int? jobId;
  final int? extJobId;

  /// Opens the payment-info screen, for the "waiting for your bank details" state.
  final VoidCallback? onOpenPaymentInfo;

  static String _day(DateTime d) =>
      DateFormat('EEEE d. MMMM', 'da_DK').format(d);

  static String _kr(double amount) =>
      '${NumberFormat.decimalPatternDigits(locale: 'da_DK', decimalDigits: amount % 1 == 0 ? 0 : 2).format(amount)} kr.';

  String _text(MyPayout p) {
    final amount = p.amountDkk != null ? _kr(p.amountDkk!) : 'dit honorar';
    switch (p.state) {
      case MyPayoutState.scheduled:
        return 'Vi overfører $amount ${p.isForecast ? 'omkring ' : ''}${_day(p.executionDate!)}. '
            'Pengene er senest på din konto ${_day(p.latestOnAccountDate!)}, men vi regner med, '
            'at de er der lidt før.';
      case MyPayoutState.paid:
        return 'Betalingen på $amount er godkendt i banken og overføres ${_day(p.executionDate!)}. '
            'Pengene er senest på din konto ${_day(p.latestOnAccountDate!)}.';
      case MyPayoutState.waiting:
        final what =
            p.waitingFor == 'missing_cvr'
                ? 'dit CVR-nummer'
                : 'dine bankoplysninger';
        return 'Udbetalingen venter på $what. Udfyld dem under Udbetaling, så sender vi pengene '
            'med næste udbetaling.';
      case MyPayoutState.preparing:
        return 'Vi gør udbetalingen klar. Datoen kommer her, så snart den er på plads.';
      case MyPayoutState.manual:
        return 'Dette job udbetales uden for den faste ugentlige udbetaling. '
            'Skriv til os, hvis du har spørgsmål til betalingen.';
    }
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Afregningen kunne ikke åbnes.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payout =
        ref
            .watch(myPayoutProvider((jobId: jobId, extJobId: extJobId)))
            .valueOrNull;
    if (payout == null) return const SizedBox.shrink();
    final hasDate =
        payout.executionDate != null && payout.latestOnAccountDate != null;
    if ((payout.state == MyPayoutState.scheduled ||
            payout.state == MyPayoutState.paid) &&
        !hasDate) {
      return const SizedBox.shrink();
    }

    final c = DSTheme.of(context);
    // Carries its own bottom gap so a hidden card leaves no empty space in the job's list.
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.state.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.wallet, size: 18, color: c.state.success),
                const SizedBox(width: DSSpacing.s2),
                Text(
                  payout.state == MyPayoutState.paid
                      ? 'Udbetalt'
                      : 'Udbetaling',
                  style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              _text(payout),
              style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
            ),
            if (payout.state == MyPayoutState.waiting &&
                onOpenPaymentInfo != null) ...[
              const SizedBox(height: DSSpacing.s3),
              DSButton(
                label: 'Udfyld betalingsoplysninger',
                variant: DSButtonVariant.secondary,
                size: DSButtonSize.sm,
                onTap: onOpenPaymentInfo,
              ),
            ],
            if (payout.documentUrl != null) ...[
              const SizedBox(height: DSSpacing.s3),
              DSButton(
                label: 'Hent afregning (PDF)',
                variant: DSButtonVariant.secondary,
                size: DSButtonSize.sm,
                onTap: () => _openPdf(context, payout.documentUrl!),
              ),
              if (payout.documentSbNumber != null) ...[
                const SizedBox(height: DSSpacing.s1),
                Text(
                  payout.documentSbNumber!,
                  style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
