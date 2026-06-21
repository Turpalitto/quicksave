import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/utils/formatters.dart';

void main() {
  group('formatBytes', () {
    test('returns dash for null', () {
      expect(formatBytes(null), '—');
    });
    test('returns dash for zero', () {
      expect(formatBytes(0), '—');
    });
    test('formats bytes', () {
      expect(formatBytes(512), '512 Б');
    });
    test('formats kilobytes', () {
      expect(formatBytes(2048), '2.0 КБ');
    });
    test('formats megabytes', () {
      expect(formatBytes(5 * 1024 * 1024), '5.0 МБ');
    });
    test('formats gigabytes', () {
      expect(formatBytes(2 * 1024 * 1024 * 1024), '2.0 ГБ');
    });
  });

  group('formatDuration', () {
    test('returns dash for null', () {
      expect(formatDuration(null), '—');
    });
    test('returns dash for zero', () {
      expect(formatDuration(0), '—');
    });
    test('formats short duration', () {
      expect(formatDuration(45), '00:45');
    });
    test('formats long duration', () {
      expect(formatDuration(125), '02:05');
    });
  });

  group('formatPercent', () {
    test('0% for 0', () {
      expect(formatPercent(0), '0%');
    });
    test('50% for 0.5', () {
      expect(formatPercent(0.5), '50%');
    });
    test('rounds to integer', () {
      expect(formatPercent(0.456), '46%');
    });
    test('clamps to 100', () {
      expect(formatPercent(1.5), '100%');
    });
  });
}
