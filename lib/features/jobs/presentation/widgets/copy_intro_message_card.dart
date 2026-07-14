import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/customer_intro_message.dart';

/// A ready-to-send intro message the performer can copy after winning a job, to make contacting the
/// customer within 24h effortless (a recurring problem is DJs/saxes not reaching out fast enough).
/// The text is the canonical [buildCustomerIntroMessage], byte-identical to the web-app.
class CopyIntroMessageCard extends StatelessWidget {
  const CopyIntroMessageCard({
    super.key,
    required this.leadName,
    required this.role,
    required this.performerName,
  });

  /// Customer name.
  final String leadName;

  /// Danish role label: "DJ" or "saxofonist".
  final String role;

  /// The performer's own name (DJ: company/DJ name; sax: full name).
  final String performerName;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final message = buildCustomerIntroMessage(
      leadName: leadName,
      role: role,
      performerName: performerName,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.bg.inputBg,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forslag til besked',
            style: DSTextStyle.labelMd.copyWith(
              color: _c.text.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            'Gør det nemt at tage kontakt til kunden.',
            style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
          ),
          const SizedBox(height: 2),
          Text(
            'Kopiér denne besked og send med det samme.',
            style: DSTextStyle.bodySm.copyWith(
              color: _c.text.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            message,
            style: DSTextStyle.bodyMd.copyWith(
              color: _c.text.primary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSButton(
            label: 'Kopiér besked',
            variant: DSButtonVariant.secondary,
            expand: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
              DSToast.show(
                context,
                variant: DSToastVariant.success,
                title: 'Besked kopieret',
              );
            },
          ),
        ],
      ),
    );
  }
}
