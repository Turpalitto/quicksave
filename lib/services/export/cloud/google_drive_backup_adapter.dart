import 'cloud_backup_adapter.dart';

/// Google Drive requires OAuth — not yet implemented.
class GoogleDriveBackupAdapter implements CloudBackupAdapter {
  @override
  String get destinationName => 'Google Drive';

  @override
  Future<void> testConnection() {
    throw CloudBackupUnavailableException('google_drive_coming_soon');
  }

  @override
  Future<String> upload(String localPath, {required String remoteFileName}) {
    throw CloudBackupUnavailableException('google_drive_coming_soon');
  }
}
