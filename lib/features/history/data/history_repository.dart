import '../../../services/storage_service.dart';
import '../domain/download_item.dart';
import '../domain/media_collection.dart';
import '../domain/library_filter.dart';

/// Media library repository with dedupe, collections, and migration.
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  Future<List<DownloadItem>> getAll() =>
      StorageService.instance.loadHistory();

  Future<List<MediaCollection>> getCollections() =>
      StorageService.instance.loadCollections();

  Future<void> save(List<DownloadItem> items) =>
      StorageService.instance.saveHistory(items);

  Future<void> saveCollections(List<MediaCollection> collections) =>
      StorageService.instance.saveCollections(collections);

  Future<void> add(DownloadItem item, {bool dedupe = true}) async {
    final current = await getAll();
    if (dedupe) {
      final exists = current.any((e) => e.dedupeKey == item.dedupeKey);
      if (exists) return;
    }
    await save([item, ...current]);
  }

  Future<void> remove(String id) async {
    final current = await getAll();
    await save(current.where((e) => e.id != id).toList());
  }

  Future<void> clear() => StorageService.instance.clearHistory();

  List<DownloadItem> filterItems(
    List<DownloadItem> items, {
    required String query,
    required LibraryMediaFilter filter,
    String? collectionId,
  }) {
    Iterable<DownloadItem> result = items;

    switch (filter) {
      case LibraryMediaFilter.video:
        result = result.where((i) => i.isVideo);
      case LibraryMediaFilter.image:
        result = result.where((i) => !i.isVideo);
      case LibraryMediaFilter.stories:
        result = result.where((i) =>
            i.sourceKind == MediaSourceKind.story ||
            i.sourceKind == MediaSourceKind.highlight);
      case LibraryMediaFilter.profiles:
        result = result.where((i) => i.sourceKind == MediaSourceKind.profile);
      case LibraryMediaFilter.all:
        break;
    }

    if (collectionId != null && collectionId.isNotEmpty) {
      result = result.where((i) => i.collectionIds.contains(collectionId));
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) => i.searchBlob.contains(q));
    }

    return result.toList();
  }

  Future<MediaCollection> createCollection(String name) async {
    final collections = await getCollections();
    final created = MediaCollection.create(name);
    await saveCollections([created, ...collections]);
    return created;
  }

  Future<void> addToCollection(String collectionId, String itemId) async {
    final collections = await getCollections();
    final updated = collections.map((c) {
      if (c.id != collectionId) return c;
      if (c.itemIds.contains(itemId)) return c;
      return c.copyWith(itemIds: [...c.itemIds, itemId]);
    }).toList();
    await saveCollections(updated);

    final items = await getAll();
    await save(items.map((item) {
      if (item.id != itemId) return item;
      if (item.collectionIds.contains(collectionId)) return item;
      return item.copyWith(
        collectionIds: [...item.collectionIds, collectionId],
      );
    }).toList());
  }
}
