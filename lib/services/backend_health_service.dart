import 'package:dio/dio.dart';

import '../core/network/backend_warmup.dart';

export '../core/network/backend_warmup.dart' show backendNeedsWarmUp;

/// Backend health probe with latency and version.
class BackendHealthResult {
  final bool available;
  final int? latencyMs;
  final String? version;
  final String? error;
  final int attempts;

  const BackendHealthResult({
    required this.available,
    this.latencyMs,
    this.version,
    this.error,
    this.attempts = 1,
  });
}

int backendHealthMaxAttempts(String backendUrl) =>
    backendResolveMaxAttempts(backendUrl);

Duration backendHealthConnectTimeout(String backendUrl) =>
    backendResolveTimeout(backendUrl);

/// Проверка доступности backend (GET /health, /version).
class BackendHealthService {
  BackendHealthService._();
  static final BackendHealthService instance = BackendHealthService._();

  DateTime? lastSuccessfulCheck;
  BackendHealthResult? lastHostedResult;
  BackendHealthResult? lastSelfHostedResult;

  final Dio _dio = Dio(
    BaseOptions(
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  String _base(String backendUrl) => backendUrl.replaceAll(RegExp(r'/$'), '');

  Future<bool> ping(String backendUrl) async {
    final r = await checkHealth(backendUrl);
    return r.available;
  }

  Future<BackendHealthResult> checkHealth(String backendUrl) async {
    final base = _base(backendUrl);
    if (base.isEmpty) {
      return const BackendHealthResult(available: false, error: 'empty_url');
    }

    final maxAttempts = backendHealthMaxAttempts(base);
    final timeout = backendHealthConnectTimeout(base);
    final overallStart = DateTime.now();
    BackendHealthResult? last;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
      last = await _probeOnce(
        base,
        connectTimeout: timeout,
        receiveTimeout: timeout,
      );
      last = BackendHealthResult(
        available: last.available,
        latencyMs: DateTime.now().difference(overallStart).inMilliseconds,
        version: last.version,
        error: last.error,
        attempts: attempt,
      );
      if (last.available) {
        lastSuccessfulCheck = DateTime.now();
        return last;
      }
      if (!_shouldRetry(last.error)) break;
    }

    return last!;
  }

  bool _shouldRetry(String? error) {
    if (error == null) return false;
    final lower = error.toLowerCase();
    return lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused');
  }

  Future<BackendHealthResult> _probeOnce(
    String base, {
    required Duration connectTimeout,
    required Duration receiveTimeout,
  }) async {
    final start = DateTime.now();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$base/health',
        options: Options(
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );
      final data = response.data;
      final ok =
          response.statusCode == 200 && data != null && data['ok'] == true;
      if (!ok) {
        return BackendHealthResult(
          available: false,
          latencyMs: DateTime.now().difference(start).inMilliseconds,
          error: 'unhealthy',
        );
      }
      return BackendHealthResult(
        available: true,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        version: data['version'] as String?,
      );
    } on DioException catch (e) {
      return BackendHealthResult(
        available: false,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        error: e.message ?? e.type.name,
      );
    } catch (e) {
      return BackendHealthResult(
        available: false,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        error: e.toString(),
      );
    }
  }

  String healthEndpoint(String backendUrl) => '${_base(backendUrl)}/health';
}
