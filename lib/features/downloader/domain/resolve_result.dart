/// Тип медиа в коллекции.
enum MediaType { video, image }

/// Один вариант качества видео.
class VideoQuality {
  final String url;
  final int width;
  final int height;
  final String label;

  const VideoQuality({
    required this.url,
    required this.width,
    required this.height,
    required this.label,
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) => VideoQuality(
        url: json['url'] as String? ?? '',
        width: (json['width'] as num?)?.toInt() ?? 0,
        height: (json['height'] as num?)?.toInt() ?? 0,
        label: (json['label'] as String?) ?? '${json['width']}p',
      );
}

/// Один элемент медиа (видео или фото) из поста/карусели/story/профиля.
class MediaItem {
  final String id;
  final int index;
  final MediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String fileName;
  final int? width;
  final int? height;
  final String? postUrl;
  final String? shortcode;
  final bool needsResolve;
  final List<VideoQuality> qualities;

  const MediaItem({
    required this.id,
    required this.index,
    required this.mediaType,
    required this.mediaUrl,
    required this.fileName,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.postUrl,
    this.shortcode,
    this.needsResolve = false,
    this.qualities = const [],
  });

  bool get isVideo => mediaType == MediaType.video;
  bool get hasQualityOptions => qualities.length > 1;

  bool get canDownloadDirectly =>
      mediaUrl.isNotEmpty && (!needsResolve || !isVideo);

  MediaItem copyWith({
    String? mediaUrl,
    String? fileName,
    String? thumbnailUrl,
    bool? needsResolve,
    List<VideoQuality>? qualities,
  }) =>
      MediaItem(
        id: id,
        index: index,
        mediaType: mediaType,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        fileName: fileName ?? this.fileName,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        durationSeconds: durationSeconds,
        width: width,
        height: height,
        postUrl: postUrl,
        shortcode: shortcode,
        needsResolve: needsResolve ?? this.needsResolve,
        qualities: qualities ?? this.qualities,
      );

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['mediaType'] as String?) ?? 'video';
    final needsResolve = json['needsResolve'] == true;
    final rawQualities = json['qualities'];
    final qualities = rawQualities is List
        ? rawQualities
            .whereType<Map<String, dynamic>>()
            .map(VideoQuality.fromJson)
            .where((q) => q.url.isNotEmpty)
            .toList()
        : <VideoQuality>[];
    return MediaItem(
      id: json['id'] as String? ?? 'item_${json['index'] ?? 0}',
      index: (json['index'] as num?)?.toInt() ?? 0,
      mediaType: typeStr == 'image' ? MediaType.image : MediaType.video,
      mediaUrl: json['mediaUrl'] as String? ?? json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt(),
      fileName: (json['fileName'] as String?) ?? 'media_${json['index'] ?? 0}.mp4',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      postUrl: json['postUrl'] as String?,
      shortcode: json['shortcode'] as String?,
      needsResolve: needsResolve,
      qualities: qualities,
    );
  }
}

enum ResolveType { single, carousel, story, highlight, profile }

class ResolveResult {
  final ResolveType type;
  final String sourceUrl;
  final List<MediaItem> items;
  final String? author;
  final String? shortcode;
  final int videoCount;
  final int imageCount;
  final String? userId;
  final String? nextCursor;
  final bool hasMore;
  final String? caption;
  final DateTime? postDate;

  const ResolveResult({
    required this.type,
    required this.sourceUrl,
    required this.items,
    this.author,
    this.shortcode,
    this.videoCount = 0,
    this.imageCount = 0,
    this.userId,
    this.nextCursor,
    this.hasMore = false,
    this.caption,
    this.postDate,
  });

  bool get isCollection => items.length > 1;
  bool get isProfile => type == ResolveType.profile;
  bool get hasVideos => videoCount > 0;
  bool get hasImages => imageCount > 0;

  ResolveResult mergeItems(ResolveResult page) {
    final seen = items.map((i) => i.id).toSet();
    final merged = [
      ...items,
      ...page.items.where((i) => !seen.contains(i.id)),
    ];
    return ResolveResult(
      type: type,
      sourceUrl: sourceUrl,
      items: merged,
      author: author ?? page.author,
      shortcode: shortcode,
      videoCount: merged.where((i) => i.isVideo).length,
      imageCount: merged.where((i) => !i.isVideo).length,
      userId: page.userId ?? userId,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      caption: caption ?? page.caption,
      postDate: postDate ?? page.postDate,
    );
  }

  MediaItem? get firstVideo {
    for (final i in items) {
      if (i.isVideo) return i;
    }
    return items.isNotEmpty ? items.first : null;
  }

  factory ResolveResult.fromJson(Map<String, dynamic> json, String sourceUrl) {
    final rawItems = json['items'];
    List<MediaItem> items;
    if (rawItems is List && rawItems.isNotEmpty) {
      items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(MediaItem.fromJson)
          .where((i) => i.mediaUrl.isNotEmpty || (i.postUrl?.isNotEmpty ?? false))
          .toList();
    } else {
      final videoUrl = json['videoUrl'] as String?;
      if (videoUrl == null || videoUrl.isEmpty) {
        items = [];
      } else {
        items = [
          MediaItem(
            id: 'legacy_0',
            index: 0,
            mediaType: MediaType.video,
            mediaUrl: videoUrl,
            thumbnailUrl: json['thumbnailUrl'] as String?,
            durationSeconds: (json['duration'] as num?)?.toInt(),
            fileName: (json['fileName'] as String?) ?? 'video.mp4',
          ),
        ];
      }
    }

    final typeStr = (json['type'] as String?) ?? 'single';
    final type = switch (typeStr) {
      'carousel' => ResolveType.carousel,
      'story' => ResolveType.story,
      'highlight' => ResolveType.highlight,
      'profile' => ResolveType.profile,
      _ => ResolveType.single,
    };

    final vCount = (json['videoCount'] as num?)?.toInt()
        ?? items.where((i) => i.isVideo).length;
    final iCount = (json['imageCount'] as num?)?.toInt()
        ?? items.where((i) => !i.isVideo).length;

    ResolveType resolvedType = type;
    if (type == ResolveType.single && items.length > 1) {
      resolvedType = ResolveType.carousel;
    }

    return ResolveResult(
      type: resolvedType,
      sourceUrl: sourceUrl,
      items: items,
      author: json['author'] as String?,
      shortcode: json['shortcode'] as String?,
      videoCount: vCount,
      imageCount: iCount,
      userId: json['userId'] as String?,
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] == true,
      caption: json['caption'] as String?,
      postDate: json['postDate'] != null
          ? DateTime.tryParse(json['postDate'] as String)
          : null,
    );
  }
}

class VideoInfoCompat {
  final String videoUrl;
  final String fileName;
  final String? thumbnailUrl;
  final String? author;
  final int? durationSeconds;
  final int? fileSizeBytes;

  const VideoInfoCompat({
    required this.videoUrl,
    required this.fileName,
    this.thumbnailUrl,
    this.author,
    this.durationSeconds,
    this.fileSizeBytes,
  });
}
