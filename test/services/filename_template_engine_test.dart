import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/services/filename_template_engine.dart';

void main() {
  group('FilenameTemplateEngine', () {
    test('sanitizeSegment removes invalid characters', () {
      expect(
        FilenameTemplateEngine.sanitizeSegment('user/name:test'),
        'user_name_test',
      );
    });

    test('apply default template', () {
      final name = FilenameTemplateEngine.apply(
        template: '{username}_{type}_{shortcode}_{date}',
        username: 'creator',
        type: 'reel',
        shortcode: 'ABC123',
        date: DateTime(2026, 6, 21),
        extension: 'mp4',
      );
      expect(name, contains('creator'));
      expect(name, contains('20260621'));
      expect(name.endsWith('.mp4'), isTrue);
    });

    test('validateTemplate rejects invalid chars', () {
      expect(
        FilenameTemplateEngine.validateTemplate('bad|name'),
        'invalid_characters',
      );
    });

    test('preview returns sample filename', () {
      final p = FilenameTemplateEngine.preview();
      expect(p, isNotEmpty);
      expect(p.contains('creator'), isTrue);
    });
  });
}
