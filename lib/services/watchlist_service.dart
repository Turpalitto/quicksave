import '../core/errors/exceptions.dart';
import '../features/downloader/data/instagram_resolver.dart';
import '../features/downloader/domain/resolve_result.dart';
import '../features/history/data/history_repository.dart';
import '../features/history/domain/download_item.dart';
import '../features/settings/domain/scheduled_profile.dart';
import '../features/settings/domain/scheduler_frequency.dart';

/// Result of a manual public profile check (user-initiated, first page only).
class WatchlistCheckResult {
  final List<MediaItem> newItems;
  final int alreadySavedCount;
  final int totalFound;
  final String? errorCode;

  const WatchlistCheckResult({
    this.newItems = const [],
    this.alreadySavedCount = 0,
    this.totalFound = 0,
    this.errorCode,
  });

  bool get ok => errorCode == null;
}

/// Safe manual profile check — no headless mass download.
class WatchlistService {
  WatchlistService._();
  static final WatchlistService instance = WatchlistService._();

  Future<WatchlistCheckResult> checkProfile({
    required ScheduledProfile profile,
    required String backendUrl,
  }) async {
    try {
      final result = await InstagramResolver.instance.resolve(
        instagramUrl: profile.profileUrl,
        backendUrl: backendUrl,
      );

      if (result.items.isEmpty) {
        return const WatchlistCheckResult(
          errorCode: 'no_public_posts',
          totalFound: 0,
        );
      }

      final history = await HistoryRepository.instance.getAll();
      final newItems = <MediaItem>[];
      var alreadySaved = 0;

      for (final item in result.items) {
        final probe = DownloadItem.create(
          sourceUrl: item.postUrl ?? profile.profileUrl,
          filePath: '',
          mediaUrl: item.mediaUrl,
          shortcode: item.shortcode,
          author: result.author ?? profile.username,
          mediaIndex: item.index,
        );
        if (HistoryRepository.instance.findDuplicate(history, probe) != null) {
          alreadySaved++;
        } else if (item.mediaUrl.isNotEmpty || item.needsResolve) {
          newItems.add(item);
        }
      }

      return WatchlistCheckResult(
        newItems: newItems,
        alreadySavedCount: alreadySaved,
        totalFound: result.items.length,
      );
    } on ProfileNotSupportedException {
      return const WatchlistCheckResult(errorCode: 'profile_not_supported');
    } catch (_) {
      return const WatchlistCheckResult(errorCode: 'resolve_failed');
    }
  }

  ScheduledProfile applyCheckResult(
    ScheduledProfile profile,
    WatchlistCheckResult result, {
    String? error,
  }) {
    final now = DateTime.now();
    if (!result.ok) {
      return profile.copyWith(
        lastCheckedAt: now,
        lastError: error ?? result.errorCode,
      );
    }
    return profile.copyWith(
      lastCheckedAt: now,
      lastSuccessAt: now,
      lastError: null,
      newItemsFound: result.newItems.length,
      totalSaved: profile.totalSaved,
      nextRunAt: profile.frequency.interval != null
          ? now.add(profile.frequency.interval!)
          : null,
    );
  }
}
