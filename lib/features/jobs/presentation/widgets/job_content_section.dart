import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/job_content_provider.dart';

const _examplesUrl = 'https://djtilbud.dk/eksempler-video-billeder/';

/// Step 5 content-capture prompt for one job (DJ-only). Pass exactly one of
/// [quoteId] / [extJobId]. Reminder + CTA only — the upload, library and delete
/// live on the dedicated "Mit content" profile screen, which this opens scoped
/// to the current job.
class JobContentSection extends ConsumerWidget {
  const JobContentSection({super.key, this.quoteId, this.extJobId});

  final int? quoteId;
  final int? extJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final key = JobContentKey(quoteId: quoteId, extJobId: extJobId);
    final count = ref.watch(jobContentProvider(key)).valueOrNull?.length ?? 0;

    return Container(
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
          Text('Husk at optage content 📸',
              style: DSTextStyle.headingSm.copyWith(fontSize: 15, color: c.text.primary)),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Optag korte klip hvor der er gang i festen. Vi redigerer dem og tilbyder at sætte dem '
            'på din profil, så du kan sælge flere jobs.',
            style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Krav: maks. $kContentVideoMaxSeconds sekunder · lodret 9:16 format.',
            style: DSTextStyle.labelMd.copyWith(color: c.text.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DSSpacing.s2),
          InkWell(
            onTap: () => launchUrl(Uri.parse(_examplesUrl), mode: LaunchMode.externalApplication),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.externalLink, size: 14, color: c.state.info),
                const SizedBox(width: DSSpacing.s1),
                Flexible(
                  child: Text('Se hvordan du gør det og eksempler på god content',
                      style: DSTextStyle.labelMd.copyWith(
                          color: c.state.info, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text('Se eksemplerne, før du optager.',
              style: DSTextStyle.labelSm.copyWith(color: c.text.muted)),
          if (count > 0) ...[
            const SizedBox(height: DSSpacing.s2),
            Text('Du har uploadet $count klip til dette job.',
                style: DSTextStyle.labelSm.copyWith(color: c.text.muted)),
          ],
          const SizedBox(height: DSSpacing.s3),
          DSButton(
            label: count > 0 ? 'Se / upload content' : 'Upload ny video',
            variant: DSButtonVariant.primary,
            expand: true,
            onTap: () => context.pushNamed(AppRoutes.myContent, extra: key),
          ),
        ],
      ),
    );
  }
}
