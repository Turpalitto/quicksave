// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuickSave';

  @override
  String get homeHeroTitle => 'Save Instagram media';

  @override
  String get homeHeroSubtitle => 'Share a link from Instagram to QuickSave';

  @override
  String get urlFieldHint => 'Post, reel, story or @profile';

  @override
  String get urlFieldPaste => 'Paste';

  @override
  String get downloadButton => 'Download';

  @override
  String get homeTip =>
      'Share from Instagram, paste a link, or enter @username to browse a profile grid.';

  @override
  String get homeClipboardDetected => 'Instagram link detected in clipboard';

  @override
  String homeFooter(String version) {
    return 'Only public posts • v$version';
  }

  @override
  String get errorEnterUrl => 'Enter a link.';

  @override
  String get errorInvalidUrl =>
      'The link must point to a public Instagram post, story, highlight, or profile.';

  @override
  String get errorNotRecognized => 'Could not recognize the Instagram link.';

  @override
  String get previewTitle => 'Preview';

  @override
  String get previewResolving => 'Fetching video info…';

  @override
  String previewSource(String source) {
    return 'Source: $source';
  }

  @override
  String get previewDownload => 'Download';

  @override
  String get previewCancel => 'Cancel';

  @override
  String previewDownloading(String percent) {
    return 'Downloading… $percent';
  }

  @override
  String get previewStop => 'Cancel';

  @override
  String get previewSuccess => 'Done!';

  @override
  String get previewSavedTo => 'Saved to QuickSave';

  @override
  String get previewOpen => 'Open video';

  @override
  String get previewShare => 'Share';

  @override
  String previewDownloadSelected(int count) {
    return 'Download selected ($count)';
  }

  @override
  String previewTypeCarousel(int count) {
    return 'Carousel · $count items';
  }

  @override
  String get previewTypeStory => 'Story';

  @override
  String previewTypeHighlight(int count) {
    return 'Highlights · $count';
  }

  @override
  String get previewTypeSingle => 'Single post';

  @override
  String get previewSelectAll => 'Select all';

  @override
  String get previewDeselectAll => 'Clear';

  @override
  String get previewVideosOnly => 'Videos only';

  @override
  String previewBatchProgress(int current, int total) {
    return 'Downloading $current of $total…';
  }

  @override
  String previewBatchSaved(String count) {
    return 'Saved $count files';
  }

  @override
  String previewBatchSavedCount(int count) {
    return '$count files saved to QuickSave';
  }

  @override
  String previewPartialSuccess(int saved, int total, int failed) {
    return 'Saved $saved of $total files ($failed failed)';
  }

  @override
  String previewTypeProfile(int count) {
    return 'Profile · $count posts';
  }

  @override
  String get previewShareAll => 'Share all';

  @override
  String get previewGoHome => 'Home';

  @override
  String get previewLoadMore => 'Load more posts';

  @override
  String get previewTapToPreview => 'Tap to preview';

  @override
  String get previewQualityTitle => 'Choose quality';

  @override
  String get recentLinksTitle => 'Recent links';

  @override
  String get errorNoInternet => 'No internet connection. Check your network.';

  @override
  String get errorPrivatePost => 'Post is private or requires Instagram login.';

  @override
  String get errorNotFoundPost => 'Post not found. Check the link.';

  @override
  String get errorResolverFailed =>
      'Could not get a direct link. Try another public post.';

  @override
  String get errorServer => 'Server error. Try again later.';

  @override
  String get errorNoSpace => 'Not enough space on device.';

  @override
  String get errorFileWrite => 'Could not save the file.';

  @override
  String get errorCancelled => 'Download cancelled.';

  @override
  String get errorUnknown => 'Unknown error.';

  @override
  String get errorRetry => 'Retry';

  @override
  String errorOpenFailed(String message) {
    return 'Could not open: $message';
  }

  @override
  String get errorFileMissing => 'File not found.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'History is empty';

  @override
  String get historyEmptySubtitle => 'Downloaded media will appear here.';

  @override
  String get historySearchHint => 'Search by author or URL';

  @override
  String get historySearchEmpty => 'No results for your search.';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterVideo => 'Videos';

  @override
  String get historyFilterImage => 'Photos';

  @override
  String get historyFilterStories => 'Stories';

  @override
  String get historyFilterProfiles => 'Profiles';

  @override
  String get historyDeleteFileTitle => 'Delete file?';

  @override
  String get historyDeleteFileBody =>
      'Remove the file from device storage and history.';

  @override
  String get historyDeleteFileConfirm => 'Delete file';

  @override
  String get historyDeleteRecordBody => 'Remove this entry from history?';

  @override
  String historyBatchFiles(int count) {
    return '$count files';
  }

  @override
  String get historyClearAll => 'Clear all';

  @override
  String get historyClearConfirmTitle => 'Clear history?';

  @override
  String get historyClearConfirmBody =>
      'All records will be deleted. Files will remain.';

  @override
  String get historyClearConfirmYes => 'Clear';

  @override
  String get historyClearConfirmNo => 'Cancel';

  @override
  String get historyFileUnavailable => 'file unavailable';

  @override
  String get historyActionOpen => 'Open';

  @override
  String get historyActionShare => 'Share';

  @override
  String get historyActionDelete => 'Delete';

  @override
  String get historyDeleted => 'Deleted from history.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionBehavior => 'Behavior';

  @override
  String get settingsAutoDownload => 'Auto-download after Share';

  @override
  String get settingsAutoDownloadSubtitle =>
      'Start download immediately when a link comes from Instagram.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Show a notification when download completes.';

  @override
  String get settingsSaveHistory => 'Save history';

  @override
  String get settingsSaveHistorySubtitle =>
      'Add downloaded videos to the history list.';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionBackend => 'Backend';

  @override
  String get settingsBackendUrlLabel => 'Backend URL';

  @override
  String get settingsBackendUrlHint => 'http://10.0.2.2:3000';

  @override
  String get settingsBackendSave => 'Save';

  @override
  String get settingsBackendSaved => 'Saved.';

  @override
  String get settingsBackendTest => 'Test connection';

  @override
  String get settingsBackendOnline => 'Backend is online.';

  @override
  String get settingsBackendOffline =>
      'Cannot reach backend. Check URL and network.';

  @override
  String get settingsBackendNote =>
      'For emulator use http://10.0.2.2:3000.\nFor real device use http://YOUR-IP:3000.';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsClearHistory => 'Clear history';

  @override
  String get settingsClearHistorySubtitle =>
      'Delete all records. Files remain.';

  @override
  String get settingsCleared => 'History cleared.';

  @override
  String get settingsWatchClipboard => 'Watch clipboard';

  @override
  String get settingsWatchClipboardSubtitle =>
      'Suggest Instagram links when you copy them.';

  @override
  String get settingsSaveInAuthorFolder => 'Save in author folder';

  @override
  String get settingsSaveInAuthorFolderSubtitle =>
      'Create a subfolder per @author inside QuickSave.';

  @override
  String get settingsSaveToGallery => 'Save to Gallery';

  @override
  String get settingsSaveToGallerySubtitle =>
      'Copy downloads to Pictures/Movies so Gallery apps can see them.';

  @override
  String get settingsBackendModeHosted => 'QuickSave Cloud (recommended)';

  @override
  String get settingsBackendModeSelf => 'Self-hosted server';

  @override
  String get settingsSectionPro => 'QuickSave Pro';

  @override
  String get settingsProActive => 'Pro active';

  @override
  String get settingsProInactive => 'Unlock scheduler, ZIP export, self-hosted';

  @override
  String get settingsProLicenseHint => 'License key QS-PRO-XXXX';

  @override
  String get settingsProActivate => 'Activate';

  @override
  String get settingsProActivated => 'Pro activated!';

  @override
  String get settingsProInvalidKey => 'Invalid license key';

  @override
  String get settingsSchedulerTitle => 'Profile scheduler';

  @override
  String get settingsSchedulerSubtitle =>
      'Check @profiles daily for new public posts (Pro)';

  @override
  String get settingsSchedulerAddHint => '@username';

  @override
  String get settingsExportZip => 'Export batch as ZIP';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get onboardingTitle => 'Get started';

  @override
  String get onboardingShareTitle => 'Share from Instagram';

  @override
  String get onboardingShareBody =>
      'Open a public post → Share → QuickSave. With auto-download on, files save in the background.';

  @override
  String get onboardingTileTitle => 'Quick Settings tile';

  @override
  String get onboardingTileBody =>
      'Add the QuickSave tile in the notification shade for one-tap paste from clipboard.';

  @override
  String get onboardingGalleryTitle => 'Gallery saving';

  @override
  String get onboardingGalleryBody =>
      'Turn on Save to Gallery in Settings so photos and videos appear in your Gallery app.';

  @override
  String get onboardingGotIt => 'Got it';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyIntro => 'QuickSave respects your privacy.';

  @override
  String get privacyBody =>
      'QuickSave does not require an Instagram account. We only process URLs you explicitly share or paste. Downloaded media is stored on your device. When using QuickSave Cloud, your URL is sent to our resolver to obtain public media links — we do not store your downloads on our servers. Self-hosted mode sends URLs only to your own server. Contact: support@quicksave.app';

  @override
  String get historyCopyCaption => 'Copy caption';

  @override
  String get historyCaptionCopied => 'Caption copied';

  @override
  String get historyPostDate => 'Post date';

  @override
  String get historyExportZip => 'Export ZIP';

  @override
  String get historyFailedBadge => 'Failed';

  @override
  String get historyRetryDownload => 'Retry download';

  @override
  String get historyRetryStarted => 'Retry started…';

  @override
  String get historyRetryFailed => 'Retry failed';

  @override
  String get historyAddToCollection => 'Add to collection';

  @override
  String get historyCreateCollection => 'New collection';

  @override
  String get historyCollectionNameHint => 'Collection name';

  @override
  String get historyCollectionCreated => 'Collection created';

  @override
  String get historyAddedToCollection => 'Added to collection';

  @override
  String get historyCollectionAll => 'All collections';

  @override
  String get queuePanelTitle => 'Download queue';

  @override
  String get queueStatusQueued => 'Queued';

  @override
  String get queueStatusRunning => 'Downloading';

  @override
  String get queueStatusPaused => 'Paused';

  @override
  String get queueStatusFailed => 'Failed';

  @override
  String get queueStatusCompleted => 'Done';

  @override
  String get queueStatusCancelled => 'Cancelled';

  @override
  String get queuePause => 'Pause';

  @override
  String get queueResume => 'Resume';

  @override
  String get queueCancel => 'Cancel';

  @override
  String get queueRetry => 'Retry';

  @override
  String get semHomeDownload => 'Download from URL';

  @override
  String get semHomeHistory => 'Open download history';

  @override
  String get semHomeSettings => 'Open settings';

  @override
  String get semHistorySearch => 'Search library';

  @override
  String get semPreviewDownload => 'Download media';

  @override
  String get semPreviewCancel => 'Cancel preview';

  @override
  String get semPreviewStop => 'Stop download';

  @override
  String get semSettingsProActivate => 'Activate Pro license';

  @override
  String get semSettingsSchedulerAdd => 'Add scheduled profile';

  @override
  String get notificationDownloadCompleteTitle => 'Media saved';

  @override
  String get notificationChannelDownloads => 'Downloads';

  @override
  String get notificationChannelDownloadsDesc =>
      'Download completion notifications';

  @override
  String notificationDownloadCompleteBody(String author) {
    return 'Author: $author';
  }

  @override
  String get notificationDownloadCompleteBodyFallback =>
      'File saved in QuickSave';

  @override
  String get notificationDownloadErrorTitle => 'Download error';

  @override
  String get notificationDownloadAuthorPrefix => 'Author';

  @override
  String get shareText => 'Video from QuickSave';
}
