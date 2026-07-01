import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/backend_warmup.dart';
import '../../../services/network_connectivity_service.dart';
import '../domain/resolve_result.dart';

/// Клиент, который обращается к backend endpoint POST /resolve.
class InstagramResolver {
  InstagramResolver._({
    Dio? dio,
    Future<bool> Function()? hasConnection,
    Future<Response<dynamic>> Function(
      String url,
      Map<String, dynamic> payload, {
      required Duration connectTimeout,
      required Duration receiveTimeout,
      required Duration sendTimeout,
      CancelToken? cancelToken,
    })?
    postOverride,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               headers: {'Content-Type': 'application/json'},
               validateStatus: (s) => s != null && s < 600,
             ),
           ),
       _hasConnection =
           hasConnection ??
           (() => NetworkConnectivityService.instance.hasConnection),
       _postOverride = postOverride;

  static final InstagramResolver instance = InstagramResolver._();

  @visibleForTesting
  factory InstagramResolver.test({
    Dio? dio,
    Future<bool> Function()? hasConnection,
    Future<Response<dynamic>> Function(
      String url,
      Map<String, dynamic> payload, {
      required Duration connectTimeout,
      required Duration receiveTimeout,
      required Duration sendTimeout,
      CancelToken? cancelToken,
    })?
    postOverride,
  }) => InstagramResolver._(
    dio: dio,
    hasConnection: hasConnection,
    postOverride: postOverride,
  );

  final Dio _dio;
  final Future<bool> Function() _hasConnection;
  final Future<Response<dynamic>> Function(
    String url,
    Map<String, dynamic> payload, {
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required Duration sendTimeout,
    CancelToken? cancelToken,
  })?
  _postOverride;

  /// Резолвит Instagram-ссылку через backend (single / carousel / story).
  Future<ResolveResult> resolve({
    required String instagramUrl,
    required String backendUrl,
    String? cursor,
    String? userId,
    CancelToken? cancelToken,
    void Function(int attempt, int maxAttempts)? onAttempt,
  }) async {
    if (instagramUrl.isEmpty) {
      throw const InvalidUrlException();
    }

    if (!await _hasConnection()) {
      throw const NoInternetException();
    }

    final url =
        '${backendUrl.replaceAll(RegExp(r'/$'), '')}'
        '${AppConstants.resolveEndpoint}';

    final payload = <String, dynamic>{'url': instagramUrl};
    if (cursor != null && cursor.isNotEmpty) payload['cursor'] = cursor;
    if (userId != null && userId.isNotEmpty) payload['userId'] = userId;

    final maxAttempts = backendResolveMaxAttempts(backendUrl);
    final perAttemptTimeout = backendResolveTimeout(backendUrl);
    final deadline = DateTime.now().add(backendResolveOverallTimeout(backendUrl));
    Response<dynamic>? response;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      onAttempt?.call(attempt, maxAttempts);

      if (attempt > 1) {
        final backoff = Duration(seconds: attempt * 2);
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          throw const BackendUnreachableException();
        }
        await Future<void>.delayed(
          backoff < remaining ? backoff : remaining,
        );
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw const BackendUnreachableException();
      }
      final attemptTimeout = remaining < perAttemptTimeout
          ? remaining
          : perAttemptTimeout;

      try {
        final post = _postOverride;
        response = post != null
            ? await post(
                url,
                payload,
                connectTimeout: attemptTimeout,
                receiveTimeout: attemptTimeout,
                sendTimeout: attemptTimeout,
                cancelToken: cancelToken,
              )
            : await _dio.post<Map<String, dynamic>>(
                url,
                data: payload,
                options: Options(
                  connectTimeout: attemptTimeout,
                  receiveTimeout: attemptTimeout,
                  sendTimeout: attemptTimeout,
                ),
                cancelToken: cancelToken,
              );
        break;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          throw const DownloadCancelledException();
        }
        final retry = attempt < maxAttempts && shouldRetryBackendRequest(e.type);
        if (retry) continue;
        if (shouldRetryBackendRequest(e.type)) {
          throw const BackendUnreachableException();
        }
        throw const ServerException();
      }
    }

    if (response == null) {
      throw const BackendUnreachableException();
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
      case 'profile_not_supported':
        return const ProfileNotSupportedException();
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
