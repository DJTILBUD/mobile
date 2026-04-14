import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/dj_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/musician_profile.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/review.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/user_file.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _c = lightColors;

class ProfilePreviewScreen extends ConsumerStatefulWidget {
  const ProfilePreviewScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<ProfilePreviewScreen> createState() =>
      _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen> {
  bool _showAllReviews = false;

  @override
  Widget build(BuildContext context) {
    final isDj = widget.role == MusicianRole.dj;
    final profileAsync =
        isDj ? ref.watch(djProfileProvider) : ref.watch(musicianProfileProvider);
    final reviewsAsync =
        isDj ? ref.watch(djReviewsProvider) : ref.watch(musicianReviewsProvider);
    final filesAsync = ref.watch(userFilesProvider);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Forhåndsvisning'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Fejl: $e',
                style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger))),
        data: (profile) {
          final fullName = profile is DjProfile
              ? profile.fullName
              : (profile as MusicianProfile).fullName;
          final firstName = fullName.split(' ').first;

          final about = profile is DjProfile
              ? profile.aboutYou
              : (profile as MusicianProfile).aboutText;
          final venues = profile is DjProfile
              ? profile.venuesAndEvents
              : (profile as MusicianProfile).venuesAndEvents;
          // Only musicians show genres on the preview page
          final genres =
              isDj ? null : (profile as MusicianProfile).genres;

          final files = filesAsync.valueOrNull ?? [];
          final mediaItems = _buildOrderedMediaItems(files);

          final reviews = reviewsAsync.valueOrNull ?? [];
          final displayedReviews =
              _showAllReviews ? reviews : reviews.take(4).toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Info banner ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(
                    DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                padding: const EdgeInsets.all(DSSpacing.s3),
                decoration: BoxDecoration(
                  color: _c.state.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  border:
                      Border.all(color: _c.state.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.eye,
                        size: 15, color: _c.state.info),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        'Sådan ser din profil ud for kunder',
                        style:
                            DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Image carousel ───────────────────────────────────────────
              if (mediaItems.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.s4),
                _ImageCarousel(items: mediaItems),
              ],

              // ── First name (+ verified badge for DJs) ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, 0),
                child: Row(
                  children: [
                    Text(
                      firstName,
                      style: DSTextStyle.headingLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _c.text.primary,
                      ),
                    ),
                    if (isDj) ...[
                      const SizedBox(width: 6),
                      Icon(LucideIcons.badgeCheck,
                          size: 20, color: _c.brand.accent),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: DSSpacing.s6),

              // ── About ────────────────────────────────────────────────────
              if (about != null && about.isNotEmpty) ...[
                _ContentSection(
                  title: isDj ? 'Beskrivelse af DJ' : 'Om musikeren',
                  child: Text(
                    about,
                    style: TextStyle(
                      fontSize: 15,
                      color: _c.text.secondary,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: DSSpacing.s6),
              ],

              // ── Venues & events ──────────────────────────────────────────
              if (venues != null && venues.isNotEmpty) ...[
                _ContentSection(
                  title: 'Erfaring og tidligere spillesteder',
                  subtitle:
                      '$firstName har spillet til følgende steder og events',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: venues
                        .map((v) => _CheckTag(label: v))
                        .toList(),
                  ),
                ),
                const SizedBox(height: DSSpacing.s6),
              ],

              // ── Genres (musician only) ───────────────────────────────────
              if (genres != null && genres.isNotEmpty) ...[
                _ContentSection(
                  title: 'Genrer',
                  subtitle: '$firstName spiller følgende genrer',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres
                        .map((g) => _CheckTag(label: g))
                        .toList(),
                  ),
                ),
                const SizedBox(height: DSSpacing.s6),
              ],

              // ── Reviews ──────────────────────────────────────────────────
              if (reviews.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reviews.length} skrevne anbefalinger fra tidligere kunder',
                        style: DSTextStyle.headingMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _c.text.primary,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s4),
                      ...displayedReviews
                          .map((r) => _ReviewCard(review: r)),
                      if (reviews.length > 4) ...[
                        const SizedBox(height: DSSpacing.s2),
                        GestureDetector(
                          onTap: () => setState(
                              () => _showAllReviews = !_showAllReviews),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAllReviews
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 18,
                                color: _c.text.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showAllReviews
                                    ? 'Skjul anbefalinger'
                                    : 'Se alle anbefalinger',
                                style: DSTextStyle.labelMd
                                    .copyWith(color: _c.text.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.s6),
              ],

              const SizedBox(height: DSSpacing.s8),
            ],
          );
        },
      ),
    );
  }
}

// ─── Media item ───────────────────────────────────────────────────────────────

class _MediaItem {
  const _MediaItem({required this.file, this.thumbnailUrl});

  final UserFile file;

