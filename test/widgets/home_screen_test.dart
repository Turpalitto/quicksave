import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/app.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

import '../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  Future<void> dismissOnboarding(WidgetTester tester) async {
    for (final label in ['Got it', 'Понятно']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        break;
      }
    }
  }

  testWidgets('App shell renders with title and bottom tabs', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('QuickSave'), findsWidgets);
    expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Empty URL shows snackbar', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await dismissOnboarding(tester);

    final findMedia = find.text('Find media');
    final findMediaRu = find.text('Найти медиа');
    if (findMedia.evaluate().isNotEmpty) {
      await tester.tap(findMedia);
    } else {
      await tester.tap(findMediaRu);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Invalid URL shows snackbar', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await dismissOnboarding(tester);

    await tester.enterText(find.byType(TextField), 'https://example.com');
    final findMedia = find.text('Find media');
    final findMediaRu = find.text('Найти медиа');
    if (findMedia.evaluate().isNotEmpty) {
      await tester.tap(findMedia);
    } else {
      await tester.tap(findMediaRu);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
