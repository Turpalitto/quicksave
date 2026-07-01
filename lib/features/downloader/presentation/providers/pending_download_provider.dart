import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/pending_download_service.dart';
import '../../domain/pending_download.dart';

final pendingDownloadsProvider =
    StateNotifierProvider<PendingDownloadsNotifier, List<PendingDownload>>(
      (ref) => PendingDownloadsNotifier(),
    );

class PendingDownloadsNotifier extends StateNotifier<List<PendingDownload>> {
  PendingDownloadsNotifier() : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    state = await PendingDownloadService.instance.list();
  }

  Future<void> enqueue(String url, {String? error}) async {
    await PendingDownloadService.instance.enqueue(url, error: error);
    await refresh();
  }

  Future<void> remove(String id) async {
    await PendingDownloadService.instance.remove(id);
    await refresh();
  }

  Future<void> removeByUrl(String url) async {
    await PendingDownloadService.instance.removeByUrl(url);
    await refresh();
  }
}
