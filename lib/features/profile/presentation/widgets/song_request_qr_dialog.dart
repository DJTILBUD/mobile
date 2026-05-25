import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

const _publicBaseUrl = 'https://app.djtilbud.dk';

/// Shows the DJ's single, reusable song-request QR code.
///
/// The token is stable; on every scan the web resolver maps it to the DJ's
/// soonest upcoming event, so one printed code works for every gig.
Future<void> showSongRequestQrDialog(BuildContext context, String token) {
  final c = DSTheme.of(context);
  final url = '$_publicBaseUrl/song-request/$token';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.bg.surface,
      title: Text(
        'QR-kode til sangønsker',
        style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DSSpacing.s3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DSRadius.md),
              ),
              child: SizedBox(
                width: 220,
                height: 220,
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.s3),
            Text(
              'Én fast QR-kode til alle dine jobs. Gæsterne scanner og sender '
              'ønsker til dit næste kommende arrangement.',
              textAlign: TextAlign.center,
              style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        DSButton(
          label: 'Kopiér link',
          variant: DSButtonVariant.secondary,
          size: DSButtonSize.sm,
          iconLeft: LucideIcons.copy,
          onTap: () {
            Clipboard.setData(ClipboardData(text: url));
            DSToast.show(context, variant: DSToastVariant.success, title: 'Link kopieret!');
          },
        ),
        DSButton(
          label: 'Luk',
          variant: DSButtonVariant.ghost,
          size: DSButtonSize.sm,
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
