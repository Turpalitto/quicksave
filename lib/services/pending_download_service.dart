import 'package:uuid/uuid.dart';

import '../core/errors/exceptions.dart';
import '../features/downloader/data/pending_download_repository.dart';
import '../features/downloader/domain/pending_download.dart';

/// Очередь «скачать позже» при временных сбоях resolve/backend.
class PendingDownloadService {
  PendingDownloadService._();
  static final PendingDownloadService instance = PendingDownloadService._();

  static const maxAttempts = 8;
  static const maxItems = 50;

  final _repo = PendingDownloadRepository.instance;

  /// Ошибки, при которых имеет смысл повторить позже.
  static bool isRetriable(AppException ex) =>
      ex is BackendUnreachableException ||
      ex is ResolverException ||
      ex is RateLimitedException ||
      ex is ServerException;

  Future<List<PendingDownload>> list() => _repo.loadAll();

  Future<int> count() async => (await list()).length;

  Future<bool> contains(String sourceUrl) async {
    final normalized = sourceUrl.trim().toLowerCase();
    final items = await list();
    return items.any((i) => i.sourceUrl.trim().toLowerCase() == normalized);
  }

  Future<PendingDownload?> enqueue(String sourceUrl, {String? error}) async {
    final url = sourceUrl.trim();
    if (url.isEmpty) return null;
    var items = await list();
    final existing = items.indexWhere(
      (i) => i.sourceUrl.trim().toLowerCase() == url.toLowerCase(),
    );
    if (existing >= 0) {
      final updated = items[existing].copyWith(
        lastError: error,
        lastAttemptAt: DateTime.now(),
      );
      items[existing] = updated;
      await _repo.saveAll(items);
      return updated;
    }
    final item = PendingDownload(
      id: const Uuid().v4(),
      sourceUrl: url,
      createdAt: DateTime.now(),
      lastError: error,
    );
    items = [item, ...items];
    if (items.length > maxItems) {
      items = items.sublist(0, maxItems);
    }
    await _repo.saveAll(items);
    return item;
  }

  Future<void> remove(String id) async {
    final items = await list();
    await _repo.saveAll(items.where((i) => i.id != id).toList());
  }

  Future<void> removeByUrl(String sourceUrl) async {
    final url = sourceUrl.trim().toLowerCase();
    final items = await list();
    await _repo.saveAll(
      items.where((i) => i.sourceUrl.trim().toLowerCase() != url).toList(),
    );
  }

  Future<void> recordAttempt(String id, {String? error}) async {
    final items = await list();
    final idx = items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(
      attempts: items[idx].attempts + 1,
      lastAttemptAt: DateTime.now(),
      lastError: error,
    );
    await _repo.saveAll(items);
  }

  Future<void> clearExpired() async {
    final items = await list();
    await _repo.saveAll(
      items.where((i) => i.attempts < maxAttempts).toList(),
    );
  }
}
