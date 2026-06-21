import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../features/settings/domain/cloud_backup_config.dart';
import 'cloud_backup_adapter.dart';

/// S3-compatible upload using AWS Signature Version 4 (MinIO, R2, AWS S3).
class S3BackupAdapter implements CloudBackupAdapter {
  S3BackupAdapter(this.config, {Dio? dio})
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
  String get destinationName => 'S3';

  @override
  Future<void> testConnection() async {
    final objectKey = buildObjectKey(
      prefix: config.s3Prefix,
      fileName: '.quicksave-probe',
    );
    final signed = _signRequest(
      method: 'HEAD',
      objectKey: objectKey,
      payloadHash: _emptyPayloadHash,
      contentType: null,
    );
    final response = await _dio.head<void>(
      signed.url,
      options: Options(headers: signed.headers),
    );
    if (response.statusCode == 404) return;
    if (!_isSuccess(response.statusCode)) {
      throw CloudBackupException(
        's3_connection_failed',
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

    final bytes = await file.readAsBytes();
    final payloadHash = sha256.convert(bytes).toString();
    final objectKey = buildObjectKey(
      prefix: config.s3Prefix,
      fileName: remoteFileName,
    );
    final signed = _signRequest(
      method: 'PUT',
      objectKey: objectKey,
      payloadHash: payloadHash,
      contentType: 'application/zip',
    );

    final response = await _dio.put<void>(
      signed.url,
      data: bytes,
      options: Options(headers: signed.headers),
    );

    if (!_isSuccess(response.statusCode)) {
      throw CloudBackupException(
        's3_upload_failed',
        statusCode: response.statusCode,
      );
    }
    return objectKey;
  }

  static String buildObjectKey({
    required String prefix,
    required String fileName,
  }) {
    final parts = <String>[
      ...prefix.split('/').where((s) => s.trim().isNotEmpty),
      fileName,
    ];
    return parts.join('/');
  }

  _SignedRequest _signRequest({
    required String method,
    required String objectKey,
    required String payloadHash,
    required String? contentType,
  }) {
    final endpoint = _normalizedEndpoint();
    final uri = Uri.parse('$endpoint/${config.s3Bucket}/$objectKey');
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = amzDate.substring(0, 8);
    final host = uri.host + (uri.hasPort ? ':${uri.port}' : '');

    final headers = <String, String>{
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (contentType != null) 'content-type': contentType,
    };

    final canonicalHeaders =
        headers.entries
            .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}')
            .toList()
          ..sort();
    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).toList()
      ..sort();

    final canonicalRequest = [
      method,
      uri.path,
      '',
      '${canonicalHeaders.join('\n')}\n',
      signedHeaders.join(';'),
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/${config.s3Region}/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _deriveSigningKey(
      config.s3SecretKey,
      dateStamp,
      config.s3Region,
    );
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'AWS4-HMAC-SHA256 Credential=${config.s3AccessKey}/$credentialScope, '
        'SignedHeaders=${signedHeaders.join(';')}, Signature=$signature';

    return _SignedRequest(
      url: uri.toString(),
      headers: {...headers, 'Authorization': authorization},
    );
  }

  List<int> _deriveSigningKey(String secret, String dateStamp, String region) {
    List<int> key = utf8.encode('AWS4$secret');
    for (final part in [dateStamp, region, 's3', 'aws4_request']) {
      key = Hmac(sha256, key).convert(utf8.encode(part)).bytes;
    }
    return key;
  }

  String _normalizedEndpoint() {
    var url = config.s3Endpoint.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String _formatAmzDate(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final mo = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '${y}${mo}${d}T${h}${mi}${s}Z';
  }

  bool _isSuccess(int? code) =>
      code != null && (code == 200 || code == 201 || code == 204);

  static const _emptyPayloadHash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
}

class _SignedRequest {
  const _SignedRequest({required this.url, required this.headers});
  final String url;
  final Map<String, String> headers;
}
