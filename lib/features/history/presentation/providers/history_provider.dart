import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/history_repository.dart';
import '../../domain/download_item.dart';

class HistoryNotifier extends StateNotifier<List<DownloadItem>> {
  HistoryNotifier(this._repo) : super(const []) {
    _load();
  }

  final HistoryRepository _repo;

  Future<void> _load() async {
    final items = await _repo.getAll();
    state = items;
  }

  Future<void> add(DownloadItem item) async {
    state = [item, ...state];
    await _repo.save(state);
  }

  Future<void> remove(String id, {bool deleteFile = false}) async {
    if (deleteFile) {
      final item = state.where((e) => e.id == id).firstOrNull;
      if (item != null) {
        try {
          final file = File(item.filePath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    state = state.where((e) => e.id != id).toList();
    await _repo.save(state);
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
