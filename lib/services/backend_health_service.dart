import 'package:dio/dio.dart';

/// Backend health probe with latency and version.
class BackendHealthResult {
  final bool available;
  final int? latencyMs;
  final String? version;
  final String? error;

  const BackendHealthResult({
    required this.available,
    this.latencyMs,
    this.version,
    this.error,
  });
}

/// Проверка доступности backend (GET /health, /version).
class BackendHealthService {
  BackendHealthService._();
  static final BackendHealthService instance = BackendHealthService._();

  DateTime? lastSuccessfulCheck;
  BackendHealthResult? lastHostedResult;
  BackendHealthResult? lastSelfHostedResult;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
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
    final start = DateTime.now();
    try {
      final response = await _dio.get('$base/health');
      final data = response.data;
      final ok =
          response.statusCode == 200 && data is Map && data['ok'] == true;
      if (!ok) {
        return BackendHealthResult(
          available: false,
          latencyMs: DateTime.now().difference(start).inMilliseconds,
          error: 'unhealthy',
        );
      }
      final version = data['version'] as String?;
      lastSuccessfulCheck = DateTime.now();
      return BackendHealthResult(
        available: true,
        latencyMs: DateTime.now().difference(start).inMilliseconds,
        version: version,
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
