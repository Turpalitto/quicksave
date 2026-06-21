/// Filename template presets for saved media.
enum FilenameTemplatePreset { defaultTemplate, dateFirst, folderStyle, custom }

/// Builds safe Android filenames from a template.
class FilenameTemplateEngine {
  FilenameTemplateEngine._();

  static final invalidChars = RegExp(r'[\\/:*?"<>|]');

  static String sanitizeSegment(String input) {
    var s = input.trim();
    if (s.isEmpty) return 'unknown';
    s = s.replaceAll(invalidChars, '_');
    s = s.replaceAll(RegExp(r'\s+'), '_');
    if (s.length > 64) s = s.substring(0, 64);
    return s;
  }

  static String presetTemplate(FilenameTemplatePreset preset) {
    switch (preset) {
      case FilenameTemplatePreset.defaultTemplate:
        return '{username}_{type}_{shortcode}_{date}';
      case FilenameTemplatePreset.dateFirst:
        return '{date}_{username}_{shortcode}';
      case FilenameTemplatePreset.folderStyle:
        return '{username}/{type}/{shortcode}';
      case FilenameTemplatePreset.custom:
        return '{username}_{type}_{shortcode}_{date}';
    }
  }

  static String apply({
    required String template,
    required String username,
    required String type,
    required String shortcode,
    required DateTime date,
    String extension = 'mp4',
  }) {
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    var result = template
        .replaceAll('{username}', sanitizeSegment(username))
        .replaceAll('{type}', sanitizeSegment(type))
        .replaceAll('{shortcode}', sanitizeSegment(shortcode))
        .replaceAll('{date}', dateStr);

    if (result.contains('/')) {
      final parts = result.split('/').map(sanitizeSegment).toList();
      result = parts.join('/');
    } else {
      result = sanitizeSegment(result.replaceAll('/', '_'));
    }

    if (!result.toLowerCase().endsWith('.$extension')) {
      result = '$result.$extension';
    }
    return result;
  }

  static String? validateTemplate(String template) {
    if (template.trim().isEmpty) return 'empty_template';
    if (invalidChars.hasMatch(template.replaceAll('/', ''))) {
      return 'invalid_characters';
    }
    return null;
  }

  static String preview({
    FilenameTemplatePreset preset = FilenameTemplatePreset.defaultTemplate,
    String? customTemplate,
  }) {
    final tpl = preset == FilenameTemplatePreset.custom
        ? (customTemplate ?? presetTemplate(preset))
        : presetTemplate(preset);
    return apply(
      template: tpl,
      username: 'creator',
      type: 'reel',
      shortcode: 'ABC123',
      date: DateTime(2026, 6, 21),
      extension: 'mp4',
    );
  }
}
