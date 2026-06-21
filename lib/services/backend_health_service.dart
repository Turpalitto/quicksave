import 'package:dio/dio.dart';

/// Проверка доступности backend (GET /health).
class BackendHealthService {
  BackendHealthService._();
  static final BackendHealthService instance = BackendHealthService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  /// Возвращает true, если backend отвечает { ok: true }.
  Future<bool> ping(String backendUrl) async {
    final base = backendUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) return false;
    try {
      final response = await _dio.get('$base/health');
      final data = response.data;
      return response.statusCode == 200 &&
          data is Map &&
          data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  String healthEndpoint(String backendUrl) {
    final base = backendUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/health';
  }
}
