/// Source kind for library filtering.
enum MediaSourceKind {
  post,
  story,
  highlight,
  profile,
  unknown;

  static MediaSourceKind fromString(String? raw) {
    switch (raw) {
      case 'post':
        return MediaSourceKind.post;
      case 'story':
        return MediaSourceKind.story;
      case 'highlight':
        return MediaSourceKind.highlight;
      case 'profile':
        return MediaSourceKind.profile;
      default:
        return MediaSourceKind.unknown;
    }
  }

  String get storageValue => name;
}

enum LibraryItemStatus {
  completed,
  failed;

  static LibraryItemStatus fromString(String? raw) {
    if (raw == 'failed') return LibraryItemStatus.failed;
    return LibraryItemStatus.completed;
  }

  String get storageValue => name;
}

enum LibraryMediaFilter {
  all,
  video,
  image,
  stories,
  profiles,
}
