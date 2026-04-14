import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class MediaScreen extends ConsumerWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(userFilesProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Text('Billeder & videoer', style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: filesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _c.brand.primary)),
        error: (e, _) => Center(child: Text('Fejl: $e')),
        data: (files) {
          final profileImages = files.where((f) => f.type == UserFileType.profile).toList();
          final commonImages = files.where((f) => f.type == UserFileType.common).toList();
          final profileVideos = files.where((f) => f.type == UserFileType.profileVideo).toList();
          final commonVideos = files.where((f) => f.type == UserFileType.commonVideo).toList();

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
                ref: ref,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Øvrige billeder',
                subtitle: 'Op til 4 billeder af udstyr/setup',
                files: commonImages,
                maxCount: 4,
                fileType: UserFileType.common,
                isVideo: false,
                ref: ref,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Profilvideo',
                subtitle: 'Personlig video hilsen (maks 60 sek.)',
                files: profileVideos,
                maxCount: 1,
                fileType: UserFileType.profileVideo,
                isVideo: true,
                ref: ref,
              ),
              const SizedBox(height: DSSpacing.s6),
              _MediaSection(
                title: 'Performance videoer',
                subtitle: 'Op til 4 klip (maks 10 sek. hver)',
                files: commonVideos,
                maxCount: 4,
                fileType: UserFileType.commonVideo,
                isVideo: true,
                ref: ref,
              ),
              const SizedBox(height: DSSpacing.s8),
            ],
          );
        },
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.subtitle,
    required this.files,
    required this.maxCount,
    required this.fileType,
    required this.isVideo,
    required this.ref,
  });

  final String title;
  final String subtitle;
  final List<UserFile> files;
  final int maxCount;
  final UserFileType fileType;
  final bool isVideo;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DSTextStyle.headingSm.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: _c.text.primary)),
        const SizedBox(height: DSSpacing.s1),
        Text(subtitle, style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
        const SizedBox(height: DSSpacing.s3),
        Wrap(
          spacing: DSSpacing.s3,
          runSpacing: DSSpacing.s3,
          children: [
            ...files.map((f) => _MediaTile(
              file: f,
              isVideo: isVideo,
              onDelete: () => _deleteFile(context, f),
            )),
            if (files.length < maxCount)
              _AddTile(
                isVideo: isVideo,
                onTap: () => _pickAndUpload(context),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked;

    if (isVideo) {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }

    if (picked == null) return;

    try {
      final repo = ref.read(profileRepositoryProvider);
      final userId = ref.read(djProfileProvider).value?.id ??
          ref.read(musicianProfileProvider).value?.id ?? '';
      await repo.uploadFile(userId: userId, filePath: picked.path, type: fileType);
      ref.invalidate(userFilesProvider);
      if (context.mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Fil uploadet');
    } catch (e) {
      if (context.mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Upload fejlede');
    }
  }

  Future<void> _deleteFile(BuildContext context, UserFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slet fil?'),
        actions: [
          DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.of(ctx).pop(false)),
          DSButton(label: 'Slet', variant: DSButtonVariant.tertiary, size: DSButtonSize.sm, onTap: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(profileRepositoryProvider).deleteFile(file.id);
      ref.invalidate(userFilesProvider);
      if (context.mounted) DSToast.show(context, variant: DSToastVariant.success, title: 'Fil slettet');
    } catch (e) {
      if (context.mounted) DSToast.show(context, variant: DSToastVariant.error, title: 'Fejl: $e');
    }
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.file, required this.isVideo, required this.onDelete});

  final UserFile file;
  final bool isVideo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
          child: isVideo
              ? Center(child: Icon(LucideIcons.video, size: 32, color: _c.text.secondary))
              : Image.network(file.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                  Center(child: Icon(LucideIcons.imageOff, color: _c.border.subtle))),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: _c.state.danger, shape: BoxShape.circle),
              child: Icon(LucideIcons.x, size: 14, color: _c.text.onDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.isVideo, required this.onTap});

  final bool isVideo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isVideo ? LucideIcons.video : LucideIcons.imagePlus,
                size: 28, color: _c.text.secondary),
            const SizedBox(height: DSSpacing.s1),
            Text(
              isVideo ? 'Tilføj video' : 'Tilføj billede',
              style: DSTextStyle.bodySm.copyWith(fontSize: 10, color: _c.text.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
