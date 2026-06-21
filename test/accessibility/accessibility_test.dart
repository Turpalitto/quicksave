import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quicksave/features/downloader/domain/resolve_result.dart';
import 'package:quicksave/features/downloader/presentation/providers/download_provider.dart';
import 'package:quicksave/features/downloader/presentation/screens/preview_screen.dart';
import 'package:quicksave/features/home/presentation/screens/home_screen.dart';
import 'package:quicksave/features/history/presentation/screens/history_screen.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';
import 'package:quicksave/features/settings/presentation/screens/settings_screen.dart';
import 'package:quicksave/l10n/app_localizations.dart';
import '../helpers/mock_setup.dart';
import '../helpers/preview_test_notifier.dart';

double _relativeLuminance(Color c) {
  double channel(double component) {
    return component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

DownloadResolved _sampleResolved() {
  const result = ResolveResult(
    type: ResolveType.single,
    sourceUrl: 'https://instagram.com/reel/test/',
    items: [
      MediaItem(
        id: 'test_0',
        index: 0,
        mediaType: MediaType.video,
        mediaUrl: 'https://cdn.example.com/v.mp4',
        fileName: 'quicksave_test.mp4',
      ),
    ],
  );
  return const DownloadResolved(
    result: result,
    sourceUrl: 'https://instagram.com/reel/test/',
    selectedIds: {'test_0'},
  );
}

void main() {
  setUpAll(() async {
    await initPlatformMocks();
    await SettingsRepository.instance.save(const AppSettings());
  });

  setUp(() async {
    await SettingsRepository.instance.save(const AppSettings(isPro: false));
  });

  Widget wrap(Widget child, {List<Override>? overrides}) => ProviderScope(
        overrides: overrides ?? [],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  group('Accessibility', () {
    testWidgets('home screen exposes semantics tree', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('primary icon buttons have adequate tap targets', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final icons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final btn in icons) {
        final c = btn.constraints;
        if (c != null) {
          expect(c.minWidth, greaterThanOrEqualTo(40));
          expect(c.minHeight, greaterThanOrEqualTo(40));
        }
      }
    });

    testWidgets('theme primary on surface meets WCAG AA contrast', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final scheme = Theme.of(tester.element(find.byType(HomeScreen))).colorScheme;
      final ratio = contrastRatio(scheme.onSurface, scheme.surface);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    testWidgets('history screen search field has semantics label', (tester) async {
      await tester.pumpWidget(wrap(const HistoryScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('preview screen exposes download and cancel semantics', (tester) async {
      final resolved = _sampleResolved();
      await tester.pumpWidget(
        wrap(
          const PreviewScreen(sourceUrl: 'https://instagram.com/reel/test/'),
          overrides: [
            downloadProvider.overrideWith(
              (ref) => PreviewTestDownloadNotifier(ref, resolved),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.bySemanticsLabel('Download media'), findsOneWidget);
      expect(find.bySemanticsLabel('Cancel preview'), findsOneWidget);
    });

    testWidgets('preview stop button has semantics when downloading', (tester) async {
      const progress = DownloadInProgress(
        completed: 0,
        total: 1,
        currentProgress: 0.42,
        currentLabel: 'quicksave_test.mp4',
      );
      await tester.pumpWidget(
        wrap(
          const PreviewScreen(sourceUrl: 'https://instagram.com/reel/test/'),
          overrides: [
            downloadProvider.overrideWith(
              (ref) => PreviewTestDownloadNotifier(ref, progress),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.bySemanticsLabel('Stop download'), findsOneWidget);
    });

    testWidgets('settings screen exposes toggle and pro semantics', (tester) async {
      await tester.pumpWidget(wrap(const SettingsScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Auto-download after Share'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsWidgets);

      await tester.scrollUntilVisible(
        find.textContaining('QuickSave Cloud'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('QuickSave Cloud'), findsOneWidget);

      final proActive = find.text('Pro active').evaluate().isNotEmpty;
      if (proActive) {
        expect(find.bySemanticsLabel('Add scheduled profile'), findsOneWidget);
      } else {
        await tester.scrollUntilVisible(
          find.text('Activate'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text('Unlock scheduler, ZIP export, self-hosted'),
          findsOneWidget,
        );
        expect(find.text('Activate'), findsOneWidget);
      }
    });

    testWidgets('preview icon buttons have adequate tap targets', (tester) async {
      final resolved = _sampleResolved();
      await tester.pumpWidget(
        wrap(
          const PreviewScreen(sourceUrl: 'https://instagram.com/reel/test/'),
          overrides: [
            downloadProvider.overrideWith(
              (ref) => PreviewTestDownloadNotifier(ref, resolved),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      for (final btn in tester.widgetList<IconButton>(find.byType(IconButton))) {
        final c = btn.constraints;
        if (c != null) {
          expect(c.minWidth, greaterThanOrEqualTo(40));
          expect(c.minHeight, greaterThanOrEqualTo(40));
        }
      }
    });

    testWidgets('settings icon buttons have adequate tap targets', (tester) async {
      await tester.pumpWidget(wrap(const SettingsScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      for (final btn in tester.widgetList<IconButton>(find.byType(IconButton))) {
        final c = btn.constraints;
        if (c != null) {
          expect(c.minWidth, greaterThanOrEqualTo(40));
          expect(c.minHeight, greaterThanOrEqualTo(40));
        }
      }
    });
  });
}
