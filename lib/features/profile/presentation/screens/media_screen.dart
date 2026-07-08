import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MediaScreen extends ConsumerWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final filesAsync = ref.watch(userFilesProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text(
          'Medier & Mixes',
          style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: filesAsync.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(color: _c.brand.primary),
            ),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (files) {
          final profileImages =
              files.where((f) => f.type == UserFileType.profile).toList();
          final commonImages =
              files.where((f) => f.type == UserFileType.common).toList();
          final profileVideos =
              files.where((f) => f.type == UserFileType.profileVideo).toList();
          final commonVideos =
              files.where((f) => f.type == UserFileType.commonVideo).toList();
          final mixes =
              files.where((f) => f.type == UserFileType.djMix).toList();

          // Build videoId -> thumbnailUrl map from thumbnail rows
          final thumbnails = <int, String>{
            for (final f in files)
              if (f.type == UserFileType.thumbnail &&
                  f.thumbnailVideoId != null)
                f.thumbnailVideoId!: f.url,
          };

          return ListView(
            padding: const EdgeInsets.all(DSSpacing.s6),
            children: [
              _MediaSection(
                title: 'Profilbillede',
                subtitle: 'Dit primære billede',
                files: profileImages,
                maxCount: 1,
                fileType: UserFileType.profile,
                isVideo: false,
                thumbnails: thumbnails,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Øvrige billeder',
                subtitle: 'Op til 4 billeder af udstyr/setup',
                files: commonImages,
                maxCount: 4,
                fileType: UserFileType.common,
                isVideo: false,
                thumbnails: thumbnails,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Profilvideo',
                subtitle: 'Personlig video hilsen (maks 60 sek.)',
                files: profileVideos,
                maxCount: 1,
                fileType: UserFileType.profileVideo,
                isVideo: true,
                thumbnails: thumbnails,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Performance videoer',
                subtitle: 'Op til 4 klip (maks 10 sek. hver)',
                files: commonVideos,
                maxCount: 4,
                fileType: UserFileType.commonVideo,
                isVideo: true,
                thumbnails: thumbnails,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MixesSection(files: mixes, maxCount: 3),
              const SizedBox(height: DSSpacing.s8),
            ],
          );
        },
      ),
    );
  }
}

class _MediaSection extends ConsumerStatefulWidget {
  const _MediaSection({
    required this.title,
    required this.subtitle,
    required this.files,
    required this.maxCount,
    required this.fileType,
    required this.isVideo,
    required this.thumbnails,
  });

  final String title;
  final String subtitle;
  final List<UserFile> files;
  final int maxCount;
  final UserFileType fileType;
  final bool isVideo;
  final Map<int, String> thumbnails;

