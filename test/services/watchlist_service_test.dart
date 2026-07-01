import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/history/data/history_repository.dart';
import 'package:quicksave/features/history/domain/download_item.dart';
import 'package:quicksave/features/settings/domain/scheduled_profile.dart';
import 'package:quicksave/services/watchlist_service.dart';

void main() {
  group('WatchlistService dedupe', () {
    test('findDuplicate skips known profile posts', () {
      final history = [
        DownloadItem.create(
          sourceUrl: 'https://www.instagram.com/p/ABC/',
          filePath: '/a.jpg',
          shortcode: 'ABC',
          author: 'creator',
        ),
      ];
      final probe = DownloadItem.create(
        sourceUrl: 'https://www.instagram.com/p/ABC/',
        filePath: '',
        shortcode: 'ABC',
        author: 'creator',
      );
      expect(
        HistoryRepository.instance.findDuplicate(history, probe),
        isNotNull,
      );
    });
  });

  group('WatchlistCheckResult', () {
    test('ok when no error code', () {
      const r = WatchlistCheckResult(totalFound: 3);
      expect(r.ok, isTrue);
    });

    test('not ok with error', () {
      const r = WatchlistCheckResult(errorCode: 'resolve_failed');
      expect(r.ok, isFalse);
    });

    test('not ok when profiles disabled', () {
      const r = WatchlistCheckResult(errorCode: 'profile_not_supported');
      expect(r.ok, isFalse);
    });
  });

  group('applyCheckResult', () {
    test('updates timestamps on success', () {
      const profile = ScheduledProfile(
        username: 'creator',
        profileUrl: 'https://www.instagram.com/creator/',
      );
      const result = WatchlistCheckResult(
        newItems: [],
        totalFound: 5,
        alreadySavedCount: 5,
      );
      final updated = WatchlistService.instance.applyCheckResult(
        profile,
        result,
      );
      expect(updated.lastCheckedAt, isNotNull);
      expect(updated.lastSuccessAt, isNotNull);
      expect(updated.lastError, isNull);
    });
  });
}
