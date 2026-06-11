import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/data/datasources/job_content_remote_datasource.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/job_content_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/content_video_player.dart';

const _examplesUrl = 'https://djtilbud.dk/eksempler-video-billeder/';

/// Profile library of all the DJ's job content clips. When opened from a job
/// (a non-null [scope]) it also shows a scoped uploader for that job; opened
/// from the profile menu it is the full library (view + delete).
class MyContentScreen extends ConsumerStatefulWidget {
  const MyContentScreen({super.key, this.scope});

  final JobContentKey? scope;

  @override
  ConsumerState<MyContentScreen> createState() => _MyContentScreenState();
}

class _MyContentScreenState extends ConsumerState<MyContentScreen> {
  bool _busy = false;
  double? _progress; // 0..1 upload progress, null when not uploading

  Future<void> _pickAndUpload() async {
    final scope = widget.scope;
    if (scope == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _busy = true;
      _progress = 0;
    });
    try {
      final error = await validateContentVideo(picked.path);
      if (error != null) {
        if (mounted)
          DSToast.show(context, variant: DSToastVariant.error, title: error);
        return;
      }
      await ref
          .read(jobContentDatasourceProvider)
          .uploadJobContent(
            userId: userId,
            filePath: picked.path,
            quoteId: scope.quoteId,
            extJobId: scope.extJobId,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.invalidate(myJobContentProvider);
      ref.invalidate(jobContentProvider(scope));
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Video uploadet 🎉',
        );
    } catch (_) {
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: 'Upload fejlede',
        );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  /// Determinate upload progress shown in place of the pick button while busy.
  /// Once the bytes are sent (100%) the thumbnail + record steps still run, so
  /// we switch the label to "finishing".
  Widget _uploadProgress() {
    final c = DSTheme.of(context);
    final p = _progress;
    final pct = p == null ? null : (p * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DSRadius.sm),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: c.bg.canvas,
            color: c.brand.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s2),
        Text(
          pct == null || pct >= 100 ? 'Færdiggør…' : 'Uploader… $pct%',
          style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// One job's section: a header (job label + clip count) and a horizontal
  /// strip of clip thumbnails.
  Widget _jobGroup(List<MyJobContentClip> clips) {
    final c = DSTheme.of(context);
    final first = clips.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.jobLabel,
          style: DSTextStyle.labelLg.copyWith(
            color: c.text.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${clips.length} klip',
          style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
        ),
        const SizedBox(height: DSSpacing.s2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: clips.map(_clipTile).toList()),
        ),
      ],
    );
  }

  /// A single 9:16 clip tile: tap to play, delete affordance, status chip.
  Widget _clipTile(MyJobContentClip clip) {
    return Padding(
      padding: const EdgeInsets.only(right: DSSpacing.s2),
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => showContentVideoPlayer(context, clip.file.url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DSRadius.sm),
                child: SizedBox(
                  width: 96,
                  height: 150, // 9:16-ish portrait
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (clip.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: clip.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget:
                              (_, __, ___) => Container(color: Colors.black),
                        )
                      else
                        Container(color: Colors.black),
                      const Center(
                        child: Icon(
                          LucideIcons.playCircle,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _delete(clip.file.id),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DSSpacing.s1),
            _statusBadge(clip.status),
          ],
        ),
      ),
    );
  }

  /// Status pill using the design-system [DSStatusBadge] with theme colors.
  Widget _statusBadge(ContentReviewStatus status) {
    final c = DSTheme.of(context);
    final (String label, Color color) = switch (status) {
      ContentReviewStatus.approved => ('Godkendt', c.state.success),
      ContentReviewStatus.rejected => ('Afvist', c.state.danger),
      ContentReviewStatus.pending => ('Afventer', c.state.warning),
    };
    return DSStatusBadge(label: label, color: color);
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDSConfirm(
      context,
      title: 'Slet video?',
      message: 'Er du sikker? Videoen slettes permanent og kan ikke gendannes.',
      confirmLabel: 'Slet',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(jobContentDatasourceProvider).deleteJobContent(id);
      ref.invalidate(myJobContentProvider);
    } catch (_) {
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: 'Kunne ikke slette',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final clipsAsync = ref.watch(myJobContentProvider);

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        title: Text(
          'Mit content',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DSSpacing.s6),
        children: [
          Text(
            'Optag korte klip hvor der er gang i festen. Vi redigerer dem og tilbyder at sætte dem '
            'på din profil, så du kan sælge flere jobs.',
            style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Krav: maks. $kContentVideoMaxSeconds sekunder · lodret 9:16 format.',
            style: DSTextStyle.labelMd.copyWith(
              color: c.text.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          InkWell(
            onTap:
                () => launchUrl(
                  Uri.parse(_examplesUrl),
                  mode: LaunchMode.externalApplication,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.externalLink, size: 14, color: c.state.info),
                const SizedBox(width: DSSpacing.s1),
                Flexible(
                  child: Text(
                    'Se hvordan du gør det og eksempler på god content',
                    style: DSTextStyle.labelMd.copyWith(
                      color: c.state.info,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Se eksemplerne, før du optager.',
            style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
          ),
          const SizedBox(height: DSSpacing.s4),
          if (widget.scope != null) ...[
            Container(
              padding: const EdgeInsets.all(DSSpacing.s4),
              decoration: BoxDecoration(
                color: c.bg.surface,
                borderRadius: BorderRadius.circular(DSRadius.md),
                border: Border.all(color: c.border.subtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DU UPLOADER TIL',
                    style: DSTextStyle.labelSm.copyWith(color: c.brand.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ref
                            .watch(scopedJobSummaryProvider(widget.scope!))
                            .valueOrNull
                            ?.label ??
                        'dette job',
                    style: DSTextStyle.labelLg.copyWith(color: c.text.primary),
                  ),
                  const SizedBox(height: DSSpacing.s1),
                  Text(
                    'Maks. $kContentVideoMaxSeconds sekunder · lodret 9:16 format.',
                    style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
                  ),
                  const SizedBox(height: DSSpacing.s3),
                  if (_busy)
                    _uploadProgress()
                  else
                    DSButton(
                      label: 'Vælg video',
                      variant: DSButtonVariant.primary,
                      expand: true,
                      onTap: _pickAndUpload,
                    ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.s6),
          ],
          clipsAsync.when(
            loading:
                () => Center(
                  child: CircularProgressIndicator(color: c.brand.primary),
                ),
            error:
                (e, _) => Text(
                  'Kunne ikke hente content: $e',
                  style: DSTextStyle.labelMd.copyWith(color: c.state.danger),
                ),
            data: (clips) {
              if (clips.isEmpty) {
                return Text(
                  'Du har ikke uploadet content endnu. Åbn et af dine jobs og tryk '
                  '"Optag content" for at uploade.',
                  style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
                );
              }
              // Group clips by job so a long flat list becomes a clear,
              // per-job overview (newest job first).
              final groups = <String, List<MyJobContentClip>>{};
              final order = <String>[];
              for (final clip in clips) {
                final key = '${clip.isExtJob ? 'ext' : 'job'}:${clip.jobId}';
                (groups[key] ??= []).add(clip);
                if (!order.contains(key)) order.add(key);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int g = 0; g < order.length; g++) ...[
                    if (g > 0) const SizedBox(height: DSSpacing.s6),
                    _jobGroup(groups[order[g]]!),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: DSSpacing.s8),
        ],
      ),
    );
  }
}
