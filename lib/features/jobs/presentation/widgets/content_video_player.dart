import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';

/// Opens a content clip in a full-screen player. Mirrors the Chewie pattern used
/// in profile_preview_screen.
Future<void> showContentVideoPlayer(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _ContentVideoDialog(url: url),
  );
}

class _ContentVideoDialog extends StatefulWidget {
  const _ContentVideoDialog({required this.url});
  final String url;

  @override
  State<_ContentVideoDialog> createState() => _ContentVideoDialogState();
}

class _ContentVideoDialogState extends State<_ContentVideoDialog> {
  late VideoPlayerController _video;
  ChewieController? _chewie;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _video.initialize();
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _video,
          autoPlay: true,
          looping: true,
          allowFullScreen: false,
          aspectRatio: _video.value.aspectRatio,
        );
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close sits above the video, clear of Chewie's own controls.
          Container(
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _error
                ? const Icon(LucideIcons.videoOff, color: Colors.white54, size: 64)
                : _chewie == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : AspectRatio(
                        aspectRatio: _video.value.aspectRatio,
                        child: Chewie(controller: _chewie!),
                      ),
          ),
        ],
      ),
    );
  }
}
