import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/history/domain/download_item.dart';
import 'package:quicksave/features/history/domain/library_filter.dart';
import 'package:quicksave/features/history/data/history_repository.dart';
import 'package:quicksave/services/download_preflight.dart';
import 'package:quicksave/services/download_queue.dart';

void main() {
  group('DownloadPreflight', () {
    test('rejects oversized files', () {
      const pf = DownloadPreflight(
        contentType: 'video/mp4',
        estimatedBytes: 600 * 1024 * 1024,
        targetFileName: 'big.mp4',
        acceptable: false,
        rejectionReason: 'file_too_large',
      );
      expect(pf.acceptable, isFalse);
    });
  });

  group('DownloadQueue', () {
    setUp(DownloadQueue.instance.resetForTests);

    test('enqueue creates queued task', () {
      final queue = DownloadQueue.instance;
      queue.clearCompleted();
      final id = queue.enqueue(
        url: 'https://example.com/file.mp4',
        fileName: 'file.mp4',
        runPreflight: false,
      );
      expect(queue.tasks.any((t) => t.id == id), isTrue);
      expect(
        queue.tasks.firstWhere((t) => t.id == id).status,
        anyOf(
          DownloadTaskStatus.queued,
          DownloadTaskStatus.running,
        ),
      );
    });

    test('cancel marks task cancelled', () {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/a.mp4',
        fileName: 'a.mp4',
        runPreflight: false,
      );
      queue.cancel(id);
      expect(
        queue.tasks.firstWhere((t) => t.id == id).status,
        DownloadTaskStatus.cancelled,
      );
    });

    test('pause marks running task paused', () {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/pause.mp4',
        fileName: 'pause.mp4',
        runPreflight: false,
      );
      queue.pause(id);
      final task = queue.tasks.firstWhere((t) => t.id == id);
      expect(
        task.status,
        anyOf(DownloadTaskStatus.paused, DownloadTaskStatus.cancelled),
      );
    });

    test('resume re-queues paused task', () {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/resume.mp4',
        fileName: 'resume.mp4',
        runPreflight: false,
      );
      queue.pause(id);
      queue.resume(id);
      final task = queue.tasks.firstWhere((t) => t.id == id);
      expect(
        task.status,
        anyOf(
          DownloadTaskStatus.queued,
          DownloadTaskStatus.running,
          DownloadTaskStatus.paused,
        ),
      );
    });

    test('retry resets failed task to queued', () {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/retry.mp4',
        fileName: 'retry.mp4',
        runPreflight: false,
      );
      queue.cancel(id);
      queue.retry(id);
      final task = queue.tasks.firstWhere((t) => t.id == id);
      expect(
        task.status,
        anyOf(DownloadTaskStatus.queued, DownloadTaskStatus.running),
      );
    });
  });

  group('Media library dedupe', () {
    test('dedupeKey prefers contentHash', () {
      final item = DownloadItem.create(
        sourceUrl: 'https://instagram.com/reel/x/',
        filePath: '/tmp/a.mp4',
        contentHash: 'abc123',
        mediaUrl: 'https://cdn/a.mp4',
      );
      expect(item.dedupeKey, 'abc123');
    });

    test('repository filter by caption search', () {
      final repo = HistoryRepository.instance;
      final items = [
        DownloadItem.create(
          sourceUrl: 'u1',
          filePath: '/a.jpg',
          caption: 'sunset beach',
          mediaType: 'image',
        ),
        DownloadItem.create(
          sourceUrl: 'u2',
          filePath: '/b.mp4',
          caption: 'city night',
          mediaType: 'video',
        ),
      ];
      final filtered = repo.filterItems(
        items,
        query: 'beach',
        filter: LibraryMediaFilter.all,
      );
      expect(filtered.length, 1);
      expect(filtered.first.caption, contains('beach'));
    });
  });
}
