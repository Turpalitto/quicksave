/// Watchlist check frequency (minimum intervals enforced).
enum SchedulerFrequency {
  manual,
  every12Hours,
  daily,
  weekly;

  String get storageValue => name;

  static SchedulerFrequency fromString(String? raw) {
    switch (raw) {
      case 'every12Hours':
        return SchedulerFrequency.every12Hours;
      case 'daily':
        return SchedulerFrequency.daily;
      case 'weekly':
        return SchedulerFrequency.weekly;
      default:
        return SchedulerFrequency.manual;
    }
  }
}

extension SchedulerFrequencyDuration on SchedulerFrequency {
  Duration? get interval {
    switch (this) {
      case SchedulerFrequency.manual:
        return null;
      case SchedulerFrequency.every12Hours:
        return const Duration(hours: 12);
      case SchedulerFrequency.daily:
        return const Duration(hours: 24);
      case SchedulerFrequency.weekly:
        return const Duration(days: 7);
    }
  }
}

class SchedulerFrequencyValidator {
  SchedulerFrequencyValidator._();

  /// Rejects frequencies shorter than 12 hours (privacy + rate-limit safety).
  static String? validate(SchedulerFrequency frequency) {
    final interval = frequency.interval;
    if (interval == null) return null;
    if (interval.inHours < 12) {
      return 'frequency_too_aggressive';
    }
    return null;
  }
}
