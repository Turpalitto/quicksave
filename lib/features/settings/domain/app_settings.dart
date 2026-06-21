import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
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
  });

  /// URL resolver для текущего режима.
  String get effectiveBackendUrl => backendMode == BackendMode.selfHosted
      ? backendUrl
      : AppConstants.hostedBackendUrl;

  bool get canUseScheduler => isPro;
  bool get canExportZip => isPro;
  bool get canSelfHost => isPro;

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
  }) =>
      AppSettings(
        autoDownload: autoDownload ?? this.autoDownload,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
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
        'scheduledProfiles':
            scheduledProfiles.map((p) => p.toJson()).toList(),
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
      backendUrl: json['backendUrl'] as String? ??
          AppConstants.defaultSelfHostedBackendUrl,
      scheduledProfiles: rawProfiles is List
          ? rawProfiles
              .whereType<Map<String, dynamic>>()
              .map(ScheduledProfile.fromJson)
              .where((p) => p.username.isNotEmpty)
              .toList()
          : const [],
    );
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
