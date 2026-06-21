import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/app.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

import '../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  testWidgets('HomeScreen renders with title and actions', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: QuickSaveApp(),
      ),
    );
    // Дать провайдерам загрузиться.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // 'QuickSave' — одинаково в обеих локалях.
    expect(find.text('QuickSave'), findsWidgets);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Empty URL shows snackbar', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: QuickSaveApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    for (final label in ['Got it', 'Понятно']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        break;
      }
    }

    // Нажимаем на кнопку скачивания.
    final downloadButton = find.byIcon(Icons.download).first;
    await tester.ensureVisible(downloadButton);
    await tester.tap(downloadButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // SnackBar должен появиться. Проверяем, что есть какой-то SnackBar.
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Invalid URL shows snackbar', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: QuickSaveApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    for (final label in ['Got it', 'Понятно']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        break;
      }
    }

    await tester.enterText(find.byType(TextField), 'https://example.com');
    final downloadButton = find.byIcon(Icons.download).first;
    await tester.ensureVisible(downloadButton);
    await tester.tap(downloadButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
