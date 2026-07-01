import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/download_queue.dart';
import '../../../../services/filename_template_engine.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/gallery_save_service.dart';
import '../../../../services/download_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/pending_download_service.dart';
import '../../../history/data/history_repository.dart';
import '../../../history/domain/download_item.dart';
import '../../../history/domain/library_filter.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/download_stage.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/instagram_resolver.dart';
import '../providers/pending_download_provider.dart';
import '../../domain/resolve_result.dart';

sealed class DownloadState {
  const DownloadState();
}

class DownloadIdle extends DownloadState {
  const DownloadIdle();
}

class DownloadResolving extends DownloadState {
  final int? attempt;
  final int? maxAttempts;

  const DownloadResolving({this.attempt, this.maxAttempts});
}

class DownloadResolved extends DownloadState {
  final ResolveResult result;
  final String sourceUrl;
  final Set<String> selectedIds;

  const DownloadResolved({
    required this.result,
    required this.sourceUrl,
    required this.selectedIds,
  });

  DownloadResolved copyWith({
    ResolveResult? result,
    Set<String>? selectedIds,
  }) => DownloadResolved(
    result: result ?? this.result,
    sourceUrl: sourceUrl,
    selectedIds: selectedIds ?? this.selectedIds,
  );

  List<MediaItem> get selectedItems =>
      result.items.where((i) => selectedIds.contains(i.id)).toList();

  int get selectedCount => selectedIds.length;
}

class DownloadInProgress extends DownloadState {
  final int completed;
  final int total;
  final double currentProgress;
  final String? currentLabel;
  final DownloadStage stage;

  const DownloadInProgress({
    required this.completed,
    required this.total,
    required this.currentProgress,
    this.currentLabel,
    this.stage = DownloadStage.downloading,
  });

  double get overallProgress {
    if (total <= 0) return 0;
    return ((completed + currentProgress) / total).clamp(0.0, 1.0);
  }
}

class DownloadAlreadySaved extends DownloadState {
  final DownloadItem existing;
  const DownloadAlreadySaved(this.existing);
}

class DownloadSuccess extends DownloadState {
  final List<DownloadItem> items;
  final int failedCount;

  const DownloadSuccess(this.items, {this.failedCount = 0});

  int get totalAttempted => items.length + failedCount;
  bool get isPartial => failedCount > 0 && items.isNotEmpty;
}

class DownloadFailureState extends DownloadState {
  final Failure failure;
  const DownloadFailureState(this.failure);
}

class DownloadStrings {
  final String completeTitle;
  final String completeBodyAuthorPrefix;
  final String completeBodyFallback;
  final String errorTitle;
  final String batchCompleteBody;
  final String channelName;
  final String channelDescription;

  const DownloadStrings({
    required this.completeTitle,
    required this.completeBodyAuthorPrefix,
    required this.completeBodyFallback,
    required this.errorTitle,
    this.batchCompleteBody = 'Сохранено файлов: {count}',
    this.channelName = 'Downloads',
    this.channelDescription = 'Download notifications',
  });

  static const fallback = DownloadStrings(
    completeTitle: 'Видео сохранено',
    completeBodyAuthorPrefix: 'Автор',
    completeBodyFallback: 'Файл сохранён в QuickSave',
    errorTitle: 'Ошибка скачивания',
    batchCompleteBody: 'Сохранено файлов: {count}',
    channelName: 'Downloads',
    channelDescription: 'Download notifications',
  );
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier(this.ref) : super(const DownloadIdle());

  final Ref ref;
  String? _batchGroupId;
  DownloadResolved? _lastResolved;
  bool _loadMoreFailed = false;
  bool get loadMoreFailed => _loadMoreFailed;

  void clearLoadMoreError() => _loadMoreFailed = false;

  bool _cancelRequested = false;
  CancelToken? _resolveCancelToken;

  void _setResolved(DownloadResolved resolved) {
    _lastResolved = resolved;
    state = resolved;
  }

