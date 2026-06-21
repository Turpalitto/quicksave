import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/settings/domain/cloud_backup_config.dart';
import 'package:quicksave/services/export/cloud/s3_backup_adapter.dart';
import 'package:quicksave/services/export/cloud/webdav_backup_adapter.dart';

void main() {
  group('CloudBackupConfig', () {
    test('webdav configured when url present', () {
      const c = CloudBackupConfig(
        provider: CloudBackupProvider.webdav,
        webDavUrl: 'https://nas.local/dav',
      );
      expect(c.isConfigured, true);
    });

    test('s3 configured when endpoint bucket and keys present', () {
      const c = CloudBackupConfig(
        provider: CloudBackupProvider.s3,
        s3Endpoint: 'https://s3.example.com',
        s3Bucket: 'media',
        s3AccessKey: 'key',
        s3SecretKey: 'secret',
      );
      expect(c.isConfigured, true);
    });

    test('json roundtrip', () {
      const c = CloudBackupConfig(
        enabled: true,
        provider: CloudBackupProvider.webdav,
        webDavUrl: 'https://x',
        webDavBasePath: 'exports',
      );
      final restored = CloudBackupConfig.fromJson(c.toJson());
      expect(restored.enabled, true);
      expect(restored.provider, CloudBackupProvider.webdav);
      expect(restored.webDavUrl, 'https://x');
      expect(restored.webDavBasePath, 'exports');
    });
  });

  group('WebDavBackupAdapter.buildRemotePath', () {
    test('joins base path and file name', () {
      expect(
        WebDavBackupAdapter.buildRemotePath(
          basePath: 'QuickSave/backups',
          fileName: 'export.zip',
        ),
        'QuickSave/backups/export.zip',
      );
    });
  });

  group('S3BackupAdapter.buildObjectKey', () {
    test('joins prefix and file name', () {
      expect(
        S3BackupAdapter.buildObjectKey(
          prefix: 'quicksave/exports',
          fileName: 'export.zip',
        ),
        'quicksave/exports/export.zip',
      );
    });
  });
}
