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

  setUp(DownloadQueue.instance.resetForTests);

  testWidgets('golden: download queue panel with a paused task', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final queue = DownloadQueue.instance;
    queue.enqueue(
      url: 'https://example.com/video.mp4',
      fileName: 'video.mp4',
      runPreflight: false,
    );

    await tester.pumpWidget(_wrap(const DownloadQueuePanel()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    queue.pause(queue.tasks.first.id);
    await tester.pump();

    await expectLater(
      find.byType(DownloadQueuePanel),
      matchesGoldenFile('goldens/download_queue_panel.png'),
    );
  });
}
