import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/web/data/web_library_repository.dart';

import '../../helpers/mock_setup.dart';

void main() {
  setUp(() async {
    await initPlatformMocks();
    await WebLibraryRepository.instance.clear();
  });

  group('WebLibraryRepository', () {
    test('imports array json and dedupes by id', () async {
      const raw = '''
[
  {"id":"a1","sourceUrl":"https://instagram.com/p/1","author":"alice","createdAt":"2026-01-01"},
  {"id":"a1","sourceUrl":"https://instagram.com/p/1","author":"alice","createdAt":"2026-01-02"}
]
''';
      final count = await WebLibraryRepository.instance.importFromJsonString(
        raw,
      );
      expect(count, 2);
      final all = await WebLibraryRepository.instance.getAll();
      expect(all.length, 1);
      expect(all.first['id'], 'a1');
    });

    test('imports metadata export wrapper', () async {
      const raw = '''
{"items":[{"id":"b1","sourceUrl":"https://x","author":"bob","createdAt":"2026-02-01"}]}
''';
      await WebLibraryRepository.instance.importFromJsonString(raw);
      final all = await WebLibraryRepository.instance.getAll();
      expect(all.length, 1);
      expect(all.first['author'], 'bob');
    });

    test('toCsv includes header and rows', () {
      final csv = WebLibraryRepository.instance.toCsv([
        {
          'id': '1',
          'sourceUrl': 'https://instagram.com/p/x',
          'author': 'user',
          'mediaType': 'video',
          'status': 'completed',
          'createdAt': '2026-01-01',
          'caption': 'hello',
        },
      ]);
      expect(csv.startsWith('id,sourceUrl'), isTrue);
      expect(csv.contains('"user"'), isTrue);
    });
  });
}
