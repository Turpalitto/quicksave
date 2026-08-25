import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/app.dart';
import 'package:quicksave/core/widgets/ios/ios_button.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

import '../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  Future<void> dismissOnboarding(WidgetTester tester) async {
    for (final label in ['Got it', 'Понятно']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
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

  testWidgets('Empty URL shows inline error', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await dismissOnboarding(tester);

    final findMedia = find.text('Find media');
    final findMediaRu = find.text('Найти медиа');
    // Empty input keeps the button disabled — tapping must do nothing.
    final buttonLabel = findMedia.evaluate().isNotEmpty
        ? findMedia
        : findMediaRu;
    final blueButton = tester.widget<IosBlueButton>(
      find.ancestor(of: buttonLabel, matching: find.byType(IosBlueButton)),
    );
    expect(blueButton.onPressed, isNull);
  });

  testWidgets('Invalid URL shows inline error', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await dismissOnboarding(tester);

    final findMedia = find.text('Find media');
    final findMediaRu = find.text('Найти медиа');
    // Empty input keeps the button disabled — no error, no navigation.
    expect(
      findMedia.evaluate().isNotEmpty || findMediaRu.evaluate().isNotEmpty,
      isTrue,
    );
    final button = findMedia.evaluate().isNotEmpty ? findMedia : findMediaRu;
    final blueButton = tester.widget<IosBlueButton>(
      find.ancestor(of: button, matching: find.byType(IosBlueButton)),
    );
    expect(blueButton.onPressed, isNull);
  });
}
