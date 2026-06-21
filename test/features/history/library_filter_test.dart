import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/history/data/history_repository.dart';
import 'package:quicksave/features/history/domain/download_item.dart';
import 'package:quicksave/features/history/domain/library_filter.dart';

void main() {
  group('HistoryRepository filters', () {
    final repo = HistoryRepository.instance;
    final items = [
      DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/reel/ABC/',
        filePath: '/a.mp4',
        author: 'alice',
        mediaType: 'video',
        sourceKind: MediaSourceKind.reel,
      ),
      DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/p/XYZ/',
        filePath: '/b.jpg',
        author: 'bob',
        mediaType: 'image',
        sourceKind: MediaSourceKind.post,
      ),
      DownloadItem.failed(
        sourceUrl: 'https://www.instagram.com/p/FAIL/',
        mediaUrl: 'https://cdn/x.mp4',
        displayFileName: 'fail.mp4',
      ),
    ];

    test('filters reels only', () {
      final out = repo.filterItems(
        items,
        query: '',
        filter: LibraryMediaFilter.reels,
      );
      expect(out.length, 1);
      expect(out.first.author, 'alice');
    });

    test('filters errors', () {
      final out = repo.filterItems(
        items,
        query: '',
        filter: LibraryMediaFilter.errors,
      );
      expect(out.length, 1);
      expect(out.first.isFailed, isTrue);
    });

    test('sorts by username', () {
      final completed = items.where((i) => !i.isFailed).toList();
      final out = repo.sortItems(completed, LibrarySortOption.usernameAsc);
      expect(out.first.author, 'alice');
      expect(out.last.author, 'bob');
    });
  });

  group('Dedupe', () {
    test('dedupeKey uses shortcode when available', () {
      final a = DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/p/ABC/',
        filePath: '/1.jpg',
        shortcode: 'ABC',
      );
      final b = DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/p/ABC/?utm=1',
        filePath: '/2.jpg',
        shortcode: 'ABC',
      );
      expect(a.dedupeKey, b.dedupeKey);
    });

    test('findDuplicate detects existing item', () {
      final items = [
        DownloadItem.create(
          sourceUrl: 'https://x/',
          filePath: '/a',
          contentHash: 'hash1',
        ),
      ];
      final dup = DownloadItem.create(
        sourceUrl: 'https://y/',
        filePath: '/b',
        contentHash: 'hash1',
      );
      expect(
        HistoryRepository.instance.findDuplicate(items, dup)?.filePath,
        '/a',
      );
    });
  });
}
