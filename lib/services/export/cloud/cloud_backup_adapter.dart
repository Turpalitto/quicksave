/// Result of a cloud backup operation.
class CloudBackupResult {
  final bool success;
  final String? remotePath;
  final String? errorCode;

  const CloudBackupResult.success(this.remotePath)
    : success = true,
      errorCode = null;

  const CloudBackupResult.failure(this.errorCode)
    : success = false,
      remotePath = null;
}

/// Thrown when a destination is not yet available (e.g. Google Drive OAuth).
class CloudBackupUnavailableException implements Exception {
  CloudBackupUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when upload or connection test fails.
class CloudBackupException implements Exception {
  CloudBackupException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class CloudBackupAdapter {
  String get destinationName;

  /// Verifies credentials and reachability without uploading media.
  Future<void> testConnection();

  /// Uploads [localPath] and returns the remote object path/key.
  Future<String> upload(String localPath, {required String remoteFileName});
}
