/// Cloud backup destination for Pro exports.
enum CloudBackupProvider { none, webdav, s3, googleDrive }

/// User-configured cloud backup settings (stored locally, Pro-gated).
class CloudBackupConfig {
  final bool enabled;
  final CloudBackupProvider provider;
  final String webDavUrl;
  final String webDavUsername;
  final String webDavPassword;
  final String webDavBasePath;
  final String s3Endpoint;
  final String s3Bucket;
  final String s3AccessKey;
  final String s3SecretKey;
  final String s3Prefix;
  final String s3Region;

  const CloudBackupConfig({
    this.enabled = false,
    this.provider = CloudBackupProvider.none,
    this.webDavUrl = '',
    this.webDavUsername = '',
    this.webDavPassword = '',
    this.webDavBasePath = 'QuickSave',
    this.s3Endpoint = '',
    this.s3Bucket = '',
    this.s3AccessKey = '',
    this.s3SecretKey = '',
    this.s3Prefix = 'quicksave',
    this.s3Region = 'us-east-1',
  });

  bool get isConfigured {
    switch (provider) {
      case CloudBackupProvider.none:
        return false;
      case CloudBackupProvider.webdav:
        return webDavUrl.trim().isNotEmpty;
      case CloudBackupProvider.s3:
        return s3Endpoint.trim().isNotEmpty &&
            s3Bucket.trim().isNotEmpty &&
            s3AccessKey.isNotEmpty &&
            s3SecretKey.isNotEmpty;
      case CloudBackupProvider.googleDrive:
        return false;
    }
  }

  CloudBackupConfig copyWith({
    bool? enabled,
    CloudBackupProvider? provider,
    String? webDavUrl,
    String? webDavUsername,
    String? webDavPassword,
    String? webDavBasePath,
    String? s3Endpoint,
    String? s3Bucket,
    String? s3AccessKey,
    String? s3SecretKey,
    String? s3Prefix,
    String? s3Region,
  }) => CloudBackupConfig(
    enabled: enabled ?? this.enabled,
    provider: provider ?? this.provider,
    webDavUrl: webDavUrl ?? this.webDavUrl,
    webDavUsername: webDavUsername ?? this.webDavUsername,
    webDavPassword: webDavPassword ?? this.webDavPassword,
    webDavBasePath: webDavBasePath ?? this.webDavBasePath,
    s3Endpoint: s3Endpoint ?? this.s3Endpoint,
    s3Bucket: s3Bucket ?? this.s3Bucket,
    s3AccessKey: s3AccessKey ?? this.s3AccessKey,
    s3SecretKey: s3SecretKey ?? this.s3SecretKey,
    s3Prefix: s3Prefix ?? this.s3Prefix,
    s3Region: s3Region ?? this.s3Region,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'provider': provider.name,
    if (webDavUrl.isNotEmpty) 'webDavUrl': webDavUrl,
    if (webDavUsername.isNotEmpty) 'webDavUsername': webDavUsername,
    if (webDavPassword.isNotEmpty) 'webDavPassword': webDavPassword,
    if (webDavBasePath.isNotEmpty) 'webDavBasePath': webDavBasePath,
    if (s3Endpoint.isNotEmpty) 's3Endpoint': s3Endpoint,
    if (s3Bucket.isNotEmpty) 's3Bucket': s3Bucket,
    if (s3AccessKey.isNotEmpty) 's3AccessKey': s3AccessKey,
    if (s3SecretKey.isNotEmpty) 's3SecretKey': s3SecretKey,
    if (s3Prefix.isNotEmpty) 's3Prefix': s3Prefix,
    if (s3Region.isNotEmpty) 's3Region': s3Region,
  };

  factory CloudBackupConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const CloudBackupConfig();
    return CloudBackupConfig(
      enabled: json['enabled'] as bool? ?? false,
      provider: _parseProvider(json['provider'] as String?),
      webDavUrl: json['webDavUrl'] as String? ?? '',
      webDavUsername: json['webDavUsername'] as String? ?? '',
      webDavPassword: json['webDavPassword'] as String? ?? '',
      webDavBasePath: json['webDavBasePath'] as String? ?? 'QuickSave',
      s3Endpoint: json['s3Endpoint'] as String? ?? '',
      s3Bucket: json['s3Bucket'] as String? ?? '',
      s3AccessKey: json['s3AccessKey'] as String? ?? '',
      s3SecretKey: json['s3SecretKey'] as String? ?? '',
      s3Prefix: json['s3Prefix'] as String? ?? 'quicksave',
      s3Region: json['s3Region'] as String? ?? 'us-east-1',
    );
  }

  static CloudBackupProvider _parseProvider(String? raw) {
    switch (raw) {
      case 'webdav':
        return CloudBackupProvider.webdav;
      case 's3':
        return CloudBackupProvider.s3;
      case 'googleDrive':
        return CloudBackupProvider.googleDrive;
      default:
        return CloudBackupProvider.none;
    }
  }
}
