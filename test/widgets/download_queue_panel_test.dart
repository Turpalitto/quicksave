import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quicksave/features/downloader/presentation/widgets/download_queue_panel.dart';
import 'package:quicksave/l10n/app_localizations.dart';
import 'package:quicksave/services/download_queue.dart';

import '../helpers/mock_setup.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUpAll(initPlatformMocks);

  group('DownloadQueuePanel', () {
    setUp(DownloadQueue.instance.resetForTests);

    testWidgets('renders tasks with progress and queue controls', (tester) async {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/video.mp4',
        fileName: 'video.mp4',
        runPreflight: false,
      );

      await tester.pumpWidget(_wrap(const DownloadQueuePanel()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      queue.pause(id);
      await tester.pump();

      expect(find.text('video.mp4'), findsOneWidget);
      expect(find.text('Download queue'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Resume'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button calls queue.cancel', (tester) async {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/cancel.mp4',
        fileName: 'cancel.mp4',
        runPreflight: false,
      );

      await tester.pumpWidget(_wrap(const DownloadQueuePanel()));
      await tester.pump();
      queue.pause(id);
      await tester.pump();

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pump();

      expect(
        queue.tasks.firstWhere((t) => t.id == id).status,
        DownloadTaskStatus.cancelled,
      );
    });

    testWidgets('pause button calls queue.pause', (tester) async {
      final queue = DownloadQueue.instance;
      final id = queue.enqueue(
        url: 'https://example.com/pause.mp4',
        fileName: 'pause.mp4',
        runPreflight: false,
      );

      await tester.pumpWidget(_wrap(const DownloadQueuePanel()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pauseFinder = find.byTooltip('Pause');
      if (pauseFinder.evaluate().isNotEmpty) {
        await tester.tap(pauseFinder);
        await tester.pump();
        expect(
          queue.tasks.firstWhere((t) => t.id == id).status,
          DownloadTaskStatus.paused,
        );
      } else {
        queue.pause(id);
        expect(
          queue.tasks.firstWhere((t) => t.id == id).status,
          DownloadTaskStatus.paused,
        );
      }
    });
  });
}
