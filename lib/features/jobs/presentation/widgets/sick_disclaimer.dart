import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

const sickLeavePhone = '60 14 86 98';
const _djTermsUrl = 'https://djtilbud.dk/dj-handelsbetingelser/';
const _musicianTermsUrl = 'https://djtilbud.dk/handelsbetingelser-instrumentalister/';

/// "What happens if I get sick?" disclaimer. Subtle collapsed fold-out, shown on
/// committed jobs for both DJs and musicians. The terms link (pkt. 3.1) points
/// to the role-specific handelsbetingelser page. Pass role 'dj' or 'musician'.
class SickDisclaimer extends StatefulWidget {
  const SickDisclaimer({super.key, required this.role});

  final String role;

  @override
  State<SickDisclaimer> createState() => _SickDisclaimerState();
}

class _SickDisclaimerState extends State<SickDisclaimer> {
  late final TapGestureRecognizer _callRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _callRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('tel:${sickLeavePhone.replaceAll(' ', '')}'));
    final termsUrl = widget.role == 'musician' ? _musicianTermsUrl : _djTermsUrl;
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(termsUrl), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _callRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final body = DSTextStyle.labelMd.copyWith(color: c.text.secondary);
    final linkStyle = body.copyWith(
      color: c.state.info,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
          childrenPadding: const EdgeInsets.fromLTRB(DSSpacing.s4, 0, DSSpacing.s4, DSSpacing.s4),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(LucideIcons.alertTriangle, size: 16, color: c.text.muted),
          title: Text(
            'Hvad sker der, hvis jeg bliver syg?',
            style: DSTextStyle.labelMd.copyWith(color: c.text.secondary, fontWeight: FontWeight.w600),
          ),
          children: [
            Text.rich(
              TextSpan(
                style: body,
                children: [
                  const TextSpan(text: 'Ring til os med det samme på '),
                  TextSpan(text: sickLeavePhone, style: linkStyle, recognizer: _callRecognizer),
                  const TextSpan(
                    text: ' – ikke næste dag. Har du mistanke om sygdom dagen inden, '
                        'så giv os besked allerede der.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.s2),
            Text(
              'Det er dit ansvar at finde en erfaren afløser til samme løn. Vi forbeholder os stadig '
              'retten til at tjekke og afvise den DJ, du har udvalgt.',
              style: body,
            ),
            const SizedBox(height: DSSpacing.s2),
            Text.rich(
              TextSpan(
                style: body,
                children: [
                  const TextSpan(
                    text: 'Såfremt du ikke kan finde en DJ, så træder vi ind. Vi gør vores bedste for '
                        'at finde en DJ til den løn, du var berrettiget til og ikke mere. Dog '
                        'forbeholder vi os retten jf. pkt. 3.1 (',
                  ),
                  TextSpan(text: 'handelsbetingelser', style: linkStyle, recognizer: _termsRecognizer),
                  const TextSpan(
                    text: '), til at vi kan tilbageholde eller fakturere dig 50% af jobbets løn ekstra. '
                        'I dette tilfælde vil den ekstra omkostning for erstatnings DJ\'ens løn '
                        'tilfalde dig, da det er din kunde og dit ansvar.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
