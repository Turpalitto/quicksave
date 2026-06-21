import 'package:uuid/uuid.dart';

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
  });

  DownloadItem copyWith({
    String? filePath,
    int? fileSizeBytes,
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
      );
}
