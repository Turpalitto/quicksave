import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../features/downloader/domain/resolve_result.dart';
import 'cached_thumbnail.dart';

/// Fullscreen in-app preview for a media item before download.
class MediaPreviewDialog extends StatefulWidget {
  final MediaItem item;

  const MediaPreviewDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, MediaItem item) {
    return showDialog<void>(
      context: context,
      builder: (_) => MediaPreviewDialog(item: item),
    );
  }

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  VideoPlayerController? _controller;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item.isVideo && item.mediaUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(item.mediaUrl))
        ..initialize()
            .then((_) {
              if (mounted) setState(() {});
              _controller?.play();
            })
            .catchError((Object e) {
              if (mounted) setState(() => _videoError = e.toString());
            });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final previewUrl = item.thumbnailUrl ?? item.mediaUrl;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: item.isVideo && item.mediaUrl.isNotEmpty
                ? _buildVideo(scheme)
                : InteractiveViewer(
                    child: CachedThumbnail(
                      imageUrl: previewUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          if (item.needsResolve && item.isVideo)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Preview only — video URL resolves at download time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurface),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: scheme.surface.withValues(alpha: 0.7),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo(ColorScheme scheme) {
    if (_videoError != null) {
      return Text(
        _videoError!,
        style: TextStyle(color: scheme.error),
        textAlign: TextAlign.center,
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const CircularProgressIndicator();
    }
    return AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c));
  }
}

Future<VideoQuality?> showQualityPicker(
  BuildContext context,
  MediaItem item,
  String title,
) async {
  if (!item.hasQualityOptions) return null;
  return showModalBottomSheet<VideoQuality>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...item.qualities.map(
              (q) => ListTile(
                title: Text(q.label),
                subtitle: Text('${q.width}×${q.height}'),
                onTap: () => Navigator.pop(ctx, q),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
