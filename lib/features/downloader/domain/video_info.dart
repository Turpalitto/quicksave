import 'resolve_result.dart';

/// Доменная модель: информация о видео, полученная от backend resolver.
/// Сохранена для обратной совместимости — предпочтительно [ResolveResult].
class VideoInfo {
  final String videoUrl;
  final String? thumbnailUrl;
  final String? author;
  final int? durationSeconds;
  final int? fileSizeBytes;
  final String fileName;

  const VideoInfo({
    required this.videoUrl,
    required this.fileName,
    this.thumbnailUrl,
    this.author,
    this.durationSeconds,
    this.fileSizeBytes,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      videoUrl: json['videoUrl'] as String,
      fileName: (json['fileName'] as String?) ?? 'video.mp4',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      author: json['author'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt(),
      fileSizeBytes: (json['fileSize'] as num?)?.toInt(),
    );
  }

  factory VideoInfo.fromResolveResult(ResolveResult result) {
    final first = result.firstVideo ?? result.items.first;
    return VideoInfo(
      videoUrl: first.mediaUrl,
      fileName: first.fileName,
      thumbnailUrl: first.thumbnailUrl,
      author: result.author,
      durationSeconds: first.durationSeconds,
    );
  }
}
