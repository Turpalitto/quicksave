import '../../../features/settings/domain/cloud_backup_config.dart';
import 'cloud_backup_adapter.dart';
import 'cloud_backup_registry.dart';

/// Orchestrates cloud backup uploads for Pro library exports.
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  CloudBackupAdapter? adapterFor(CloudBackupConfig config) =>
      cloudBackupAdapterFor(config);

  Future<void> testConnection(CloudBackupConfig config) async {
    final adapter = _requireAdapter(config);
    await adapter.testConnection();
  }

  Future<CloudBackupResult> uploadArchive(
    String localPath,
    CloudBackupConfig config, {
    String? remoteFileName,
  }) async {
    if (!config.enabled || !config.isConfigured) {
      return const CloudBackupResult.failure('cloud_backup_disabled');
    }

    final adapter = _requireAdapter(config);
    try {
      final name = remoteFileName ?? cloudBackupFileNameFromPath(localPath);
      final remote = await adapter.upload(localPath, remoteFileName: name);
      return CloudBackupResult.success(remote);
    } on CloudBackupUnavailableException catch (e) {
      return CloudBackupResult.failure(e.message);
    } on CloudBackupException catch (e) {
      return CloudBackupResult.failure(e.message);
    } catch (_) {
      return const CloudBackupResult.failure('cloud_backup_unknown');
    }
  }

  CloudBackupAdapter _requireAdapter(CloudBackupConfig config) {
    final adapter = adapterFor(config);
    if (adapter == null || !config.isConfigured) {
      throw CloudBackupException('cloud_backup_not_configured');
    }
    return adapter;
  }
}
