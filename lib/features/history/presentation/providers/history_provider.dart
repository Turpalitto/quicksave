import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/download_queue.dart';
import '../../data/history_repository.dart';
import '../../domain/download_item.dart';
import '../../domain/library_filter.dart';
import '../../domain/media_collection.dart';

class HistoryNotifier extends StateNotifier<List<DownloadItem>> {
  HistoryNotifier(this._repo) : super(const []) {
    _load();
  }

  final HistoryRepository _repo;

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<DedupeAddResult> add(DownloadItem item) async {
    final result = await _repo.addWithDedupe(item);
    state = await _repo.getAll();
    return result;
  }

  Future<void> removeMany(Set<String> ids, {bool deleteFiles = false}) async {
    if (deleteFiles) {
      for (final id in ids) {
        final item = state.where((e) => e.id == id).firstOrNull;
        if (item != null && item.filePath.isNotEmpty) {
          try {
            final file = File(item.filePath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
    }
    await _repo.removeMany(ids);
    state = await _repo.getAll();
  }

  Future<void> updateItem(DownloadItem item) async {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    await _repo.save(state);
  }

  /// Re-download failed item via [DownloadQueue] and update library entry.
  Future<bool> retryFailed(String id) async {
    final item = state.where((e) => e.id == id).firstOrNull;
    final mediaUrl = item?.mediaUrl;
    if (item == null ||
        !item.isFailed ||
        mediaUrl == null ||
        mediaUrl.isEmpty) {
      return false;
    }

    final fileName =
        item.displayFileName ??
        'quicksave_${item.id}.${item.isVideo ? 'mp4' : 'jpg'}';

    final taskId = DownloadQueue.instance.enqueue(
      url: mediaUrl,
      fileName: fileName,
    );
    final finished = await DownloadQueue.instance.waitForTask(taskId);

    if (finished.status == DownloadTaskStatus.completed &&
        finished.resultPath != null) {
      int? size;
      try {
        size = await File(finished.resultPath!).length();
      } catch (_) {
        size = item.fileSizeBytes;
      }
      final updated = item.copyWith(
        filePath: finished.resultPath!,
        status: LibraryItemStatus.completed,
        failureReason: null,
        fileSizeBytes: size,
      );
      await updateItem(updated);
      return true;
    }
    return false;
  }

  Future<MediaCollection> createCollection(String name) async {
    final created = await _repo.createCollection(name);
    return created;
  }

  Future<void> addToCollection(String collectionId, String itemId) async {
    await _repo.addToCollection(collectionId, itemId);
    state = await _repo.getAll();
  }

  Future<void> remove(String id, {bool deleteFile = false}) async {
    if (deleteFile) {
      final item = state.where((e) => e.id == id).firstOrNull;
      if (item != null && item.filePath.isNotEmpty) {
        try {
          final file = File(item.filePath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    await _repo.remove(id);
    state = await _repo.getAll();
  }

  Future<void> clear() async {
    state = const [];
    await _repo.clear();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<DownloadItem>>(
      (ref) => HistoryNotifier(HistoryRepository.instance),
    );

final collectionsProvider = FutureProvider<List<MediaCollection>>((ref) async {
  return HistoryRepository.instance.getCollections();
});
