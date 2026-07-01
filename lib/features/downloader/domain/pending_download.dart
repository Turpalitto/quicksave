/// Запись очереди «скачать позже» при временных сбоях resolve.
class PendingDownload {
  final String id;
  final String sourceUrl;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attempts;
  final String? lastError;

  const PendingDownload({
    required this.id,
    required this.sourceUrl,
    required this.createdAt,
    this.lastAttemptAt,
    this.attempts = 0,
    this.lastError,
  });

  PendingDownload copyWith({
    DateTime? lastAttemptAt,
    int? attempts,
    String? lastError,
  }) => PendingDownload(
    id: id,
    sourceUrl: sourceUrl,
    createdAt: createdAt,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceUrl': sourceUrl,
    'createdAt': createdAt.toIso8601String(),
    if (lastAttemptAt != null) 'lastAttemptAt': lastAttemptAt!.toIso8601String(),
    'attempts': attempts,
    if (lastError != null) 'lastError': lastError,
  };

  factory PendingDownload.fromJson(Map<String, dynamic> json) => PendingDownload(
    id: json['id'] as String,
    sourceUrl: json['sourceUrl'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAttemptAt: json['lastAttemptAt'] != null
        ? DateTime.tryParse(json['lastAttemptAt'] as String)
        : null,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    lastError: json['lastError'] as String?,
  );
}
