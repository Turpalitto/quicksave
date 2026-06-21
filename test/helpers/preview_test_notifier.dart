import 'package:quicksave/features/downloader/presentation/providers/download_provider.dart';

/// Stub [DownloadNotifier] that keeps a fixed state and no-ops resolve.
class PreviewTestDownloadNotifier extends DownloadNotifier {
  PreviewTestDownloadNotifier(super.ref, DownloadState initial) {
    state = initial;
  }

  @override
  Future<void> resolve(String url) async {}
}
