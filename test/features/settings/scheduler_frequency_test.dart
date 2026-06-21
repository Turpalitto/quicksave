import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/settings/domain/scheduler_frequency.dart';

void main() {
  group('SchedulerFrequencyValidator', () {
    test('manual is valid', () {
      expect(
        SchedulerFrequencyValidator.validate(SchedulerFrequency.manual),
        isNull,
      );
    });

    test('daily is valid', () {
      expect(
        SchedulerFrequencyValidator.validate(SchedulerFrequency.daily),
        isNull,
      );
    });

    test('interval respects minimum 12h', () {
      expect(
        SchedulerFrequency.every12Hours.interval!.inHours,
        greaterThanOrEqualTo(12),
      );
    });
  });
}
