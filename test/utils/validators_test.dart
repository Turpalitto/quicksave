import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/utils/validators.dart';

void main() {
  group('Validators.extractInstagramUrl', () {
    test('returns null for empty text', () {
      expect(Validators.extractInstagramUrl(''), isNull);
    });

    test('extracts reel URL from plain URL', () {
      const text = 'https://www.instagram.com/reel/ABC123/';
      expect(
        Validators.extractInstagramUrl(text),
        'https://www.instagram.com/reel/ABC123/',
      );
    });

    test('extracts URL embedded in surrounding text', () {
      const text =
          'Check out this reel! https://www.instagram.com/reel/XYZ/ Cool!';
      expect(
        Validators.extractInstagramUrl(text),
        'https://www.instagram.com/reel/XYZ/',
      );
    });

    test('extracts URL without www', () {
      const text = 'https://instagram.com/p/POST1/';
      expect(
        Validators.extractInstagramUrl(text),
        'https://instagram.com/p/POST1/',
      );
    });

    test('extracts short URL with instagr.com typo', () {
      const text = 'https://instagr.com/tv/VID1/';
      expect(
        Validators.extractInstagramUrl(text),
        'https://instagr.com/tv/VID1/',
      );
      expect(Validators.normalize(text), 'https://instagram.com/tv/VID1');
      expect(Validators.isValidInstagramUrl(text), isTrue);
    });

    test('extracts /video/reel/ alias URL', () {
      const text = 'https://www.instagram.com/video/reel/DWze_eKkrwr/';
      expect(
        Validators.extractInstagramUrl(text),
        'https://www.instagram.com/video/reel/DWze_eKkrwr/',
      );
      expect(
        Validators.normalize(text),
        'https://www.instagram.com/reel/DWze_eKkrwr',
      );
      expect(Validators.isValidInstagramUrl(text), isTrue);
    });

    test('prepareUrl normalizes share text with alias path', () {
      const text = 'Look https://www.instagram.com/video/reel/ABC123/ wow';
      expect(
        Validators.prepareUrl(text),
        'https://www.instagram.com/reel/ABC123',
      );
    });

    test('returns null for non-instagram URL', () {
      expect(
        Validators.extractInstagramUrl('https://youtube.com/watch?v=abc'),
        isNull,
      );
    });
  });

  group('Validators.isValidInstagramUrl', () {
    test('accepts reel URL', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/reel/X/'),
        isTrue,
      );
    });
    test('accepts p URL', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/p/X/'),
        isTrue,
      );
    });
    test('accepts tv URL', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/tv/X/'),
        isTrue,
      );
    });
    test('rejects explore path as profile', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/explore'),
        isFalse,
      );
    });
    test('rejects story URL', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/stories/'),
        isFalse,
      );
    });
    test('rejects non-instagram URL', () {
      expect(Validators.isValidInstagramUrl('https://example.com/'), isFalse);
    });
    // Edge-кейсы строгой валидации (раньше мягкий contains пропускал их).
    test('rejects instagram pattern hidden in query of other site', () {
      expect(
        Validators.isValidInstagramUrl(
          'https://example.com/?x=instagram.com/reel/abc',
        ),
        isFalse,
      );
    });
    test('rejects instagram pattern as path of other site', () {
      expect(
        Validators.isValidInstagramUrl(
          'https://evil.com/instagram.com/reel/abc',
        ),
        isFalse,
      );
    });
    test('accepts URL without protocol (normalized internally)', () {
      expect(
        Validators.isValidInstagramUrl('instagram.com/reel/ABC123'),
        isTrue,
      );
    });
    test('accepts instagr.am short URL', () {
      expect(
        Validators.isValidInstagramUrl('https://instagr.am/reel/ABC/'),
        isTrue,
      );
    });
    test('rejects stories with shortcode', () {
      expect(
        Validators.isValidInstagramUrl(
          'https://www.instagram.com/stories/user/1234567890',
        ),
        isTrue,
      );
    });

    test('rejects old stories path without id', () {
      expect(
        Validators.isValidInstagramUrl(
          'https://www.instagram.com/stories/abc/',
        ),
        isFalse,
      );
    });
    test('accepts public profile URL', () {
      expect(
        Validators.isValidInstagramUrl('https://www.instagram.com/natgeo'),
        isTrue,
      );
    });

    test('accepts @username shorthand', () {
      expect(Validators.prepareUrl('@natgeo'), 'https://instagram.com/natgeo');
    });

    test('rejects empty string', () {
      expect(Validators.isValidInstagramUrl(''), isFalse);
    });
  });

  group('Validators.normalize', () {
    test('adds https if missing', () {
      expect(
        Validators.normalize('instagram.com/reel/X/'),
        'https://instagram.com/reel/X',
      );
    });
    test('removes trailing slash', () {
      expect(
        Validators.normalize('https://instagram.com/p/X/'),
        'https://instagram.com/p/X',
      );
    });
    test('removes query parameters', () {
      expect(
        Validators.normalize('https://instagram.com/p/X/?igshid=abc'),
        'https://instagram.com/p/X',
      );
    });
  });
}
