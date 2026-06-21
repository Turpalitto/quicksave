import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/history/domain/download_item.dart';

void main() {
  group('DownloadItem', () {
    test('toJson and fromJson roundtrip', () {
      final item = DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/reel/X/',
        filePath: '/tmp/qs.mp4',
        thumbnailUrl: 'https://img.test/x.jpg',
        author: 'test_user',
        fileSizeBytes: 12345,
      );

      final json = item.toJson();
      final restored = DownloadItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.sourceUrl, item.sourceUrl);
      expect(restored.filePath, item.filePath);
      expect(restored.thumbnailUrl, item.thumbnailUrl);
      expect(restored.author, item.author);
      expect(restored.fileSizeBytes, item.fileSizeBytes);
      expect(restored.createdAt, item.createdAt);
    });

    test('copyWith keeps id and createdAt', () {
      final item = DownloadItem.create(sourceUrl: 'u', filePath: '/tmp/a.mp4');
      final updated = item.copyWith(filePath: '/tmp/b.mp4', fileSizeBytes: 99);
      expect(updated.id, item.id);
      expect(updated.createdAt, item.createdAt);
      expect(updated.filePath, '/tmp/b.mp4');
      expect(updated.fileSizeBytes, 99);
    });

    test('fromJson handles missing fields', () {
      final item = DownloadItem.fromJson({
        'id': 'abc',
        'sourceUrl': 'https://x/',
        'filePath': '/tmp/x',
        'createdAt': '2024-01-01T00:00:00.000Z',
      });
      expect(item.id, 'abc');
      expect(item.thumbnailUrl, isNull);
      expect(item.author, isNull);
      expect(item.fileSizeBytes, isNull);
    });

    test('fromJson handles invalid date', () {
      final item = DownloadItem.fromJson({
        'id': 'abc',
        'sourceUrl': 'https://x/',
        'filePath': '/tmp/x',
        'createdAt': 'invalid',
      });
      // Falls back to DateTime.now() — just check it's recent.
      final diff = DateTime.now().difference(item.createdAt).inSeconds;
      expect(diff.abs(), lessThan(5));
    });
  });
}
