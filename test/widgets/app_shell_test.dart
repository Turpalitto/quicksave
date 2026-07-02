import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/app.dart';
import 'package:quicksave/core/utils/validators.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

import '../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  test('prepareUrl accepts profile shorthand', () {
    expect(Validators.prepareUrl('@natgeo'), 'https://instagram.com/natgeo');
  });

  testWidgets('App shell switches library tab', (tester) async {
    await SettingsRepository.instance.save(
      const AppSettings(onboardingCompleted: true),
    );

    await tester.pumpWidget(const ProviderScope(child: QuickSaveApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    for (final label in ['Got it', 'Понятно']) {
      if (find.text(label).evaluate().isNotEmpty) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        break;
      }
    }

    final libraryTab = find.text('Library');
    final libraryTabRu = find.text('Библиотека');
    if (libraryTab.evaluate().isNotEmpty) {
      await tester.tap(libraryTab);
    } else {
      await tester.tap(libraryTabRu);
    }
    await tester.pumpAndSettle();

    expect(find.text('Full history').evaluate().isNotEmpty ||
        find.text('Полная история').evaluate().isNotEmpty, isTrue);
  });
}