  @override
  ConsumerState<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends ConsumerState<_MediaSection> {
  bool _isUploading = false;
  int? _deletingFileId;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? picked =
        widget.isVideo
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            );

    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final userId =
          ref.read(djProfileProvider).value?.id ??
          ref.read(musicianProfileProvider).value?.id ??
          '';
      await repo.uploadFile(
        userId: userId,
        filePath: picked.path,
        type: widget.fileType,
      );
      ref.invalidate(userFilesProvider);
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Fil uploadet',
        );
    } catch (e) {
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Filen kunne ikke uploades. Prøv igen.',
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(UserFile file) async {
    final confirmed = await showDSConfirm(
      context,
      title: 'Slet fil?',
      confirmLabel: 'Slet',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() => _deletingFileId = file.id);
    try {
      await ref.read(profileRepositoryProvider).deleteFile(file.id);
      ref.invalidate(userFilesProvider);
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Fil slettet',
        );
    } catch (e) {
      if (mounted)
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Filen kunne ikke slettes. Prøv igen.',
          ),
        );
    } finally {
      if (mounted) setState(() => _deletingFileId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final busy = _isUploading || _deletingFileId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: DSTextStyle.headingSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          widget.subtitle,
          style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
        ),
        const SizedBox(height: DSSpacing.s3),
        Wrap(
          spacing: DSSpacing.s3,
          runSpacing: DSSpacing.s3,
          children: [
            ...widget.files.map(
              (f) => _MediaTile(
                file: f,
                isVideo: widget.isVideo,
                thumbnailUrl: widget.thumbnails[f.id],
                isDeleting: _deletingFileId == f.id,
                onDelete: busy ? null : () => _deleteFile(f),
              ),
            ),
            if (widget.files.length < widget.maxCount)
              _AddTile(
                isVideo: widget.isVideo,
                isLoading: _isUploading,
                onTap: busy ? null : _pickAndUpload,
              ),
          ],
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.file,
    required this.isVideo,
    required this.isDeleting,
    required this.onDelete,
    this.thumbnailUrl,
  });

  final UserFile file;
  final bool isVideo;
  final bool isDeleting;
  final VoidCallback? onDelete;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              isVideo
                  ? thumbnailUrl != null
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Center(
                                  child: Icon(
                                    LucideIcons.video,
                                    size: 32,
                                    color: _c.text.secondary,
                                  ),
                                ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Center(
                        child: Icon(
                          LucideIcons.video,
                          size: 32,
                          color: _c.text.secondary,
                        ),
                      )
                  : Image.network(
                    file.url,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Center(
                          child: Icon(
                            LucideIcons.imageOff,
                            color: _c.border.subtle,
                          ),
                        ),
                  ),
        ),
        if (isDeleting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DSRadius.md),
                color: _c.bg.canvas.withValues(alpha: 0.7),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _c.state.danger,
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _c.state.danger,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.x, size: 14, color: _c.text.onDark),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.isVideo,
    required this.isLoading,
    required this.onTap,
  });

  final bool isVideo;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
          color: _c.bg.canvas,
        ),
        child:
            isLoading
                ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _c.brand.primary,
                    ),
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVideo ? LucideIcons.video : LucideIcons.imagePlus,
                      size: 28,
                      color:
                          onTap != null ? _c.text.secondary : _c.border.subtle,
                    ),
                    const SizedBox(height: DSSpacing.s1),
                    Text(
                      isVideo ? 'Tilføj video' : 'Tilføj billede',
                      style: DSTextStyle.bodySm.copyWith(
                        fontSize: 10,
                        color:
                            onTap != null
                                ? _c.text.secondary
                                : _c.border.subtle,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

/// DJ party mixes (audio). Upload via the file picker with a short title, list with a play
/// (opens the audio externally) + delete. Max [maxCount]. Shown to customers on the web profile.
class _MixesSection extends ConsumerStatefulWidget {
  const _MixesSection({required this.files, required this.maxCount});

  final List<UserFile> files;
  final int maxCount;

  @override
  ConsumerState<_MixesSection> createState() => _MixesSectionState();
}

class _MixesSectionState extends ConsumerState<_MixesSection> {
  static const _maxSizeMb = 50;
  bool _isUploading = false;
  int? _deletingFileId;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final picked = result?.files.single;
    if (picked == null || picked.path == null) return;

    if (picked.size > _maxSizeMb * 1024 * 1024) {
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: 'Filen er for stor. Maks $_maxSizeMb MB',
        );
      }
      return;
    }

    final title = await _promptTitle();
    if (title == null) return; // cancelled

    setState(() => _isUploading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final userId =
          ref.read(djProfileProvider).value?.id ??
          ref.read(musicianProfileProvider).value?.id ??
          '';
      await repo.uploadFile(
        userId: userId,
        filePath: picked.path!,
        type: UserFileType.djMix,
        description: title.trim().isEmpty ? null : title.trim(),
      );
      ref.invalidate(userFilesProvider);
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Mix uploadet',
        );
      }
    } catch (e) {
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Mixet kunne ikke uploades. Prøv igen.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _promptTitle() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Titel på mixet'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(
                hintText: 'F.eks. Bryllup i Aarhus, august 2025',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuller'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Upload'),
              ),
            ],
          ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _deleteFile(UserFile file) async {
    final confirmed = await showDSConfirm(
      context,
      title: 'Slet mix?',
      confirmLabel: 'Slet',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _deletingFileId = file.id);
    try {
      await ref.read(profileRepositoryProvider).deleteFile(file.id);
      ref.invalidate(userFilesProvider);
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Mix slettet',
        );
      }
    } catch (e) {
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Mixet kunne ikke slettes. Prøv igen.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingFileId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final busy = _isUploading || _deletingFileId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mixes',
          style: DSTextStyle.headingSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          'Op til ${widget.maxCount} mixes fra dine fester (mp3, m4a, wav). Vises til kunden.',
          style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
        ),
        const SizedBox(height: DSSpacing.s3),
        ...widget.files.map(
          (f) => Container(
            margin: const EdgeInsets.only(bottom: DSSpacing.s2),
            padding: const EdgeInsets.symmetric(
              horizontal: DSSpacing.s2,
              vertical: DSSpacing.s1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: c.border.subtle),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.play_circle_fill,
                    color: c.brand.primaryActive,
                  ),
                  onPressed:
                      () => launchUrl(
                        Uri.parse(f.url),
                        mode: LaunchMode.externalApplication,
                      ),
                ),
                Expanded(
                  child: Text(
                    (f.description?.trim().isNotEmpty ?? false)
                        ? f.description!.trim()
                        : 'Mix uden titel',
                    style: DSTextStyle.bodyMd.copyWith(color: c.text.primary),
                  ),
                ),
                if (_deletingFileId == f.id)
                  const Padding(
                    padding: EdgeInsets.all(DSSpacing.s2),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: c.state.danger,
                    ),
                    onPressed: busy ? null : () => _deleteFile(f),
                  ),
              ],
            ),
          ),
        ),
        if (widget.files.length < widget.maxCount)
          DSButton(
            label: 'Tilføj mix',
            variant: DSButtonVariant.secondary,
            size: DSButtonSize.md,
            iconLeft: LucideIcons.music,
            isLoading: _isUploading,
            onTap: busy ? null : _pickAndUpload,
          ),
      ],
    );
  }
}