  Future<void> resolve(String url) async {
    _resolveCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _resolveCancelToken = cancelToken;
    state = const DownloadResolving();
    try {
      final backendUrl = ref.read(settingsProvider).effectiveBackendUrl;
      final result = await InstagramResolver.instance.resolve(
        instagramUrl: url,
        backendUrl: backendUrl,
        cancelToken: cancelToken,
        onAttempt: (attempt, maxAttempts) {
          if (cancelToken.isCancelled) return;
          if (maxAttempts <= 1) return;
          state = DownloadResolving(attempt: attempt, maxAttempts: maxAttempts);
        },
      );
      _batchGroupId = const Uuid().v4();
      _setResolved(
        DownloadResolved(
          result: result,
          sourceUrl: url,
          selectedIds: result.items.map((i) => i.id).toSet(),
        ),
      );
    } on AppException catch (e) {
      if (e is DownloadCancelledException) {
        state = const DownloadIdle();
        return;
      }
      if (PendingDownloadService.isRetriable(e)) {
        await ref
            .read(pendingDownloadsProvider.notifier)
            .enqueue(url, error: e.message);
      }
      state = DownloadFailureState(mapExceptionToFailure(e));
    } catch (e) {
      state = DownloadFailureState(UnknownFailure(e.toString()));
    } finally {
      if (identical(_resolveCancelToken, cancelToken)) {
        _resolveCancelToken = null;
      }
    }
  }

  void cancelResolve() {
    _resolveCancelToken?.cancel('user_cancelled');
    _resolveCancelToken = null;
    state = const DownloadIdle();
  }

  /// Повторяет resolve для очереди «скачать позже» (вызывается с главного экрана).
  Future<bool> retryPendingUrl(String url) async {
    await resolve(url);
    return state is DownloadResolved;
  }

  Future<void> enqueuePending(String url, {String? error}) async {
    await ref.read(pendingDownloadsProvider.notifier).enqueue(url, error: error);
  }

  void toggleSelection(String id) {
    final current = state;
    if (current is! DownloadResolved) return;
    final next = Set<String>.from(current.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _setResolved(current.copyWith(selectedIds: next));
  }

  void mergeProfileItems(ResolveResult merged) {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(
      current.copyWith(
        result: merged,
        selectedIds: {...current.selectedIds, ...merged.items.map((i) => i.id)},
      ),
    );
  }

  void selectAll() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(
      current.copyWith(
        selectedIds: current.result.items.map((i) => i.id).toSet(),
      ),
    );
  }

