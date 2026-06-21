import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/history/data/history_repository.dart';
import 'package:quicksave/features/history/domain/download_item.dart';
import 'package:quicksave/features/history/presentation/providers/history_provider.dart';

import '../../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  // Изоляция тестов: SharedPreferences-мок живёт весь файл, поэтому
  // очищаем историю перед каждым тестом — иначе данные утекают из теста
  // в тест (add → remove видел бы элементы, добавленные в предыдущем тесте).
  setUp(() async {
    await HistoryRepository.instance.clear();
  });

  group('HistoryNotifier', () {
    test('starts with empty list', () async {
      final notifier = HistoryNotifier(HistoryRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state, isEmpty);
    });

    test('add prepends item', () async {
      final notifier = HistoryNotifier(HistoryRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final item = DownloadItem.create(
        sourceUrl: 'https://x',
        filePath: '/tmp/a.mp4',
      );
      await notifier.add(item);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, item.id);
    });

    test('remove removes specific item', () async {
      final notifier = HistoryNotifier(HistoryRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final a = DownloadItem.create(sourceUrl: 'u1', filePath: 'p1');
      final b = DownloadItem.create(sourceUrl: 'u2', filePath: 'p2');
      await notifier.add(a);
      await notifier.add(b);
      expect(notifier.state.length, 2);
      await notifier.remove(a.id);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, b.id);
    });

    test('clear empties the list', () async {
      final notifier = HistoryNotifier(HistoryRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.add(DownloadItem.create(sourceUrl: 'u', filePath: 'p'));
      await notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });
}
