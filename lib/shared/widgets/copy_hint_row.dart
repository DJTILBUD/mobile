import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';

/// A small tappable "Kopier" affordance that copies [text] to the clipboard and shows a success
/// toast. Used under the customer-request / notes blocks so a DJ/musician can grab the text in one
/// tap (selecting text by hand is painful on mobile).
class CopyHintRow extends StatelessWidget {
  const CopyHintRow({
    super.key,
    required this.text,
    this.copiedTitle = 'Kopieret',
  });

  final String text;
  final String copiedTitle;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: copiedTitle,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.copy, size: 13, color: c.text.muted),
          const SizedBox(width: DSSpacing.s1),
          Text(
            'Kopier',
            style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
          ),
        ],
      ),
    );
  }
}
