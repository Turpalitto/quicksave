import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/resolve_result.dart';

/// Клиент, который обращается к backend endpoint POST /resolve.
class InstagramResolver {
  InstagramResolver._();
  static final InstagramResolver instance = InstagramResolver._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      sendTimeout: AppConstants.networkTimeout,
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  /// Резолвит Instagram-ссылку через backend (single / carousel / story).
  Future<ResolveResult> resolve({
    required String instagramUrl,
    required String backendUrl,
    String? cursor,
    String? userId,
  }) async {
    if (instagramUrl.isEmpty) {
      throw const InvalidUrlException();
    }

    final url =
        '${backendUrl.replaceAll(RegExp(r'/$'), '')}'
        '${AppConstants.resolveEndpoint}';

    final payload = <String, dynamic>{'url': instagramUrl};
    if (cursor != null && cursor.isNotEmpty) payload['cursor'] = cursor;
    if (userId != null && userId.isNotEmpty) payload['userId'] = userId;

    Response<dynamic> response;
    try {
      response = await _dio.post(url, data: payload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NoInternetException();
      }
      throw const ServerException();
    }

    final status = response.statusCode ?? 0;
    final data = response.data;

    if (status >= 200 && status < 300 && data is Map<String, dynamic>) {
      final ok = data['ok'] == true || data['success'] == true;
      if (!ok) {
        throw _exceptionForError(data['error'] as String?);
      }

      final result = ResolveResult.fromJson(data, instagramUrl);
      if (result.items.isEmpty) {
        throw const ResolverException();
      }
      return result;
    }

    if (data is Map<String, dynamic>) {
      throw _exceptionForError(data['error'] as String?, is2xx: false);
    }

    throw const ServerException();
  }

  /// Маппинг кода ошибки backend → соответствующее исключение.
  /// На 2xx-ответе без ok=true неизвестный код трактуется как ошибка резолвера,
  /// на 4xx/5xx — как серверная ошибка.
  AppException _exceptionForError(String? code, {bool is2xx = true}) {
    switch (code) {
      case 'invalid_url':
        return const InvalidUrlException();
      case 'private':
        return const PrivatePostException();
      case 'not_found':
        return const NotFoundPostException();
      case 'rate_limited':
        return const RateLimitedException();
      case 'resolver_failed':
        return const ResolverException();
      default:
        return is2xx ? const ResolverException() : const ServerException();
    }
  }
}
