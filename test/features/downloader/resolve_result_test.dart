import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/downloader/domain/resolve_result.dart';

void main() {
  group('ResolveResult.fromJson', () {
    test('parses carousel with multiple items', () {
      final result = ResolveResult.fromJson({
        'ok': true,
        'type': 'carousel',
        'itemCount': 2,
        'videoCount': 1,
        'imageCount': 1,
        'author': 'Alice',
        'items': [
          {
            'id': 'abc_0',
            'index': 0,
            'mediaType': 'video',
            'mediaUrl': 'https://cdn.example.com/v.mp4',
            'fileName': 'quicksave_abc_1.mp4',
          },
          {
            'id': 'abc_1',
            'index': 1,
            'mediaType': 'image',
            'mediaUrl': 'https://cdn.example.com/p.jpg',
            'fileName': 'quicksave_abc_2.jpg',
          },
        ],
      }, 'https://instagram.com/p/abc/');

      expect(result.isCollection, isTrue);
      expect(result.items.length, 2);
      expect(result.videoCount, 1);
      expect(result.imageCount, 1);
      expect(result.author, 'Alice');
    });

    test('falls back to legacy single videoUrl', () {
      final result = ResolveResult.fromJson({
        'videoUrl': 'https://cdn.example.com/v.mp4',
        'fileName': 'quicksave_x.mp4',
      }, 'https://instagram.com/reel/x/');

      expect(result.items.length, 1);
      expect(result.items.first.mediaUrl, 'https://cdn.example.com/v.mp4');
    });

    test('parses profile pagination fields', () {
      final result = ResolveResult.fromJson({
        'type': 'profile',
        'items': [
          {
            'id': 'p1',
            'index': 0,
            'mediaType': 'video',
            'mediaUrl': '',
            'postUrl': 'https://instagram.com/reel/p1',
            'needsResolve': true,
            'fileName': 'a.mp4',
          },
        ],
        'userId': '123',
        'nextCursor': 'cursor1',
        'hasMore': true,
      }, 'https://instagram.com/natgeo');

      expect(result.isProfile, isTrue);
      expect(result.userId, '123');
      expect(result.nextCursor, 'cursor1');
      expect(result.hasMore, isTrue);
      expect(result.items.first.needsResolve, isTrue);
    });

    test('mergeItems deduplicates by id', () {
      const base = ResolveResult(
        type: ResolveType.profile,
        sourceUrl: 'https://instagram.com/natgeo',
        items: [
          MediaItem(
            id: 'a',
            index: 0,
            mediaType: MediaType.video,
            mediaUrl: '',
            fileName: 'a.mp4',
            postUrl: 'https://instagram.com/reel/a',
            needsResolve: true,
          ),
        ],
        userId: '123',
        nextCursor: 'c1',
        hasMore: true,
      );
      final page = ResolveResult.fromJson({
        'type': 'profile',
        'items': [
          {
            'id': 'a',
            'index': 0,
            'mediaType': 'video',
            'mediaUrl': '',
            'fileName': 'a.mp4',
          },
          {
            'id': 'b',
            'index': 1,
            'mediaType': 'image',
            'mediaUrl': 'https://cdn.example.com/b.jpg',
            'fileName': 'b.jpg',
          },
        ],
        'userId': '123',
        'nextCursor': 'c2',
        'hasMore': false,
      }, 'https://instagram.com/natgeo');

      final merged = base.mergeItems(page);
      expect(merged.items.length, 2);
      expect(merged.items.map((i) => i.id), ['a', 'b']);
      expect(merged.hasMore, isFalse);
      expect(merged.nextCursor, 'c2');
    });
  });
}
