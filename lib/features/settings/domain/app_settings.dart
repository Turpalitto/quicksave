import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/filename_template_engine.dart';
import 'cloud_backup_config.dart';
import 'scheduled_profile.dart';

enum AppThemeMode { system, light, dark }

enum BackendMode { hosted, selfHosted }

/// Настройки приложения.
class AppSettings {
  final bool autoDownload;
  final bool notificationsEnabled;
  final bool saveHistory;
  final bool watchClipboard;
  final bool saveInAuthorFolder;
  final bool saveToGallery;
  final bool onboardingCompleted;
  final bool isPro;
  final BackendMode backendMode;
  final AppThemeMode themeMode;
  final String backendUrl;
  final List<ScheduledProfile> scheduledProfiles;
  final FilenameTemplatePreset filenameTemplatePreset;
  final String customFilenameTemplate;
  final CloudBackupConfig cloudBackup;

  const AppSettings({
    this.autoDownload = true,
    this.notificationsEnabled = true,
    this.saveHistory = true,
    this.watchClipboard = true,
    this.saveInAuthorFolder = false,
    this.saveToGallery = true,
    this.onboardingCompleted = false,
    this.isPro = false,
    this.backendMode = BackendMode.hosted,
    this.themeMode = AppThemeMode.system,
    this.backendUrl = AppConstants.defaultSelfHostedBackendUrl,
    this.scheduledProfiles = const [],
    this.filenameTemplatePreset = FilenameTemplatePreset.defaultTemplate,
    this.customFilenameTemplate = '',
    this.cloudBackup = const CloudBackupConfig(),
  });

  /// URL resolver для текущего режима.
  String get effectiveBackendUrl => backendMode == BackendMode.selfHosted
      ? backendUrl
      : AppConstants.hostedBackendUrl;

  bool get canUseScheduler => isPro;
  bool get canExportZip => isPro;
  bool get canSelfHost => true;
  bool get canUseFilenameTemplates => isPro;
  bool get canBulkActions => isPro;
  bool get canCloudBackup => isPro;

  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  AppSettings copyWith({
    bool? autoDownload,
    bool? notificationsEnabled,
    bool? saveHistory,
    bool? watchClipboard,
    bool? saveInAuthorFolder,
    bool? saveToGallery,
    bool? onboardingCompleted,
    bool? isPro,
    BackendMode? backendMode,
    AppThemeMode? themeMode,
    String? backendUrl,
    List<ScheduledProfile>? scheduledProfiles,
    FilenameTemplatePreset? filenameTemplatePreset,
    String? customFilenameTemplate,
    CloudBackupConfig? cloudBackup,
  }) => AppSettings(
    autoDownload: autoDownload ?? this.autoDownload,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    saveHistory: saveHistory ?? this.saveHistory,
    watchClipboard: watchClipboard ?? this.watchClipboard,
    saveInAuthorFolder: saveInAuthorFolder ?? this.saveInAuthorFolder,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    isPro: isPro ?? this.isPro,
    backendMode: backendMode ?? this.backendMode,
    themeMode: themeMode ?? this.themeMode,
    backendUrl: backendUrl ?? this.backendUrl,
    scheduledProfiles: scheduledProfiles ?? this.scheduledProfiles,
    filenameTemplatePreset:
        filenameTemplatePreset ?? this.filenameTemplatePreset,
    customFilenameTemplate:
        customFilenameTemplate ?? this.customFilenameTemplate,
    cloudBackup: cloudBackup ?? this.cloudBackup,
  );

  Map<String, dynamic> toJson() => {
    'autoDownload': autoDownload,
    'notificationsEnabled': notificationsEnabled,
    'saveHistory': saveHistory,
    'watchClipboard': watchClipboard,
    'saveInAuthorFolder': saveInAuthorFolder,
    'saveToGallery': saveToGallery,
    'onboardingCompleted': onboardingCompleted,
    'isPro': isPro,
    'backendMode': backendMode.name,
    'themeMode': themeMode.name,
    'backendUrl': backendUrl,
    'scheduledProfiles': scheduledProfiles.map((p) => p.toJson()).toList(),
    'filenameTemplatePreset': filenameTemplatePreset.name,
    if (customFilenameTemplate.isNotEmpty)
      'customFilenameTemplate': customFilenameTemplate,
    if (cloudBackup.enabled || cloudBackup.provider != CloudBackupProvider.none)
      'cloudBackup': cloudBackup.toJson(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final themeStr = json['themeMode'] as String?;
    final backendStr = json['backendMode'] as String?;
    final rawProfiles = json['scheduledProfiles'];
    return AppSettings(
      autoDownload: json['autoDownload'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      saveHistory: json['saveHistory'] as bool? ?? true,
      watchClipboard: json['watchClipboard'] as bool? ?? true,
      saveInAuthorFolder: json['saveInAuthorFolder'] as bool? ?? false,
      saveToGallery: json['saveToGallery'] as bool? ?? true,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      backendMode: backendStr == 'selfHosted'
          ? BackendMode.selfHosted
          : BackendMode.hosted,
      themeMode: _parseTheme(themeStr),
      backendUrl:
          json['backendUrl'] as String? ??
          AppConstants.defaultSelfHostedBackendUrl,
      scheduledProfiles: rawProfiles is List
          ? rawProfiles
                .whereType<Map<String, dynamic>>()
                .map(ScheduledProfile.fromJson)
                .where((p) => p.username.isNotEmpty)
                .toList()
          : const [],
      filenameTemplatePreset: _parseFilenamePreset(
        json['filenameTemplatePreset'] as String?,
      ),
      customFilenameTemplate: json['customFilenameTemplate'] as String? ?? '',
      cloudBackup: CloudBackupConfig.fromJson(
        json['cloudBackup'] as Map<String, dynamic>?,
      ),
    );
  }

  static FilenameTemplatePreset _parseFilenamePreset(String? raw) {
    switch (raw) {
      case 'dateFirst':
        return FilenameTemplatePreset.dateFirst;
      case 'folderStyle':
        return FilenameTemplatePreset.folderStyle;
      case 'custom':
        return FilenameTemplatePreset.custom;
      default:
        return FilenameTemplatePreset.defaultTemplate;
    }
  }

  static AppThemeMode _parseTheme(String? v) {
    switch (v) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
}
