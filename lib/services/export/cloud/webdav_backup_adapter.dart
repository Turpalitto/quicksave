import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../features/settings/domain/cloud_backup_config.dart';
import 'cloud_backup_adapter.dart';

/// WebDAV upload via HTTP PUT with optional Basic auth.
class WebDavBackupAdapter implements CloudBackupAdapter {
  WebDavBackupAdapter(this.config, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 10),
              sendTimeout: const Duration(minutes: 10),
              validateStatus: (code) => code != null && code < 500,
            ),
          );

  final CloudBackupConfig config;
  final Dio _dio;

  @override
  String get destinationName => 'WebDAV';

  @override
  Future<void> testConnection() async {
    final base = _normalizedBaseUrl();
    if (base.isEmpty) {
      throw CloudBackupException('webdav_url_required');
    }
    final response = await _dio.request<void>(
      base,
      options: Options(method: 'PROPFIND', headers: _authHeaders()),
    );
    if (!_isSuccess(response.statusCode)) {
      throw CloudBackupException(
        'webdav_connection_failed',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<String> upload(
    String localPath, {
    required String remoteFileName,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw CloudBackupException('local_file_missing');
    }

    final remotePath = buildRemotePath(
      basePath: config.webDavBasePath,
      fileName: remoteFileName,
    );
    final uploadUrl = _joinUrl(_normalizedBaseUrl(), remotePath);
    final bytes = await file.readAsBytes();

    final response = await _dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          ..._authHeaders(),
          'Content-Type': 'application/zip',
          'Content-Length': bytes.length,
        },
      ),
    );

    if (!_isSuccess(response.statusCode)) {
      throw CloudBackupException(
        'webdav_upload_failed',
        statusCode: response.statusCode,
      );
    }
    return remotePath;
  }

  /// Builds remote path segments without leading slash.
  static String buildRemotePath({
    required String basePath,
    required String fileName,
  }) {
    final segments = <String>[
      ...basePath.split('/').where((s) => s.trim().isNotEmpty),
      fileName,
    ];
    return segments.join('/');
  }

  String _normalizedBaseUrl() {
    var url = config.webDavUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Map<String, String> _authHeaders() {
    final user = config.webDavUsername.trim();
    final pass = config.webDavPassword;
    if (user.isEmpty) return const {};
    final token = base64Encode(utf8.encode('$user:$pass'));
    return {'Authorization': 'Basic $token'};
  }

  String _joinUrl(String base, String remotePath) {
    final encoded = remotePath.split('/').map(Uri.encodeComponent).join('/');
    return '$base/$encoded';
  }

  bool _isSuccess(int? code) =>
      code != null &&
      (code == 200 || code == 201 || code == 204 || code == 207);
}
