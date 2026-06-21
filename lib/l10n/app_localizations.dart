import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuickSave'**
  String get appTitle;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Instagram media'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a link from Instagram to QuickSave'**
  String get homeHeroSubtitle;

  /// No description provided for @urlFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Post, reel, story or @profile'**
  String get urlFieldHint;

  /// No description provided for @urlFieldPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get urlFieldPaste;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @homeTip.
  ///
  /// In en, this message translates to:
  /// **'Share from Instagram, paste a link, or enter @username to browse a profile grid.'**
  String get homeTip;

  /// No description provided for @homeClipboardDetected.
  ///
  /// In en, this message translates to:
  /// **'Instagram link detected in clipboard'**
  String get homeClipboardDetected;

  /// No description provided for @homeFooter.
  ///
  /// In en, this message translates to:
  /// **'Only public posts • v{version}'**
  String homeFooter(String version);

  /// No description provided for @errorEnterUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a link.'**
  String get errorEnterUrl;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'The link must point to a public Instagram post, story, highlight, or profile.'**
  String get errorInvalidUrl;

  /// No description provided for @errorNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Could not recognize the Instagram link.'**
  String get errorNotRecognized;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @previewResolving.
  ///
  /// In en, this message translates to:
  /// **'Fetching video info…'**
  String get previewResolving;

  /// No description provided for @previewSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String previewSource(String source);

  /// No description provided for @previewDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get previewDownload;

  /// No description provided for @previewCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get previewCancel;

  /// No description provided for @previewDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}'**
  String previewDownloading(String percent);

  /// No description provided for @previewStop.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get previewStop;

  /// No description provided for @previewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get previewSuccess;

  /// No description provided for @previewSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to QuickSave'**
  String get previewSavedTo;

  /// No description provided for @previewOpen.
  ///
  /// In en, this message translates to:
  /// **'Open video'**
  String get previewOpen;

  /// No description provided for @previewShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get previewShare;

  /// No description provided for @previewDownloadSelected.
  ///
  /// In en, this message translates to:
  /// **'Download selected ({count})'**
  String previewDownloadSelected(int count);

  /// No description provided for @previewTypeCarousel.
  ///
  /// In en, this message translates to:
  /// **'Carousel · {count} items'**
  String previewTypeCarousel(int count);

  /// No description provided for @previewTypeStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get previewTypeStory;

  /// No description provided for @previewTypeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlights · {count}'**
  String previewTypeHighlight(int count);

  /// No description provided for @previewTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single post'**
  String get previewTypeSingle;

  /// No description provided for @previewSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get previewSelectAll;

  /// No description provided for @previewDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get previewDeselectAll;

  /// No description provided for @previewVideosOnly.
  ///
  /// In en, this message translates to:
  /// **'Videos only'**
  String get previewVideosOnly;

  /// No description provided for @previewBatchProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {current} of {total}…'**
  String previewBatchProgress(int current, int total);

  /// No description provided for @previewBatchSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} files'**
  String previewBatchSaved(String count);

  /// No description provided for @previewBatchSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files saved to QuickSave'**
  String previewBatchSavedCount(int count);

  /// No description provided for @previewPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved {saved} of {total} files ({failed} failed)'**
  String previewPartialSuccess(int saved, int total, int failed);

  /// No description provided for @previewTypeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile · {count} posts'**
  String previewTypeProfile(int count);

  /// No description provided for @previewShareAll.
  ///
  /// In en, this message translates to:
  /// **'Share all'**
  String get previewShareAll;

  /// No description provided for @previewGoHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get previewGoHome;

  /// No description provided for @previewLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more posts'**
  String get previewLoadMore;

  /// No description provided for @previewTapToPreview.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview'**
  String get previewTapToPreview;

  /// No description provided for @previewQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose quality'**
  String get previewQualityTitle;

  /// No description provided for @recentLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent links'**
  String get recentLinksTitle;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get errorNoInternet;

  /// No description provided for @errorPrivatePost.
  ///
  /// In en, this message translates to:
  /// **'Post is private or requires Instagram login.'**
  String get errorPrivatePost;

  /// No description provided for @errorNotFoundPost.
  ///
  /// In en, this message translates to:
  /// **'Post not found. Check the link.'**
  String get errorNotFoundPost;

  /// No description provided for @errorResolverFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get a direct link. Try another public post.'**
  String get errorResolverFailed;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Try again later.'**
  String get errorServer;

  /// No description provided for @errorNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on device.'**
  String get errorNoSpace;

  /// No description provided for @errorFileWrite.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file.'**
  String get errorFileWrite;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error.'**
  String get errorUnknown;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @errorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open: {message}'**
  String errorOpenFailed(String message);

  /// No description provided for @errorFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File not found.'**
  String get errorFileMissing;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'History is empty'**
  String get historyEmpty;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded media will appear here.'**
  String get historyEmptySubtitle;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by author or URL'**
  String get historySearchHint;

  /// No description provided for @historySearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results for your search.'**
  String get historySearchEmpty;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get historyFilterVideo;

  /// No description provided for @historyFilterImage.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get historyFilterImage;

  /// No description provided for @historyFilterStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get historyFilterStories;

  /// No description provided for @historyFilterProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get historyFilterProfiles;

  /// No description provided for @historyDeleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get historyDeleteFileTitle;

  /// No description provided for @historyDeleteFileBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the file from device storage and history.'**
  String get historyDeleteFileBody;

  /// No description provided for @historyDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get historyDeleteFileConfirm;

  /// No description provided for @historyDeleteRecordBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this entry from history?'**
  String get historyDeleteRecordBody;

  /// No description provided for @historyBatchFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String historyBatchFiles(int count);

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get historyClearConfirmTitle;

  /// No description provided for @historyClearConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All records will be deleted. Files will remain.'**
  String get historyClearConfirmBody;

  /// No description provided for @historyClearConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClearConfirmYes;

  /// No description provided for @historyClearConfirmNo.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get historyClearConfirmNo;

  /// No description provided for @historyFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'file unavailable'**
  String get historyFileUnavailable;

  /// No description provided for @historyActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get historyActionOpen;

  /// No description provided for @historyActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get historyActionShare;

  /// No description provided for @historyActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyActionDelete;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted from history.'**
  String get historyDeleted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get settingsSectionBehavior;

  /// No description provided for @settingsAutoDownload.
  ///
  /// In en, this message translates to:
  /// **'Auto-download after Share'**
  String get settingsAutoDownload;

  /// No description provided for @settingsAutoDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start download immediately when a link comes from Instagram.'**
  String get settingsAutoDownloadSubtitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a notification when download completes.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsSaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Save history'**
  String get settingsSaveHistory;

  /// No description provided for @settingsSaveHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add downloaded videos to the history list.'**
  String get settingsSaveHistorySubtitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsSectionBackend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get settingsSectionBackend;

  /// No description provided for @settingsBackendUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Backend URL'**
  String get settingsBackendUrlLabel;

  /// No description provided for @settingsBackendUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://10.0.2.2:3000'**
  String get settingsBackendUrlHint;

  /// No description provided for @settingsBackendSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsBackendSave;

  /// No description provided for @settingsBackendSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get settingsBackendSaved;

  /// No description provided for @settingsBackendTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsBackendTest;

  /// No description provided for @settingsBackendOnline.
  ///
  /// In en, this message translates to:
  /// **'Backend is online.'**
  String get settingsBackendOnline;

  /// No description provided for @settingsBackendOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach backend. Check URL and network.'**
  String get settingsBackendOffline;

  /// No description provided for @settingsBackendNote.
  ///
  /// In en, this message translates to:
  /// **'For emulator use http://10.0.2.2:3000.\nFor real device use http://YOUR-IP:3000.'**
  String get settingsBackendNote;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all records. Files remain.'**
  String get settingsClearHistorySubtitle;

  /// No description provided for @settingsCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get settingsCleared;

  /// No description provided for @settingsWatchClipboard.
  ///
  /// In en, this message translates to:
  /// **'Watch clipboard'**
  String get settingsWatchClipboard;

  /// No description provided for @settingsWatchClipboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest Instagram links when you copy them.'**
  String get settingsWatchClipboardSubtitle;

  /// No description provided for @settingsSaveInAuthorFolder.
  ///
  /// In en, this message translates to:
  /// **'Save in author folder'**
  String get settingsSaveInAuthorFolder;

  /// No description provided for @settingsSaveInAuthorFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a subfolder per @author inside QuickSave.'**
  String get settingsSaveInAuthorFolderSubtitle;

  /// No description provided for @settingsSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get settingsSaveToGallery;

  /// No description provided for @settingsSaveToGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy downloads to Pictures/Movies so Gallery apps can see them.'**
  String get settingsSaveToGallerySubtitle;

  /// No description provided for @settingsBackendModeHosted.
  ///
  /// In en, this message translates to:
  /// **'QuickSave Cloud (recommended)'**
  String get settingsBackendModeHosted;

  /// No description provided for @settingsBackendModeSelf.
  ///
  /// In en, this message translates to:
  /// **'Self-hosted server'**
  String get settingsBackendModeSelf;

  /// No description provided for @settingsSectionPro.
  ///
  /// In en, this message translates to:
  /// **'QuickSave Pro'**
  String get settingsSectionPro;

  /// No description provided for @settingsProActive.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get settingsProActive;

  /// No description provided for @settingsProInactive.
  ///
  /// In en, this message translates to:
  /// **'Unlock scheduler, ZIP export, self-hosted'**
  String get settingsProInactive;

  /// No description provided for @settingsProLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'License key QS-PRO-XXXX'**
  String get settingsProLicenseHint;

  /// No description provided for @settingsProActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get settingsProActivate;

  /// No description provided for @settingsProActivated.
  ///
  /// In en, this message translates to:
  /// **'Pro activated!'**
  String get settingsProActivated;

  /// No description provided for @settingsProInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid license key'**
  String get settingsProInvalidKey;

  /// No description provided for @settingsSchedulerTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile scheduler'**
  String get settingsSchedulerTitle;

  /// No description provided for @settingsSchedulerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check @profiles daily for new public posts (Pro)'**
  String get settingsSchedulerSubtitle;

  /// No description provided for @settingsSchedulerAddHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get settingsSchedulerAddHint;

  /// No description provided for @settingsExportZip.
  ///
  /// In en, this message translates to:
  /// **'Export batch as ZIP'**
  String get settingsExportZip;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingTitle;

  /// No description provided for @onboardingShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share from Instagram'**
  String get onboardingShareTitle;

  /// No description provided for @onboardingShareBody.
  ///
  /// In en, this message translates to:
  /// **'Open a public post → Share → QuickSave. With auto-download on, files save in the background.'**
  String get onboardingShareBody;

  /// No description provided for @onboardingTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tile'**
  String get onboardingTileTitle;

  /// No description provided for @onboardingTileBody.
  ///
  /// In en, this message translates to:
  /// **'Add the QuickSave tile in the notification shade for one-tap paste from clipboard.'**
  String get onboardingTileBody;

  /// No description provided for @onboardingGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery saving'**
  String get onboardingGalleryTitle;

  /// No description provided for @onboardingGalleryBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Save to Gallery in Settings so photos and videos appear in your Gallery app.'**
  String get onboardingGalleryBody;

  /// No description provided for @onboardingGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get onboardingGotIt;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'QuickSave respects your privacy.'**
  String get privacyIntro;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'QuickSave does not require an Instagram account. We only process URLs you explicitly share or paste. Downloaded media is stored on your device. When using QuickSave Cloud, your URL is sent to our resolver to obtain public media links — we do not store your downloads on our servers. Self-hosted mode sends URLs only to your own server. Contact: support@quicksave.app'**
  String get privacyBody;

  /// No description provided for @historyCopyCaption.
  ///
  /// In en, this message translates to:
  /// **'Copy caption'**
  String get historyCopyCaption;

  /// No description provided for @historyCaptionCopied.
  ///
  /// In en, this message translates to:
  /// **'Caption copied'**
  String get historyCaptionCopied;

  /// No description provided for @historyPostDate.
  ///
  /// In en, this message translates to:
  /// **'Post date'**
  String get historyPostDate;

  /// No description provided for @historyExportZip.
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get historyExportZip;

  /// No description provided for @historyFailedBadge.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get historyFailedBadge;

  /// No description provided for @historyRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get historyRetryDownload;

  /// No description provided for @historyRetryStarted.
  ///
  /// In en, this message translates to:
  /// **'Retry started…'**
  String get historyRetryStarted;

  /// No description provided for @historyRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed'**
  String get historyRetryFailed;

  /// No description provided for @historyAddToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get historyAddToCollection;

  /// No description provided for @historyCreateCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get historyCreateCollection;

  /// No description provided for @historyCollectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get historyCollectionNameHint;

  /// No description provided for @historyCollectionCreated.
  ///
  /// In en, this message translates to:
  /// **'Collection created'**
  String get historyCollectionCreated;

  /// No description provided for @historyAddedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Added to collection'**
  String get historyAddedToCollection;

  /// No description provided for @historyCollectionAll.
  ///
  /// In en, this message translates to:
  /// **'All collections'**
  String get historyCollectionAll;

  /// No description provided for @queuePanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Download queue'**
  String get queuePanelTitle;

  /// No description provided for @queueStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queueStatusQueued;

  /// No description provided for @queueStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get queueStatusRunning;

  /// No description provided for @queueStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get queueStatusPaused;

  /// No description provided for @queueStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get queueStatusFailed;

  /// No description provided for @queueStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get queueStatusCompleted;

  /// No description provided for @queueStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get queueStatusCancelled;

  /// No description provided for @queuePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get queuePause;

  /// No description provided for @queueResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get queueResume;

  /// No description provided for @queueCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get queueCancel;

  /// No description provided for @queueRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get queueRetry;

  /// No description provided for @semHomeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download from URL'**
  String get semHomeDownload;

  /// No description provided for @semHomeHistory.
  ///
  /// In en, this message translates to:
  /// **'Open download history'**
  String get semHomeHistory;

  /// No description provided for @semHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get semHomeSettings;

  /// No description provided for @semHistorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search library'**
  String get semHistorySearch;

  /// No description provided for @semPreviewDownload.
  ///
  /// In en, this message translates to:
  /// **'Download media'**
  String get semPreviewDownload;

  /// No description provided for @semPreviewCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel preview'**
  String get semPreviewCancel;

  /// No description provided for @semPreviewStop.
  ///
  /// In en, this message translates to:
  /// **'Stop download'**
  String get semPreviewStop;

  /// No description provided for @semSettingsProActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Pro license'**
  String get semSettingsProActivate;

  /// No description provided for @semSettingsSchedulerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add scheduled profile'**
  String get semSettingsSchedulerAdd;

  /// No description provided for @notificationDownloadCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Media saved'**
  String get notificationDownloadCompleteTitle;

  /// No description provided for @notificationChannelDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get notificationChannelDownloads;

  /// No description provided for @notificationChannelDownloadsDesc.
  ///
  /// In en, this message translates to:
  /// **'Download completion notifications'**
  String get notificationChannelDownloadsDesc;

  /// No description provided for @notificationDownloadCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Author: {author}'**
  String notificationDownloadCompleteBody(String author);

  /// No description provided for @notificationDownloadCompleteBodyFallback.
  ///
  /// In en, this message translates to:
  /// **'File saved in QuickSave'**
  String get notificationDownloadCompleteBodyFallback;

  /// No description provided for @notificationDownloadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Download error'**
  String get notificationDownloadErrorTitle;

  /// No description provided for @notificationDownloadAuthorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get notificationDownloadAuthorPrefix;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Video from QuickSave'**
  String get shareText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
