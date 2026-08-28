import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/downloader/presentation/providers/download_provider.dart';
import 'package:quicksave/features/history/data/history_repository.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';
import 'package:quicksave/core/errors/failures.dart';
import 'package:quicksave/services/download_queue.dart';

import '../../helpers/mock_setup.dart';

class _FakeConnectivityPlatform extends Fake implements ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.wifi];
}

String _freshOe() =>
    (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toRadixString(16);

void main() {
  setUpAll(() {
    initPlatformMocks();
    ConnectivityPlatform.instance = _FakeConnectivityPlatform();
  });

  late HttpServer server;
  late int resolveCount;
  late bool alwaysExpired;
  late String expiredPath;
  late String shortcode;

  Future<void> startServer() async {
    resolveCount = 0;
    alwaysExpired = false;
    expiredPath = '/expired-a.mp4';
    shortcode = 'alpha1';
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.listen((request) async {
        final expired = alwaysExpired || resolveCount == 1;
        if (request.method == 'POST' && request.uri.path == '/resolve') {
          resolveCount += 1;
          final mediaUrl = expired
              ? 'http://127.0.0.1:${server.port}$expiredPath?oe=0'
              : 'http://127.0.0.1:${server.port}/fresh.mp4?oe=${_freshOe()}';
          final body = jsonEncode({
            'ok': true,
            'type': 'single',
            'author': 'tester',
            'shortcode': shortcode,
            'videoCount': 1,
            'items': [
              {
                'id': 'i1',
                'index': 0,
                'mediaType': 'video',
                'mediaUrl': mediaUrl,
                'fileName': 'clip.mp4',
                'postUrl': 'https://www.instagram.com/reel/$shortcode/',
                'needsResolve': false,
              },
            ],
          });
          request.response
            ..headers.contentType = ContentType.json
            ..write(body)
            ..close();
          return;
        }
        if (request.method == 'HEAD') {
          request.response.statusCode = expired ? 403 : 200;
          request.response.contentLength = expired ? 0 : 13;
          await request.response.close();
          return;
        }
        if (request.method == 'GET') {
          if (expired) {
            request.response.statusCode = 403;
            await request.response.close();
            return;
          }
          final payload = utf8.encode('VIDEO_CONTENT');
          request.response
            ..statusCode = 200
            ..contentLength = payload.length
            ..add(payload);
          await request.response.close();
          return;
        }
        request.response.statusCode = 404;
        await request.response.close();
      }),
    );
  }

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    return container;
  }

  group('DownloadNotifier re-resolve on expired CDN URL (e2e)', () {
    setUp(() async {
      await startServer();
      await SettingsRepository.instance.save(
        AppSettings(
          backendMode: BackendMode.selfHosted,
          backendUrl: 'http://127.0.0.1:${server.port}',
          saveToGallery: false,
        ),
      );
      await HistoryRepository.instance.clear();
      DownloadQueue.instance.resetForTests();
    });

    tearDown(() async {
      DownloadQueue.instance.resetForTests();
      await server.close(force: true);
    });

    test('expired CDN URL triggers re-resolve and completes download', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final file = File('/tmp/test_docs/QuickSave/clip.mp4');
      if (file.existsSync()) file.deleteSync();

      final notifier = container.read(downloadProvider.notifier);
      await notifier.resolve('https://www.instagram.com/reel/$shortcode/');
      expect(container.read(downloadProvider), isA<DownloadResolved>());

      await notifier.download().timeout(const Duration(seconds: 15));

      final state = container.read(downloadProvider);
      expect(state, isA<DownloadSuccess>());
      final success = state as DownloadSuccess;
      expect(success.items, hasLength(1));
      expect(success.failedCount, 0);
      expect(resolveCount, 2);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), utf8.encode('VIDEO_CONTENT'));
    });

    test('re-resolve returning expired URL again fails with UrlExpiredFailure',
        () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      alwaysExpired = true;
      expiredPath = '/expired-b.mp4';
      shortcode = 'beta2';

      final notifier = container.read(downloadProvider.notifier);
      await notifier.resolve('https://www.instagram.com/reel/$shortcode/');
      expect(container.read(downloadProvider), isA<DownloadResolved>());

      await notifier.download().timeout(const Duration(seconds: 15));

      final state = container.read(downloadProvider);
      expect(state, isA<DownloadFailureState>());
      final failure = (state as DownloadFailureState).failure;
      expect(failure, isA<UrlExpiredFailure>());
      expect(resolveCount, 2);
    });
  });
}
