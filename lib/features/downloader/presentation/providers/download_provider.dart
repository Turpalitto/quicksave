import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/gallery_save_service.dart';
import '../../../../services/download_service.dart';
import '../../../../services/notification_service.dart';
import '../../../history/domain/download_item.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/instagram_resolver.dart';
import '../../domain/resolve_result.dart';

sealed class DownloadState {
  const DownloadState();
}

class DownloadIdle extends DownloadState {
  const DownloadIdle();
}

class DownloadResolving extends DownloadState {
  const DownloadResolving();
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
  }) =>
      DownloadResolved(
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

  const DownloadInProgress({
    required this.completed,
    required this.total,
    required this.currentProgress,
    this.currentLabel,
  });

  double get overallProgress {
    if (total <= 0) return 0;
    return ((completed + currentProgress) / total).clamp(0.0, 1.0);
  }
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

  void _setResolved(DownloadResolved resolved) {
    _lastResolved = resolved;
    state = resolved;
  }

  Future<void> resolve(String url) async {
    state = const DownloadResolving();
    try {
      final backendUrl = ref.read(settingsProvider).effectiveBackendUrl;
      final result = await InstagramResolver.instance.resolve(
        instagramUrl: url,
        backendUrl: backendUrl,
      );
      _batchGroupId = const Uuid().v4();
      _setResolved(DownloadResolved(
        result: result,
        sourceUrl: url,
        selectedIds: result.items.map((i) => i.id).toSet(),
      ));
    } on AppException catch (e) {
      state = DownloadFailureState(mapExceptionToFailure(e));
    } catch (e) {
      state = DownloadFailureState(UnknownFailure(e.toString()));
    }
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
    _setResolved(current.copyWith(
      result: merged,
      selectedIds: {
        ...current.selectedIds,
        ...merged.items.map((i) => i.id),
      },
    ));
  }

  void selectAll() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(current.copyWith(
      selectedIds: current.result.items.map((i) => i.id).toSet(),
    ));
  }

  void deselectAll() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(current.copyWith(selectedIds: {}));
  }

  void selectVideosOnly() {
    final current = state;
    if (current is! DownloadResolved) return;
    _setResolved(current.copyWith(
      selectedIds: current.result.items
          .where((i) => i.isVideo)
          .map((i) => i.id)
          .toSet(),
    ));
  }

  Future<bool> loadMoreProfile() async {
    final current = state;
    if (current is! DownloadResolved) return false;
    final result = current.result;
    if (!result.hasMore ||
        result.nextCursor == null ||
        result.userId == null) {
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
    _setResolved(current.copyWith(
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
    ));
  }

  Future<void> download({
    DownloadStrings strings = DownloadStrings.fallback,
  }) async {
    final current = state;
    if (current is! DownloadResolved) return;

    final toDownload = current.selectedItems;
    if (toDownload.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final backendUrl = settings.effectiveBackendUrl;
    final groupId = _batchGroupId ?? const Uuid().v4();
    final saved = <DownloadItem>[];
    var failedCount = 0;
    _cancelRequested = false;

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

    state = DownloadInProgress(
      completed: 0,
      total: queue.length,
      currentProgress: 0,
    );

    try {
      for (var i = 0; i < queue.length; i++) {
        if (_cancelRequested) {
          if (_lastResolved != null) state = _lastResolved!;
          return;
        }

        final item = queue[i];
        state = DownloadInProgress(
          completed: i,
          total: queue.length,
          currentProgress: 0,
          currentLabel: item.fileName,
        );

        try {
          var savedPath = await DownloadService.instance.download(
            url: item.mediaUrl,
            fileName: item.fileName,
            subfolder: settings.saveInAuthorFolder
                ? _sanitizeFolderName(current.result.author)
                : null,
            onProgress: (p) {
              if (_cancelRequested) return;
              state = DownloadInProgress(
                completed: i,
                total: queue.length,
                currentProgress: p,
                currentLabel: item.fileName,
              );
            },
          );

          if (settings.saveToGallery) {
            savedPath = await GallerySaveService.instance.saveToGallery(
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
          );

          if (settings.saveHistory) {
            await ref.read(historyProvider.notifier).add(downloadItem);
          }
          saved.add(downloadItem);
        } on DownloadCancelledException {
          rethrow;
        } catch (_) {
          failedCount++;
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
    } on AppException catch (e) {
      if (saved.isNotEmpty || failedCount > 0) {
        if (saved.isNotEmpty) {
          state = DownloadSuccess(saved, failedCount: failedCount);
        } else {
          final failure = mapExceptionToFailure(e);
          state = DownloadFailureState(failure);
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
    DownloadService.instance.cancel();
    if (_lastResolved != null) {
      state = _lastResolved!;
    }
  }

  void reset() {
    _batchGroupId = null;
    _lastResolved = null;
    _cancelRequested = false;
    state = const DownloadIdle();
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
}

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>(
  DownloadNotifier.new,
);
