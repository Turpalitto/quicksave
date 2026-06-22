import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/errors/exceptions.dart';
import 'package:quicksave/features/downloader/data/instagram_resolver.dart';

Future<Response<dynamic>> _throwTimeout(
  String url,
  Map<String, dynamic> payload, {
  required Duration connectTimeout,
  required Duration receiveTimeout,
  required Duration sendTimeout,
  CancelToken? cancelToken,
}) async {
  throw DioException(
    requestOptions: RequestOptions(path: url),
    type: DioExceptionType.connectionTimeout,
  );
}

void main() {
  test('throws BackendUnreachableException after retryable failures', () async {
    final resolver = InstagramResolver.test(
      hasConnection: () async => true,
      postOverride: _throwTimeout,
    );

    expect(
      () => resolver.resolve(
        instagramUrl: 'https://www.instagram.com/reel/ABC123/',
        backendUrl: 'http://localhost:3000',
      ),
      throwsA(isA<BackendUnreachableException>()),
    );
  });

  test('reports retry attempts via onAttempt callback', () async {
    var calls = 0;
    final resolver = InstagramResolver.test(
      hasConnection: () async => true,
      postOverride:
          (
            url,
            payload, {
            required connectTimeout,
            required receiveTimeout,
            required sendTimeout,
            cancelToken,
          }) async {
            calls++;
            if (calls < 2) {
              throw DioException(
                requestOptions: RequestOptions(path: url),
                type: DioExceptionType.connectionTimeout,
              );
            }
            return Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: url),
              statusCode: 200,
              data: {
                'ok': true,
                'type': 'single',
                'items': [
                  {
                    'id': '1',
                    'mediaUrl': 'https://cdn.example/video.mp4',
                    'fileName': 'video.mp4',
                    'isVideo': true,
                    'index': 0,
                  },
                ],
              },
            );
          },
    );

    final attempts = <List<int>>[];
    final result = await resolver.resolve(
      instagramUrl: 'https://www.instagram.com/reel/ABC123/',
      backendUrl: 'https://quicksave-api.onrender.com',
      onAttempt: (attempt, max) => attempts.add([attempt, max]),
    );

    expect(result.items, isNotEmpty);
    expect(attempts, [
      [1, 3],
      [2, 3],
    ]);
  });

  test('cancel token aborts resolve with DownloadCancelledException', () async {
    final resolver = InstagramResolver.test(
      hasConnection: () async => true,
      postOverride:
          (
            url,
            payload, {
            required connectTimeout,
            required receiveTimeout,
            required sendTimeout,
            cancelToken,
          }) async {
            throw DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.cancel,
            );
          },
    );

    expect(
      () => resolver.resolve(
        instagramUrl: 'https://www.instagram.com/reel/ABC123/',
        backendUrl: 'http://localhost:3000',
        cancelToken: CancelToken()..cancel('test'),
      ),
      throwsA(isA<DownloadCancelledException>()),
    );
  });
}
