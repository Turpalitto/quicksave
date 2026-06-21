import 'package:intl/intl.dart';

/// Форматирует размер файла в человекочитаемый вид.
String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = ['Б', 'КБ', 'МБ', 'ГБ'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// Форматирует длительность (секунды) в mm:ss.
String formatDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '—';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Форматирует дату.
String formatDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

/// Прогресс 0..1 → строка "45%".
String formatPercent(double p) {
  return '${(p * 100).clamp(0, 100).toStringAsFixed(0)}%';
}
