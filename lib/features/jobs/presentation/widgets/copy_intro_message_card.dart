import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/phone_utils.dart';
import 'package:dj_tilbud_app/features/jobs/domain/customer_intro_message.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A ready-to-send intro message the performer can fire off after winning a job, to make contacting
/// the customer within 24h effortless (a recurring problem is DJs/saxes not reaching out fast enough).
/// The text is the canonical [buildCustomerIntroMessage], byte-identical to the web-app.
///
/// "Send besked" opens the OS message composer with the customer's number AND the message already
/// filled in, so sending is one tap. Copy stays as a secondary action: some performers send via
/// WhatsApp/mail instead, and it is the fallback when the composer cannot open.
class CopyIntroMessageCard extends StatelessWidget {
  const CopyIntroMessageCard({
    super.key,
    required this.leadName,
    required this.role,
    required this.performerName,
    this.phoneNumber,
  });

  /// Customer name.
  final String leadName;

  /// Danish role label: "DJ" or "saxofonist".
  final String role;

  /// The performer's own name (DJ: company/DJ name; sax: full name).
  final String performerName;

  /// The customer's raw phone number, straight from the DB. It is free text, so it can
  /// be a placeholder ("ikke oplyst") rather than a number — [dialablePhoneNumber] is
  /// what decides whether there is a real recipient to send to.
  final String? phoneNumber;

  String? get _smsNumber => dialablePhoneNumber(phoneNumber);

  bool get _canSms => _smsNumber != null;

  Future<void> _copy(BuildContext context, String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    DSToast.show(
      context,
      variant: DSToastVariant.success,
      title: 'Besked kopieret',
    );
  }

  Future<void> _sendSms(
    BuildContext context,
    String number,
    String message,
  ) async {
    // Built by hand rather than Uri(queryParameters:) so the body is always
    // percent-encoded: query encoding can render a space as '+', which the composer
    // would then show literally in the text. encodeComponent also handles the emojis
    // the canonical message contains, and (unlike encodeFull) escapes ?, & and #.
    //
    // '?body=' is verified to prefill on iOS 26 and is the RFC 5724 form Android wants.
    // Older advice to use '&body=' on iOS predates iOS 8-11 and no longer applies —
    // do not "fix" this to '&' without re-testing the body prefill on a real device.
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(message)}');

    try {
      // No canLaunchUrl() check on purpose — that would require declaring `sms` in
      // LSApplicationQueriesSchemes on iOS, which this app does not do (tel: is
      // launched the same unchecked way in sick_disclaimer.dart). Try, then fall back.
      final opened = await launchUrl(uri);
      if (!opened) throw Exception('launchUrl returned false');
    } catch (_) {
      // Simulator, no messaging app, or a blocked scheme. Never dead-end: put the
      // message on the clipboard so it can still be sent by hand.
      await Clipboard.setData(ClipboardData(text: message));
      if (!context.mounted) return;
      DSToast.show(
        context,
        variant: DSToastVariant.info,
        title: 'Kunne ikke åbne Beskeder – teksten er kopieret i stedet',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final number = _smsNumber;
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
            _canSms
                ? 'Send beskeden med det samme.'
                : 'Kopiér denne besked og send med det samme.',
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
          if (number != null) ...[
            DSButton(
              label: 'Send besked',
              iconLeft: LucideIcons.messageSquare,
              expand: true,
              onTap: () => _sendSms(context, number, message),
            ),
            const SizedBox(height: DSSpacing.s2),
          ],
          DSButton(
            label: 'Kopiér besked',
            variant: DSButtonVariant.secondary,
            expand: true,
            onTap: () => _copy(context, message),
          ),
        ],
      ),
    );
  }
}
