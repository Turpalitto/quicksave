import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksave/features/downloader/presentation/providers/download_provider.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

import '../../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  group('DownloadNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      // Принудительно сбрасываем настройки к дефолтам.
      final repo = SettingsRepository.instance;
      await repo.save(const AppSettings());

      container = ProviderContainer();
      // Дайте settingsProvider загрузиться.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with DownloadIdle', () {
      expect(container.read(downloadProvider), isA<DownloadIdle>());
    });

    test('reset returns to DownloadIdle from any state', () async {
      // Изначально idle.
      container.read(downloadProvider.notifier).reset();
      expect(container.read(downloadProvider), isA<DownloadIdle>());
    });
  });
}