  /// Resolved thumbnail URL for video files (null for images).
  final String? thumbnailUrl;

  bool get isVideo =>
      file.type == UserFileType.profileVideo ||
      file.type == UserFileType.commonVideo;

  /// URL to display in the thumbnail tile.
  String? get previewUrl => isVideo ? thumbnailUrl : file.url;
}

// ─── Media ordering (mirrors web app DjImageCarousel / MusicianImageCarousel) ─

List<_MediaItem> _buildOrderedMediaItems(List<UserFile> files) {
  // Build videoId → thumbnail URL map from thumbnail files
  final thumbnailMap = <int, String>{};
  for (final f in files) {
    if (f.type == UserFileType.thumbnail && f.thumbnailVideoId != null) {
      thumbnailMap[f.thumbnailVideoId!] = f.url;
    }
  }

  _MediaItem wrap(UserFile f) =>
      _MediaItem(file: f, thumbnailUrl: thumbnailMap[f.id]);

  final profileImage =
      files.where((f) => f.type == UserFileType.profile).firstOrNull;
  final profileVideo =
      files.where((f) => f.type == UserFileType.profileVideo).firstOrNull;
  final commonImages =
      files.where((f) => f.type == UserFileType.common).toList();
  final commonVideos =
      files.where((f) => f.type == UserFileType.commonVideo).toList();

  final ordered = <_MediaItem>[];
  if (profileImage != null) ordered.add(wrap(profileImage));
  if (profileVideo != null) ordered.add(wrap(profileVideo));

  final maxCommon = commonImages.length > commonVideos.length
      ? commonImages.length
      : commonVideos.length;
  for (var i = 0; i < maxCommon; i++) {
    if (i < commonImages.length) ordered.add(wrap(commonImages[i]));
    if (i < commonVideos.length) ordered.add(wrap(commonVideos[i]));
  }
  return ordered;
}

// ─── Image Carousel ───────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.items});

  final List<_MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _MediaTile(
          item: items[i],
          onTap: () => _openViewer(context, items, i),
        ),
      ),
    );
  }

  void _openViewer(
      BuildContext context, List<_MediaItem> items, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _MediaViewerScreen(
          items: items,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item, required this.onTap});

  final _MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl = item.previewUrl;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DSRadius.lg),
        child: Stack(
          children: [
            if (previewUrl != null && previewUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: previewUrl,
                width: 260,
                height: 260,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 260,
                  height: 260,
                  color: _c.bg.inputBg,
                ),
                errorWidget: (_, __, ___) => _PlaceholderTile(
                    isVideo: item.isVideo),
              )
            else
              _PlaceholderTile(isVideo: item.isVideo),

            if (item.isVideo)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: Icon(
                      LucideIcons.playCircle,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      color: _c.bg.inputBg,
      child: Icon(
        isVideo ? LucideIcons.video : LucideIcons.image,
        color: _c.text.muted,
        size: 40,
      ),
    );
  }
}

// ─── Full-screen media viewer ─────────────────────────────────────────────────

class _MediaViewerScreen extends StatefulWidget {
  const _MediaViewerScreen({
    required this.items,
    required this.initialIndex,
  });

  final List<_MediaItem> items;
  final int initialIndex;

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final item = widget.items[i];
          return item.isVideo
              ? _VideoPage(videoUrl: item.file.url)
              : _ImagePage(imageUrl: item.file.url);
        },
      ),
    );
  }
}

// Full-screen image page with pinch-to-zoom
class _ImagePage extends StatelessWidget {
  const _ImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(LucideIcons.imageOff,
                color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}

// Full-screen video page using chewie
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.videoUrl});

  final String videoUrl;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _videoController.initialize();
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: false,
            allowFullScreen: false,
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Icon(LucideIcons.videoOff,
            color: Colors.white54, size: 64),
      );
    }
    if (_chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(child: Chewie(controller: _chewieController!));
  }
}

// ─── Content Section ──────────────────────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _c.text.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: _c.text.muted),
            ),
          ],
          const SizedBox(height: DSSpacing.s3),
          child,
        ],
      ),
    );
  }
}

// ─── Check Tag ────────────────────────────────────────────────────────────────

class _CheckTag extends StatelessWidget {
  const _CheckTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: Border.all(color: const Color(0xFFCBCBCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.checkCircle,
              size: 14, color: Color(0xFF5A731A)),
        ],
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(review.eventDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DSSpacing.s3),
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event type (title)
          Text(
            eventTypeLabel(review.eventType),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          // Customer name + date
          Text(
            '${review.customerName} • $date',
            style: TextStyle(
              fontSize: 12,
              color: _c.text.muted,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          // Review text
          Text(
            review.review,
            style: TextStyle(
              fontSize: 14,
              color: _c.text.secondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
        'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
      ];
      return '${dt.day}. ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
