import 'package:uuid/uuid.dart';

import 'library_filter.dart';

class DownloadItem {
  final String id;
  final String sourceUrl;
  final String filePath;
  final String? thumbnailUrl;
  final String? author;
  final String? caption;
  final DateTime? postDate;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final int? mediaIndex;
  final String? mediaType;
  final String? groupId;
  final String? mediaUrl;
  final String? displayFileName;
  final String? contentHash;
  final MediaSourceKind sourceKind;
  final LibraryItemStatus status;
  final List<String> collectionIds;
  final String? failureReason;

  const DownloadItem({
    required this.id,
    required this.sourceUrl,
    required this.filePath,
    required this.createdAt,
    this.thumbnailUrl,
    this.author,
    this.caption,
    this.postDate,
    this.fileSizeBytes,
    this.mediaIndex,
    this.mediaType,
    this.groupId,
    this.mediaUrl,
    this.displayFileName,
    this.contentHash,
    this.sourceKind = MediaSourceKind.unknown,
    this.status = LibraryItemStatus.completed,
    this.collectionIds = const [],
    this.failureReason,
  });

  bool get isVideo => mediaType != 'image';
  bool get isFailed => status == LibraryItemStatus.failed;

  String get searchBlob => [
        author,
        caption,
        displayFileName,
        sourceUrl,
        filePath.split(RegExp(r'[/\\]')).last,
      ].whereType<String>().join(' ').toLowerCase();

  String get dedupeKey =>
      contentHash ??
      mediaUrl ??
      '$sourceUrl|${fileSizeBytes ?? 0}|${mediaIndex ?? 0}';

  DownloadItem copyWith({
    String? filePath,
    int? fileSizeBytes,
    LibraryItemStatus? status,
    String? failureReason,
    List<String>? collectionIds,
  }) =>
      DownloadItem(
        id: id,
        sourceUrl: sourceUrl,
        filePath: filePath ?? this.filePath,
        thumbnailUrl: thumbnailUrl,
        author: author,
        caption: caption,
        postDate: postDate,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        createdAt: createdAt,
        mediaIndex: mediaIndex,
        mediaType: mediaType,
        groupId: groupId,
        mediaUrl: mediaUrl,
        displayFileName: displayFileName,
        contentHash: contentHash,
        sourceKind: sourceKind,
        status: status ?? this.status,
        collectionIds: collectionIds ?? this.collectionIds,
        failureReason: failureReason ?? this.failureReason,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceUrl': sourceUrl,
        'filePath': filePath,
        'thumbnailUrl': thumbnailUrl,
        'author': author,
        'caption': caption,
        if (postDate != null) 'postDate': postDate!.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        if (mediaIndex != null) 'mediaIndex': mediaIndex,
        if (mediaType != null) 'mediaType': mediaType,
        if (groupId != null) 'groupId': groupId,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (displayFileName != null) 'displayFileName': displayFileName,
        if (contentHash != null) 'contentHash': contentHash,
        'sourceKind': sourceKind.storageValue,
        'status': status.storageValue,
        if (collectionIds.isNotEmpty) 'collectionIds': collectionIds,
        if (failureReason != null) 'failureReason': failureReason,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json['id'] as String,
        sourceUrl: json['sourceUrl'] as String,
        filePath: json['filePath'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        author: json['author'] as String?,
        caption: json['caption'] as String?,
        postDate: json['postDate'] != null
            ? DateTime.tryParse(json['postDate'] as String)
            : null,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        mediaIndex: (json['mediaIndex'] as num?)?.toInt(),
        mediaType: json['mediaType'] as String?,
        groupId: json['groupId'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        displayFileName: json['displayFileName'] as String?,
        contentHash: json['contentHash'] as String?,
        sourceKind: MediaSourceKind.fromString(json['sourceKind'] as String?),
        status: LibraryItemStatus.fromString(json['status'] as String?),
        collectionIds: (json['collectionIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        failureReason: json['failureReason'] as String?,
      );

  factory DownloadItem.create({
    required String sourceUrl,
    required String filePath,
    String? thumbnailUrl,
    String? author,
    String? caption,
    DateTime? postDate,
    int? fileSizeBytes,
    int? mediaIndex,
    String? mediaType,
    String? groupId,
    String? mediaUrl,
    String? displayFileName,
    String? contentHash,
    MediaSourceKind sourceKind = MediaSourceKind.unknown,
    LibraryItemStatus status = LibraryItemStatus.completed,
    List<String> collectionIds = const [],
    String? failureReason,
  }) =>
      DownloadItem(
        id: const Uuid().v4(),
        sourceUrl: sourceUrl,
        filePath: filePath,
        thumbnailUrl: thumbnailUrl,
        author: author,
        caption: caption,
        postDate: postDate,
        fileSizeBytes: fileSizeBytes,
        createdAt: DateTime.now(),
        mediaIndex: mediaIndex,
        mediaType: mediaType,
        groupId: groupId,
        mediaUrl: mediaUrl,
        displayFileName: displayFileName ?? filePath.split(RegExp(r'[/\\]')).last,
        contentHash: contentHash,
        sourceKind: sourceKind,
        status: status,
        collectionIds: collectionIds,
        failureReason: failureReason,
      );

  factory DownloadItem.failed({
    required String sourceUrl,
    required String mediaUrl,
    required String displayFileName,
    String? author,
    String? failureReason,
    MediaSourceKind sourceKind = MediaSourceKind.unknown,
  }) =>
      DownloadItem.create(
        sourceUrl: sourceUrl,
        filePath: '',
        mediaUrl: mediaUrl,
        displayFileName: displayFileName,
        author: author,
        sourceKind: sourceKind,
        status: LibraryItemStatus.failed,
        failureReason: failureReason ?? 'download_failed',
      );
}