  void deselectAll() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(current.copyWith(selectedIds: {}));
  }

  void selectVideosOnly() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(
      current.copyWith(
        selectedIds: current.result.items
            .where((i) => i.isVideo)
            .map((i) => i.id)
            .toSet(),
      ),
    );
  }

  Future<bool> loadMoreProfile() async {
    final current = state;
    if (current is! DownloadResolved) return false;
    final result = current.result;
    if (!result.hasMore || result.nextCursor == null || result.userId == null) {
      return false;
    }

    _loadMoreFailed = false;
    try {
      final backendUrl = ref.read(settingsProvider).effectiveBackendUrl;
      final page = await InstagramResolver.instance.resolve(
        instagramUrl: current.sourceUrl,
        backendUrl: backendUrl,
        cursor: result.nextCursor,
        userId: result.userId,
      );
      mergeProfileItems(result.mergeItems(page));
      return true;
    } catch (_) {
      _loadMoreFailed = true;
      return false;
    }
  }

  void setItemQuality(String itemId, VideoQuality quality) {
    final current = state;
    if (current is! DownloadResolved) return;
    final items = current.result.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(
        mediaUrl: quality.url,
        fileName: item.fileName.replaceAll(
          RegExp(r'\.mp4$'),
          '_${quality.width}p.mp4',
        ),
      );
    }).toList();
    _setResolved(
      current.copyWith(
        result: ResolveResult(
          type: current.result.type,
          sourceUrl: current.result.sourceUrl,
          items: items,
          author: current.result.author,
          shortcode: current.result.shortcode,
          videoCount: current.result.videoCount,
          imageCount: current.result.imageCount,
          userId: current.result.userId,
          nextCursor: current.result.nextCursor,
          hasMore: current.result.hasMore,
        ),
      ),
    );
  }

  Future<void> download({
    DownloadStrings strings = DownloadStrings.fallback,
  }) async {
    final current = state;
    if (current is! DownloadResolved) return;

    final toDownload = current.selectedItems;
    if (toDownload.isEmpty) return;

    state = const DownloadInProgress(
      completed: 0,
      total: 1,
      currentProgress: 0,
      stage: DownloadStage.analyzing,
    );

    final settings = ref.read(settingsProvider);
    final backendUrl = settings.effectiveBackendUrl;
    final groupId = _batchGroupId ?? const Uuid().v4();
    final saved = <DownloadItem>[];
    var failedCount = 0;
    var alreadySavedCount = 0;
    _cancelRequested = false;

    state = DownloadInProgress(
      completed: 0,
      total: toDownload.length,
      currentProgress: 0,
      stage: DownloadStage.resolvingMedia,
    );

    final queue = <MediaItem>[];
    for (final item in toDownload) {
      if (_cancelRequested) break;
      queue.addAll(await _resolveDownloadItems(item, backendUrl));
    }

    if (_cancelRequested) {
      if (_lastResolved != null) state = _lastResolved!;
      return;
    }

    if (queue.isEmpty) return;

    if (queue.length == 1 && settings.saveHistory) {
      final probe = _probeItem(
        current: current,
        media: queue.first,
        settings: settings,
      );
      final dup = HistoryRepository.instance.findDuplicate(
        ref.read(historyProvider),
        probe,
      );
      if (dup != null) {
        state = DownloadAlreadySaved(dup);
        return;
      }
    }

    state = DownloadInProgress(
      completed: 0,
      total: queue.length,
      currentProgress: 0,
      stage: DownloadStage.preparing,
    );

    try {
      for (var i = 0; i < queue.length; i++) {
        if (_cancelRequested) {
          if (_lastResolved != null) state = _lastResolved!;
          return;
        }

        final item = queue[i];
        final fileName = _resolveFileName(
          settings: settings,
          result: current.result,
          media: item,
        );

        state = DownloadInProgress(
          completed: i,
          total: queue.length,
          currentProgress: 0,
          currentLabel: fileName,
          stage: DownloadStage.downloading,
        );

        try {
          final savedPath = await _downloadMediaWithReResolve(
            media: item,
            current: current,
            backendUrl: backendUrl,
            fileName: fileName,
            subfolder: settings.saveInAuthorFolder
                ? _sanitizeFolderName(current.result.author)
                : null,
            onProgress: (progress) {
              state = DownloadInProgress(
                completed: i,
                total: queue.length,
                currentProgress: progress,
                currentLabel: fileName,
                stage: DownloadStage.downloading,
              );
            },
          );

          if (savedPath == null) {
            failedCount++;
            if (settings.saveHistory) {
              await ref
                  .read(historyProvider.notifier)
                  .add(
                    DownloadItem.failed(
                      sourceUrl: current.sourceUrl,
                      mediaUrl: item.mediaUrl,
                      displayFileName: fileName,
                      author: current.result.author,
                      sourceKind: _sourceKindFromResult(current.result.type),
                      provenance: _buildProvenance(
                        settings: settings,
                        sourceUrl: current.sourceUrl,
                        result: current.result,
                        media: item,
                      ),
                    ),
                  );
            }
            continue;
          }

          state = DownloadInProgress(
            completed: i,
            total: queue.length,
            currentProgress: 0.9,
            currentLabel: fileName,
            stage: DownloadStage.saving,
          );

          if (settings.saveToGallery) {
            await GallerySaveService.instance.saveToGallery(
              savedPath,
              isVideo: item.isVideo,
            );
          }

          int? fileSize;
          try {
            fileSize = await File(savedPath).length();
          } catch (_) {
            fileSize = null;
          }

          final downloadItem = DownloadItem.create(
            sourceUrl: current.sourceUrl,
            filePath: savedPath,
            thumbnailUrl: item.thumbnailUrl,
            author: current.result.author,
            caption: current.result.caption,
            postDate: current.result.postDate,
            fileSizeBytes: fileSize,
            mediaIndex: item.index,
            mediaType: item.isVideo ? 'video' : 'image',
            groupId: groupId,
            mediaUrl: item.mediaUrl,
            displayFileName: fileName,
            shortcode: item.shortcode ?? current.result.shortcode,
            sourceKind: _sourceKindFromResult(current.result.type),
            provenance: _buildProvenance(
              settings: settings,
              sourceUrl: current.sourceUrl,
              result: current.result,
              media: item,
            ),
          );

          if (settings.saveHistory) {
            final dedupe = await ref
                .read(historyProvider.notifier)
                .add(downloadItem);
            if (dedupe.kind == DedupeResultKind.duplicate &&
                dedupe.existing != null) {
              alreadySavedCount++;
              continue;
            }
          }
          saved.add(downloadItem);
        } on DownloadCancelledException {
          rethrow;
        } on UrlExpiredException {
          rethrow;
        } catch (_) {
          failedCount++;
        }
      }

      if (saved.isEmpty && alreadySavedCount > 0 && failedCount == 0) {
        final all = ref.read(historyProvider);
        final last = all.isNotEmpty ? all.first : null;
        if (last != null) {
          state = DownloadAlreadySaved(last);
          return;
        }
      }

      if (saved.isEmpty && failedCount > 0) {
        state = DownloadFailureState(
          UnknownFailure('All $failedCount downloads failed'),
        );
        return;
      }

      if (settings.notificationsEnabled && saved.isNotEmpty) {
        final body = saved.length == 1 && failedCount == 0
            ? (current.result.author != null
                  ? '${strings.completeBodyAuthorPrefix}: ${current.result.author}'
                  : strings.completeBodyFallback)
            : strings.batchCompleteBody.replaceAll(
                '{count}',
                '${saved.length}',
              );
        await NotificationService.instance.showDownloadComplete(
          title: strings.completeTitle,
          body: body,
          payload: saved.first.filePath,
          channelName: strings.channelName,
          channelDescription: strings.channelDescription,
        );
      }

      state = DownloadSuccess(saved, failedCount: failedCount);
    } on DownloadCancelledException catch (_) {
      if (_lastResolved != null) {
        state = _lastResolved!;
      }
    } on UrlExpiredException catch (_) {
      if (saved.isNotEmpty) {
        state = DownloadSuccess(saved, failedCount: failedCount + 1);
        return;
      }
      const failure = UrlExpiredFailure();
      state = const DownloadFailureState(UrlExpiredFailure());
      if (settings.notificationsEnabled) {
        await NotificationService.instance.showDownloadError(
          failure.message,
          title: strings.errorTitle,
          channelName: strings.channelName,
          channelDescription: strings.channelDescription,
        );
      }
    } on AppException catch (e) {
      if (saved.isNotEmpty || failedCount > 0) {
        if (saved.isNotEmpty) {
          state = DownloadSuccess(saved, failedCount: failedCount);
        } else {
          state = DownloadFailureState(mapExceptionToFailure(e));
        }
        return;
      }
      final failure = mapExceptionToFailure(e);
      state = DownloadFailureState(failure);
      if (settings.notificationsEnabled) {
        await NotificationService.instance.showDownloadError(
          failure.message,
          title: strings.errorTitle,
          channelName: strings.channelName,
          channelDescription: strings.channelDescription,
        );
      }
    } catch (e) {
      if (e is UrlExpiredException) {
        if (saved.isNotEmpty) {
          state = DownloadSuccess(saved, failedCount: failedCount + 1);
          return;
        }
        const failure = UrlExpiredFailure();
        state = const DownloadFailureState(UrlExpiredFailure());
        if (settings.notificationsEnabled) {
          await NotificationService.instance.showDownloadError(
            failure.message,
            title: strings.errorTitle,
            channelName: strings.channelName,
            channelDescription: strings.channelDescription,
          );
        }
        return;
      }
      if (saved.isNotEmpty || failedCount > 0) {
        if (saved.isNotEmpty) {
          state = DownloadSuccess(saved, failedCount: failedCount);
        } else {
          state = DownloadFailureState(UnknownFailure(e.toString()));
        }
        return;
      }
      state = DownloadFailureState(UnknownFailure(e.toString()));
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
    DownloadQueue.instance.cancelAll();
    DownloadService.instance.cancel();
    if (_lastResolved != null) {
      state = _lastResolved!;
    }
  }

  void reset() {
    _resolveCancelToken?.cancel('reset');
    _resolveCancelToken = null;
    _batchGroupId = null;
    _lastResolved = null;
    _cancelRequested = false;
    state = const DownloadIdle();
  }

  /// Скачивает медиа через очередь; при истёкшем CDN URL — один auto re-resolve.
  Future<String?> _downloadMediaWithReResolve({
    required MediaItem media,
    required DownloadResolved current,
    required String backendUrl,
    required String fileName,
    String? subfolder,
    void Function(double progress)? onProgress,
  }) async {
    var activeMedia = media;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final path = await _runQueueDownload(
          url: activeMedia.mediaUrl,
          fileName: fileName,
          subfolder: subfolder,
          onProgress: onProgress,
        );
        return path;
      } on UrlExpiredException {
        if (attempt == 1) rethrow;
        activeMedia = await _refreshExpiredMediaUrl(
          activeMedia,
          current,
          backendUrl,
        );
        _applyRefreshedMedia(current, activeMedia);
      }
    }

    return null;
  }

  Future<String?> _runQueueDownload({
    required String url,
    required String fileName,
    String? subfolder,
    void Function(double progress)? onProgress,
  }) async {
    final taskId = DownloadQueue.instance.enqueue(
      url: url,
      fileName: fileName,
      subfolder: subfolder,
    );

    DownloadQueueTask finished = await DownloadQueue.instance.waitForTask(
      taskId,
    );
    while (finished.status == DownloadTaskStatus.running ||
        finished.status == DownloadTaskStatus.queued) {
      onProgress?.call(finished.progress);
      finished = await DownloadQueue.instance.waitForTask(taskId);
    }

    if (finished.status == DownloadTaskStatus.completed &&
        finished.resultPath != null) {
      return finished.resultPath;
    }
    if (finished.status == DownloadTaskStatus.failed &&
        finished.errorMessage == DownloadQueue.urlExpiredError) {
      throw const UrlExpiredException();
    }
    return null;
  }

  Future<MediaItem> _refreshExpiredMediaUrl(
    MediaItem item,
    DownloadResolved current,
    String backendUrl,
  ) async {
    final target = item.postUrl ?? current.sourceUrl;
    final resolved = await InstagramResolver.instance.resolve(
      instagramUrl: target,
      backendUrl: backendUrl,
    );

    MediaItem? fresh;
    for (final m in resolved.items) {
      if (m.id == item.id) {
        fresh = m;
        break;
      }
    }
    if (fresh == null) {
      for (final m in resolved.items) {
        if (m.index == item.index && m.isVideo == item.isVideo) {
          fresh = m;
          break;
        }
      }
    }
    if (fresh == null && item.isVideo) {
      fresh = resolved.firstVideo;
    }
    if (fresh == null) {
      for (final m in resolved.items) {
        if (m.mediaUrl.isNotEmpty) {
          fresh = m;
          break;
        }
      }
    }

    if (fresh == null || fresh.mediaUrl.isEmpty) {
      throw const ResolverException();
    }

    return item.copyWith(
      mediaUrl: fresh.mediaUrl,
      fileName: fresh.fileName.isNotEmpty ? fresh.fileName : item.fileName,
      thumbnailUrl: fresh.thumbnailUrl ?? item.thumbnailUrl,
      needsResolve: false,
    );
  }

  void _applyRefreshedMedia(DownloadResolved current, MediaItem refreshed) {
    final items = current.result.items
        .map((m) => m.id == refreshed.id ? refreshed : m)
        .toList();
    _setResolved(
      DownloadResolved(
        result: ResolveResult(
          type: current.result.type,
          sourceUrl: current.result.sourceUrl,
          items: items,
          author: current.result.author,
          shortcode: current.result.shortcode,
          videoCount: current.result.videoCount,
          imageCount: current.result.imageCount,
          userId: current.result.userId,
          nextCursor: current.result.nextCursor,
          hasMore: current.result.hasMore,
          caption: current.result.caption,
          postDate: current.result.postDate,
        ),
        sourceUrl: current.sourceUrl,
        selectedIds: current.selectedIds,
      ),
    );
  }

  /// Резолвит элемент профиля; для карусели возвращает все слайды.
  Future<List<MediaItem>> _resolveDownloadItems(
    MediaItem item,
    String backendUrl,
  ) async {
    if (item.canDownloadDirectly) return [item];

    final resolveUrl = item.postUrl;
    if (resolveUrl == null || resolveUrl.isEmpty) {
      throw const ResolverException();
    }

    final resolved = await InstagramResolver.instance.resolve(
      instagramUrl: resolveUrl,
      backendUrl: backendUrl,
    );

    if (resolved.items.length > 1) {
      return resolved.items
          .where((m) => m.mediaUrl.isNotEmpty)
          .map((m) => m.copyWith(needsResolve: false))
          .toList();
    }

    MediaItem? media = resolved.firstVideo;
    if (media == null || media.mediaUrl.isEmpty) {
      for (final m in resolved.items) {
        if (m.mediaUrl.isNotEmpty) {
          media = m;
          break;
        }
      }
    }

    if (media == null || media.mediaUrl.isEmpty) {
      throw const ResolverException();
    }

    return [
      item.copyWith(
        mediaUrl: media.mediaUrl,
        fileName: media.fileName.isNotEmpty ? media.fileName : item.fileName,
        needsResolve: false,
      ),
    ];
  }

  String? _sanitizeFolderName(String? author) {
    if (author == null || author.trim().isEmpty) return null;
    final clean = author
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    if (clean.isEmpty || clean.length > 64) return null;
    return clean;
  }

  MediaSourceKind _sourceKindFromResult(ResolveType? type) {
    switch (type) {
      case ResolveType.story:
        return MediaSourceKind.story;
      case ResolveType.highlight:
        return MediaSourceKind.highlight;
      case ResolveType.profile:
        return MediaSourceKind.profile;
      case ResolveType.carousel:
        return MediaSourceKind.carousel;
      case ResolveType.single:
        return MediaSourceKind.post;
      case null:
        return MediaSourceKind.unknown;
    }
  }

  DownloadItem _probeItem({
    required DownloadResolved current,
    required MediaItem media,
    required AppSettings settings,
  }) => DownloadItem.create(
    sourceUrl: current.sourceUrl,
    filePath: '',
    mediaUrl: media.mediaUrl,
    shortcode: media.shortcode ?? current.result.shortcode,
    author: current.result.author,
    mediaIndex: media.index,
    sourceKind: _sourceKindFromResult(current.result.type),
  );

  String _resolveFileName({
    required AppSettings settings,
    required ResolveResult result,
    required MediaItem media,
  }) {
    if (!settings.canUseFilenameTemplates) {
      return media.fileName;
    }
    final preset = settings.filenameTemplatePreset;
    final template = preset == FilenameTemplatePreset.custom
        ? (settings.customFilenameTemplate.isNotEmpty
              ? settings.customFilenameTemplate
              : FilenameTemplateEngine.presetTemplate(preset))
        : FilenameTemplateEngine.presetTemplate(preset);
    final ext = media.isVideo ? 'mp4' : 'jpg';
    final typeLabel = _mediaTypeLabel(result.type, media);
    final shortcode =
        media.shortcode ?? result.shortcode ?? 'item${media.index}';
    return FilenameTemplateEngine.apply(
      template: template,
      username: result.author ?? 'unknown',
      type: typeLabel,
      shortcode: shortcode,
      date: DateTime.now(),
      extension: ext,
    );
  }

  String _mediaTypeLabel(ResolveType type, MediaItem media) {
    if (type == ResolveType.carousel) return 'carousel';
    if (type == ResolveType.story) return 'story';
    if (type == ResolveType.highlight) return 'highlight';
    if (type == ResolveType.profile) return 'profile';
    if (media.isVideo) return 'reel';
    return 'post';
  }

  MediaProvenance _buildProvenance({
    required AppSettings settings,
    required String sourceUrl,
    required ResolveResult result,
    required MediaItem media,
  }) => MediaProvenance(
    originalUrl: sourceUrl,
    resolvedUrl: media.postUrl ?? sourceUrl,
    contentType: media.isVideo ? 'video' : 'image',
    username: result.author,
    shortcode: media.shortcode ?? result.shortcode,
    mediaId: media.id,
    savedAt: DateTime.now(),
    appVersion: AppInfoService.instance.version,
    backendMode: settings.backendMode.name,
    userInitiated: true,
  );
}

final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>(
  DownloadNotifier.new,
);
