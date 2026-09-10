import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart';

/// "Billeder fra stedet": the photos the team took at a partner venue, each
/// with its comment (where the DJ stands, where the power is, how the setup
/// looks). Shown on an ext job spawned from a recurring customer so the DJ can
/// look at the room before arriving. Mirrors web `VenuePhotosSection`.
///
/// Self-hides when there are no photos. Tapping a tile opens
/// [VenuePhotoViewerScreen], a swipeable full-screen viewer with the caption.
class VenuePhotosCard extends StatelessWidget {
  const VenuePhotosCard({super.key, required this.photos});

  final List<VenuePhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final c = DSTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.border.subtle),
          boxShadow: DSShadow.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4,
                DSSpacing.s4,
                DSSpacing.s4,
                DSSpacing.s2,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.camera, size: 18, color: c.text.secondary),
                  const SizedBox(width: DSSpacing.s2),
                  Expanded(
                    child: Text(
                      'Billeder fra stedet',
                      style: DSTextStyle.headingSm.copyWith(
                        color: c.text.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${photos.length}',
                    style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
              child: Text(
                'Taget af DJTILBUD på stedet. Tryk for at se i fuld størrelse.',
                style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
              ),
            ),
            const SizedBox(height: DSSpacing.s3),
            SizedBox(
              height: 150,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: DSSpacing.s2),
                itemBuilder:
                    (context, i) => _Thumb(
                      photo: photos[i],
                      onTap:
                          () => VenuePhotoViewerScreen.open(
                            context,
                            photos: photos,
                            initialIndex: i,
                          ),
                    ),
              ),
            ),
            const SizedBox(height: DSSpacing.s4),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onTap});

  final VenuePhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(color: c.border.subtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.bg.canvas),
                errorWidget:
                    (_, _, _) => Container(
                      color: c.bg.canvas,
                      child: Icon(LucideIcons.imageOff, color: c.text.muted),
                    ),
              ),
            ),
            if (photo.hasComment)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  photo.comment!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DSTextStyle.bodySm.copyWith(
                    color: c.text.secondary,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, swipeable viewer for a venue's photos. Pinch to zoom; the
/// team's comment sits under the image so it is readable on a dark backdrop.
class VenuePhotoViewerScreen extends StatefulWidget {
  const VenuePhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  final List<VenuePhoto> photos;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<VenuePhoto> photos,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder:
            (_) => VenuePhotoViewerScreen(
              photos: photos,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  @override
  State<VenuePhotoViewerScreen> createState() => _VenuePhotoViewerScreenState();
}

class _VenuePhotoViewerScreenState extends State<VenuePhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${photos.length}'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder:
                  (_, i) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: photos[i].url,
                        fit: BoxFit.contain,
                        placeholder:
                            (_, _) => const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        errorWidget:
                            (_, _, _) => const Icon(
                              LucideIcons.imageOff,
                              color: Colors.white54,
                              size: 40,
                            ),
                      ),
                    ),
                  ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4,
                DSSpacing.s3,
                DSSpacing.s4,
                DSSpacing.s4,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Text(
                  current.hasComment
                      ? current.comment!
                      : 'Ingen kommentar til dette billede',
                  textAlign: TextAlign.center,
                  style: DSTextStyle.bodyMd.copyWith(
                    color: current.hasComment ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
