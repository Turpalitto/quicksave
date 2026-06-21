import 'scheduler_frequency.dart';

/// Профиль для watchlist / планировщика (только публичный контент).
class ScheduledProfile {
  final String username;
  final String profileUrl;
  final DateTime? lastCheckedAt;
  final DateTime? lastSuccessAt;
  final DateTime? nextRunAt;
  final String? lastError;
  final int newItemsFound;
  final int totalSaved;
  final bool enabled;
  final bool autoSaveNewPosts;
  final SchedulerFrequency frequency;
  final bool wifiOnly;
  final bool chargingOnly;

  const ScheduledProfile({
    required this.username,
    required this.profileUrl,
    this.lastCheckedAt,
    this.lastSuccessAt,
    this.nextRunAt,
    this.lastError,
    this.newItemsFound = 0,
    this.totalSaved = 0,
    this.enabled = true,
    this.autoSaveNewPosts = false,
    this.frequency = SchedulerFrequency.manual,
    this.wifiOnly = false,
    this.chargingOnly = false,
  });

  ScheduledProfile copyWith({
    String? username,
    String? profileUrl,
    DateTime? lastCheckedAt,
    DateTime? lastSuccessAt,
    DateTime? nextRunAt,
    String? lastError,
    int? newItemsFound,
    int? totalSaved,
    bool? enabled,
    bool? autoSaveNewPosts,
    SchedulerFrequency? frequency,
    bool? wifiOnly,
    bool? chargingOnly,
  }) => ScheduledProfile(
    username: username ?? this.username,
    profileUrl: profileUrl ?? this.profileUrl,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    nextRunAt: nextRunAt ?? this.nextRunAt,
    lastError: lastError ?? this.lastError,
    newItemsFound: newItemsFound ?? this.newItemsFound,
    totalSaved: totalSaved ?? this.totalSaved,
    enabled: enabled ?? this.enabled,
    autoSaveNewPosts: autoSaveNewPosts ?? this.autoSaveNewPosts,
    frequency: frequency ?? this.frequency,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    chargingOnly: chargingOnly ?? this.chargingOnly,
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'profileUrl': profileUrl,
    if (lastCheckedAt != null)
      'lastCheckedAt': lastCheckedAt!.toIso8601String(),
    if (lastSuccessAt != null)
      'lastSuccessAt': lastSuccessAt!.toIso8601String(),
    if (nextRunAt != null) 'nextRunAt': nextRunAt!.toIso8601String(),
    if (lastError != null) 'lastError': lastError,
    'newItemsFound': newItemsFound,
    'totalSaved': totalSaved,
    'enabled': enabled,
    'autoSaveNewPosts': autoSaveNewPosts,
    'frequency': frequency.storageValue,
    'wifiOnly': wifiOnly,
    'chargingOnly': chargingOnly,
  };

  factory ScheduledProfile.fromJson(Map<String, dynamic> json) =>
      ScheduledProfile(
        username: json['username'] as String? ?? '',
        profileUrl: json['profileUrl'] as String? ?? '',
        lastCheckedAt: json['lastCheckedAt'] != null
            ? DateTime.tryParse(json['lastCheckedAt'] as String)
            : null,
        lastSuccessAt: json['lastSuccessAt'] != null
            ? DateTime.tryParse(json['lastSuccessAt'] as String)
            : null,
        nextRunAt: json['nextRunAt'] != null
            ? DateTime.tryParse(json['nextRunAt'] as String)
            : null,
        lastError: json['lastError'] as String?,
        newItemsFound: (json['newItemsFound'] as num?)?.toInt() ?? 0,
        totalSaved: (json['totalSaved'] as num?)?.toInt() ?? 0,
        enabled: json['enabled'] as bool? ?? true,
        autoSaveNewPosts: json['autoSaveNewPosts'] as bool? ?? false,
        frequency: SchedulerFrequency.fromString(json['frequency'] as String?),
        wifiOnly: json['wifiOnly'] as bool? ?? false,
        chargingOnly: json['chargingOnly'] as bool? ?? false,
      );
}
