/// Human-readable stages shown during download flow.
enum DownloadStage {
  analyzing,
  resolvingMedia,
  preparing,
  downloading,
  saving,
  addedToLibrary,
}

extension DownloadStageLabel on DownloadStage {
  String l10nKey() {
    switch (this) {
      case DownloadStage.analyzing:
        return 'downloadStageAnalyzing';
      case DownloadStage.resolvingMedia:
        return 'downloadStageResolving';
      case DownloadStage.preparing:
        return 'downloadStagePreparing';
      case DownloadStage.downloading:
        return 'downloadStageDownloading';
      case DownloadStage.saving:
        return 'downloadStageSaving';
      case DownloadStage.addedToLibrary:
        return 'downloadStageAddedToLibrary';
    }
  }
}
