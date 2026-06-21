import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/downloader/domain/video_info.dart';

void main() {
  group('VideoInfo.fromJson', () {
    test('parses full payload', () {
      final info = VideoInfo.fromJson({
        'videoUrl': 'https://cdn.test/v.mp4',
        'thumbnailUrl': 'https://img.test/t.jpg',
        'author': 'cool_user',
        'duration': 30,
        'fileName': 'video.mp4',
        'fileSize': 1024,
      });
      expect(info.videoUrl, 'https://cdn.test/v.mp4');
      expect(info.thumbnailUrl, 'https://img.test/t.jpg');
      expect(info.author, 'cool_user');
      expect(info.durationSeconds, 30);
      expect(info.fileName, 'video.mp4');
      expect(info.fileSizeBytes, 1024);
    });

    test('handles missing optional fields', () {
      final info = VideoInfo.fromJson({
        'videoUrl': 'https://cdn.test/v.mp4',
      });
      expect(info.thumbnailUrl, isNull);
      expect(info.author, isNull);
      expect(info.durationSeconds, isNull);
      expect(info.fileName, 'video.mp4');
      expect(info.fileSizeBytes, isNull);
    });

    test('coerces numeric duration from double', () {
      final info = VideoInfo.fromJson({
        'videoUrl': 'x',
        'duration': 12.7,
      });
      expect(info.durationSeconds, 12);
    });
  });
}
