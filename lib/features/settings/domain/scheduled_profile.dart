/// Профиль для фонового планировщика (публичные посты).
class ScheduledProfile {
  final String username;
  final String profileUrl;
  final DateTime? lastCheckedAt;
  final bool enabled;

  const ScheduledProfile({
    required this.username,
    required this.profileUrl,
    this.lastCheckedAt,
    this.enabled = true,
  });

  ScheduledProfile copyWith({
    String? username,
    String? profileUrl,
    DateTime? lastCheckedAt,
    bool? enabled,
  }) =>
      ScheduledProfile(
        username: username ?? this.username,
        profileUrl: profileUrl ?? this.profileUrl,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'profileUrl': profileUrl,
        if (lastCheckedAt != null)
          'lastCheckedAt': lastCheckedAt!.toIso8601String(),
        'enabled': enabled,
      };

  factory ScheduledProfile.fromJson(Map<String, dynamic> json) =>
      ScheduledProfile(
        username: json['username'] as String? ?? '',
        profileUrl: json['profileUrl'] as String? ?? '',
        lastCheckedAt: json['lastCheckedAt'] != null
            ? DateTime.tryParse(json['lastCheckedAt'] as String)
            : null,
        enabled: json['enabled'] as bool? ?? true,
      );
}
