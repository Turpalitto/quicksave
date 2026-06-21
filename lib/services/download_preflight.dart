/// Preflight metadata before starting a download.
class DownloadPreflight {
  const DownloadPreflight({
    required this.contentType,
    required this.estimatedBytes,
    required this.targetFileName,
    required this.acceptable,
    this.rejectionReason,
  });

  final String? contentType;
  final int? estimatedBytes;
  final String targetFileName;
  final bool acceptable;
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
    'contentType': contentType,
    'estimatedBytes': estimatedBytes,
    'targetFileName': targetFileName,
    'acceptable': acceptable,
    'rejectionReason': rejectionReason,
  };

  factory DownloadPreflight.fromJson(Map<String, dynamic> json) =>
      DownloadPreflight(
        contentType: json['contentType'] as String?,
        estimatedBytes: (json['estimatedBytes'] as num?)?.toInt(),
        targetFileName: json['targetFileName'] as String? ?? 'download.bin',
        acceptable: json['acceptable'] as bool? ?? true,
        rejectionReason: json['rejectionReason'] as String?,
      );
}
