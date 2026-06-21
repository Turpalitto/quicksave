/// Source kind for library filtering.
enum MediaSourceKind {
  post,
  reel,
  story,
  highlight,
  profile,
  carousel,
  unknown;

  static MediaSourceKind fromString(String? raw) {
    switch (raw) {
      case 'post':
        return MediaSourceKind.post;
      case 'reel':
        return MediaSourceKind.reel;
      case 'story':
        return MediaSourceKind.story;
      case 'highlight':
        return MediaSourceKind.highlight;
      case 'profile':
        return MediaSourceKind.profile;
      case 'carousel':
        return MediaSourceKind.carousel;
      default:
        return MediaSourceKind.unknown;
    }
  }

  String get storageValue => name;

  /// Maps legacy `post` + mediaType/groupId to reel/carousel when needed.
  static MediaSourceKind infer({
    required MediaSourceKind stored,
    String? sourceUrl,
    String? groupId,
    int? mediaIndex,
  }) {
    if (stored != MediaSourceKind.unknown && stored != MediaSourceKind.post) {
      return stored;
    }
    final url = sourceUrl?.toLowerCase() ?? '';
    if (url.contains('/reel/')) return MediaSourceKind.reel;
    if (groupId != null && groupId.isNotEmpty && (mediaIndex ?? 0) > 0) {
      return MediaSourceKind.carousel;
    }
    return stored;
  }
}

enum LibraryItemStatus {
  completed,
  failed,
  partial,
  missingFile;

  static LibraryItemStatus fromString(String? raw) {
    switch (raw) {
      case 'failed':
        return LibraryItemStatus.failed;
      case 'partial':
        return LibraryItemStatus.partial;
      case 'missingFile':
        return LibraryItemStatus.missingFile;
      default:
        return LibraryItemStatus.completed;
    }
  }

  String get storageValue => name;
}

enum LibraryMediaFilter {
  all,
  reels,
  video,
  image,
  carousels,
  stories,
  highlights,
  profiles,
  errors,
  recent,
  uncollected,
}

enum LibrarySortOption {
  savedAtDesc,
  savedAtAsc,
  usernameAsc,
  typeAsc,
  sizeDesc,
  statusAsc,
}

/// Provenance metadata for saved media (privacy-safe, no cookies).
class MediaProvenance {
  final String? originalUrl;
  final String? resolvedUrl;
  final String? contentType;
  final String? username;
  final String? shortcode;
  final String? mediaId;
  final DateTime? savedAt;
  final String? appVersion;
  final String? resolverVersion;
  final String? backendMode;
  final bool userInitiated;

  const MediaProvenance({
    this.originalUrl,
    this.resolvedUrl,
    this.contentType,
    this.username,
    this.shortcode,
    this.mediaId,
    this.savedAt,
    this.appVersion,
    this.resolverVersion,
    this.backendMode,
    this.userInitiated = true,
  });

  Map<String, dynamic> toJson() => {
    if (originalUrl != null) 'originalUrl': originalUrl,
    if (resolvedUrl != null) 'resolvedUrl': resolvedUrl,
    if (contentType != null) 'contentType': contentType,
    if (username != null) 'username': username,
    if (shortcode != null) 'shortcode': shortcode,
    if (mediaId != null) 'mediaId': mediaId,
    if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    if (appVersion != null) 'appVersion': appVersion,
    if (resolverVersion != null) 'resolverVersion': resolverVersion,
    if (backendMode != null) 'backendMode': backendMode,
    'userInitiated': userInitiated,
  };

  factory MediaProvenance.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MediaProvenance();
    return MediaProvenance(
      originalUrl: json['originalUrl'] as String?,
      resolvedUrl: json['resolvedUrl'] as String?,
      contentType: json['contentType'] as String?,
      username: json['username'] as String?,
      shortcode: json['shortcode'] as String?,
      mediaId: json['mediaId'] as String?,
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
      appVersion: json['appVersion'] as String?,
      resolverVersion: json['resolverVersion'] as String?,
      backendMode: json['backendMode'] as String?,
      userInitiated: json['userInitiated'] as bool? ?? true,
    );
  }
}
