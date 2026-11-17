import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/wknds_delivery.dart';

/// The fixed WKNDS setup, shown to a non-equipped DJ.
///
/// [forQuote] = in the quote form / edit sheet, where it replaces the gear
/// picker and the early-setup switch (mirrors web `DeliveredSetupNotice`).
/// Otherwise it is the "Dit udstyr" profile card (mirrors web
/// `DeliveredEquipmentCard`). Never mentions what the delivery costs.
// @uxid lib/shared/widgets/delivered_setup_notice.dart::DeliveredSetupNotice
class DeliveredSetupNotice extends StatelessWidget {
  const DeliveredSetupNotice({super.key, this.forQuote = true});

  final bool forQuote;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.truck, size: 18, color: c.text.primary),
              const SizedBox(width: DSSpacing.s2),
              Text(
                forQuote ? 'Udstyr og tidlig opsætning' : 'Dit udstyr',
                style: DSTextStyle.labelLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            forQuote
                ? 'Udstyret bliver leveret og sat op, før du kommer. Kunden ser '
                    'derfor dit tilbud med tidlig opsætning inkluderet og det '
                    'samme udstyr som på alle leverede jobs:'
                : 'Udstyret bliver leveret, sat op og taget ned igen til hvert job:',
            style: DSTextStyle.bodySm.copyWith(
              color: c.text.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          for (final item in wkndsDeliveredGear)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '•  $item',
                style: DSTextStyle.bodySm.copyWith(color: c.text.primary),
              ),
            ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            wkndsDjBrings,
            style: DSTextStyle.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text.primary,
            ),
          ),
        ],
      ),
    );
  }
}
