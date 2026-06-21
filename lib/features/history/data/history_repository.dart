import '../../../services/storage_service.dart';
import '../domain/download_item.dart';

/// Репозиторий истории скачиваний.
/// Тонкая обёртка над [StorageService], инкапсулирующая логику доступа.
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  Future<List<DownloadItem>> getAll() =>
      StorageService.instance.loadHistory();

  Future<void> save(List<DownloadItem> items) =>
      StorageService.instance.saveHistory(items);

  Future<void> add(DownloadItem item) async {
    final current = await getAll();
    await save([item, ...current]);
  }

  Future<void> remove(String id) async {
    final current = await getAll();
    await save(current.where((e) => e.id != id).toList());
  }

  Future<void> clear() => StorageService.instance.clearHistory();
}
