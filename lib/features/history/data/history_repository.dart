import '../../../services/storage_service.dart';
import '../domain/download_item.dart';
import '../domain/media_collection.dart';
import '../domain/library_filter.dart';

/// Media library repository with dedupe, collections, filters, and sort.
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  static const recentWindow = Duration(days: 7);

  Future<List<DownloadItem>> getAll() => StorageService.instance.loadHistory();

  Future<List<MediaCollection>> getCollections() =>
      StorageService.instance.loadCollections();

  Future<void> save(List<DownloadItem> items) =>
      StorageService.instance.saveHistory(items);

  Future<void> saveCollections(List<MediaCollection> collections) =>
      StorageService.instance.saveCollections(collections);

  DownloadItem? findDuplicate(List<DownloadItem> items, DownloadItem item) {
    try {
      return items.firstWhere((e) => e.dedupeKey == item.dedupeKey);
    } catch (_) {
      return null;
    }
  }

  Future<DedupeAddResult> addWithDedupe(DownloadItem item) async {
    final current = await getAll();
    final existing = findDuplicate(current, item);
    if (existing != null) {
      return DedupeAddResult(
        kind: DedupeResultKind.duplicate,
        existing: existing,
      );
    }
    await save([item, ...current]);
    return const DedupeAddResult(kind: DedupeResultKind.added);
  }

  Future<void> add(DownloadItem item, {bool dedupe = true}) async {
    if (dedupe) {
      await addWithDedupe(item);
      return;
    }
    final current = await getAll();
    await save([item, ...current]);
  }

  Future<void> remove(String id) async {
    final current = await getAll();
    await save(current.where((e) => e.id != id).toList());
  }

  Future<void> removeMany(Set<String> ids) async {
    final current = await getAll();
    await save(current.where((e) => !ids.contains(e.id)).toList());
  }

  Future<void> clear() => StorageService.instance.clearHistory();

  List<DownloadItem> filterItems(
    List<DownloadItem> items, {
    required String query,
    required LibraryMediaFilter filter,
    String? collectionId,
    List<MediaCollection> collections = const [],
  }) {
    Iterable<DownloadItem> result = items;
    final now = DateTime.now();

    switch (filter) {
      case LibraryMediaFilter.reels:
        result = result.where(
          (i) => i.effectiveSourceKind == MediaSourceKind.reel,
        );
      case LibraryMediaFilter.video:
        result = result.where((i) => i.isVideo);
      case LibraryMediaFilter.image:
        result = result.where((i) => !i.isVideo);
      case LibraryMediaFilter.carousels:
        result = result.where(
          (i) =>
              i.effectiveSourceKind == MediaSourceKind.carousel ||
              (i.groupId != null && i.groupId!.isNotEmpty),
        );
      case LibraryMediaFilter.stories:
        result = result.where(
          (i) => i.effectiveSourceKind == MediaSourceKind.story,
        );
      case LibraryMediaFilter.highlights:
        result = result.where(
          (i) => i.effectiveSourceKind == MediaSourceKind.highlight,
        );
      case LibraryMediaFilter.profiles:
        result = result.where(
          (i) => i.effectiveSourceKind == MediaSourceKind.profile,
        );
      case LibraryMediaFilter.errors:
        result = result.where(
          (i) =>
              i.status == LibraryItemStatus.failed ||
              i.status == LibraryItemStatus.partial ||
              i.status == LibraryItemStatus.missingFile,
        );
      case LibraryMediaFilter.recent:
        result = result.where(
          (i) => now.difference(i.createdAt) <= recentWindow,
        );
      case LibraryMediaFilter.uncollected:
        result = result.where((i) => i.collectionIds.isEmpty);
      case LibraryMediaFilter.all:
        break;
    }

    if (collectionId != null && collectionId.isNotEmpty) {
      result = result.where((i) => i.collectionIds.contains(collectionId));
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) {
        if (i.searchBlob.contains(q)) return true;
        for (final c in collections) {
          if (i.collectionIds.contains(c.id) &&
              c.name.toLowerCase().contains(q)) {
            return true;
          }
        }
        return false;
      });
    }

    return result.toList();
  }

  List<DownloadItem> sortItems(
    List<DownloadItem> items,
    LibrarySortOption sort,
  ) {
    final sorted = [...items];
    switch (sort) {
      case LibrarySortOption.savedAtDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case LibrarySortOption.savedAtAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case LibrarySortOption.usernameAsc:
        sorted.sort((a, b) => (a.author ?? '').compareTo(b.author ?? ''));
      case LibrarySortOption.typeAsc:
        sorted.sort(
          (a, b) =>
              a.effectiveSourceKind.name.compareTo(b.effectiveSourceKind.name),
        );
      case LibrarySortOption.sizeDesc:
        sorted.sort(
          (a, b) => (b.fileSizeBytes ?? 0).compareTo(a.fileSizeBytes ?? 0),
        );
      case LibrarySortOption.statusAsc:
        sorted.sort((a, b) => a.status.name.compareTo(b.status.name));
    }
    return sorted;
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
    await save(
      items.map((item) {
        if (item.id != itemId) return item;
        if (item.collectionIds.contains(collectionId)) return item;
        return item.copyWith(
          collectionIds: [...item.collectionIds, collectionId],
        );
      }).toList(),
    );
  }

  Future<void> addManyToCollection(
    String collectionId,
    Iterable<String> itemIds,
  ) async {
    for (final id in itemIds) {
      await addToCollection(collectionId, id);
    }
  }
}
