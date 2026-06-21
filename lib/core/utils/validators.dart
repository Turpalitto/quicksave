/// Утилиты для валидации ссылок Instagram.
class Validators {
  Validators._();

  static const _reservedUsernames = {
    'reel', 'reels', 'p', 'tv', 'stories', 'explore', 'accounts', 'direct',
    'about', 'legal', 'developer', 'privacy', 'terms', 'api', 'static',
    'challenge', 'oauth', 'nametag', 'login', 'directory', 'web', 'help',
  };

  static final RegExp _publicPostRe = RegExp(
    r'^https?:\/\/(www\.)?(instagram\.com|instagr\.am)'
    r'\/((reel|p|tv)\/[A-Za-z0-9_\-]+|stories\/[^/]+\/\d+|stories\/highlights\/\d+)$',
    caseSensitive: false,
  );

  static final RegExp _profileRe = RegExp(
    r'^https?:\/\/(www\.)?instagram\.com\/([A-Za-z0-9._]+)$',
    caseSensitive: false,
  );

  static final RegExp _extractRe = RegExp(
    r'(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am|instagr\.com)'
    r'\/(?:video\/|share\/|reels\/)?(reel|p|tv)\/[A-Za-z0-9_\-]+\/?'
    r'|(https?:\/\/)?(www\.)?instagram\.com\/stories\/[^/\s]+\/\d+\/?'
    r'|(https?:\/\/)?(www\.)?instagram\.com\/stories\/highlights\/\d+\/?'
    r'|(https?:\/\/)?(www\.)?instagram\.com\/[A-Za-z0-9._]+\/?',
    caseSensitive: false,
  );

  static String? extractInstagramUrl(String text) {
    if (text.isEmpty) return null;
    final trimmed = text.trim();
    if (trimmed.startsWith('@') && trimmed.length > 1) {
      final user = trimmed.substring(1).split(RegExp(r'\s')).first;
      if (_isValidUsername(user)) {
        return 'https://instagram.com/$user';
      }
    }
    final match = _extractRe.firstMatch(trimmed);
    return match?.group(0);
  }

  static bool _isValidUsername(String username) {
    if (username.isEmpty || username.length > 30) return false;
    if (_reservedUsernames.contains(username.toLowerCase())) return false;
    return RegExp(r'^[A-Za-z0-9._]+$').hasMatch(username);
  }

  static bool isProfileUrl(String url) {
    final normalized = normalize(url);
    final m = _profileRe.firstMatch(normalized);
    if (m == null) return false;
    return _isValidUsername(m.group(2)!);
  }

  static bool isValidInstagramUrl(String url) {
    if (url.isEmpty) return false;
    final normalized = normalize(url);
    if (isProfileUrl(normalized)) return true;
    return _publicPostRe.hasMatch(normalized);
  }

  static String normalize(String url) {
    var result = url.trim();
    if (result.startsWith('@') && result.length > 1) {
      result = 'https://instagram.com/${result.substring(1).split(RegExp(r'\s')).first}';
    }
    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      result = 'https://$result';
    }

    result = result.replaceAllMapped(
      RegExp(r'//(www\.)?instagr\.com/', caseSensitive: false),
      (m) => '//${m.group(1) ?? ''}instagram.com/',
    );

    final frag = result.indexOf('#');
    if (frag >= 0) result = result.substring(0, frag);
    final query = result.indexOf('?');
    if (query >= 0) result = result.substring(0, query);

    result = result.replaceAllMapped(
      RegExp(
        r'instagram\.com/(?:video/|share/)?(reels|reel|p|tv)/',
        caseSensitive: false,
      ),
      (m) => 'instagram.com/${m[1]}/',
    );
    result = result.replaceAll(
      RegExp(r'instagram\.com/reels/', caseSensitive: false),
      'instagram.com/reel/',
    );
    result = result.replaceAllMapped(
      RegExp(
        r'instagr\.am/(?:video/|share/)?(reels|reel|p|tv)/',
        caseSensitive: false,
      ),
      (m) => 'instagr.am/${m[1]}/',
    );
    result = result.replaceAll(
      RegExp(r'instagr\.am/reels/', caseSensitive: false),
      'instagr.am/reel/',
    );
    result = result.replaceAllMapped(
      RegExp(r'instagram\.com/stories/([^/]+)/(\d+)/.+', caseSensitive: false),
      (m) => 'instagram.com/stories/${m[1]}/${m[2]}',
    );

    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String? prepareUrl(String raw) {
    final extracted = extractInstagramUrl(raw) ?? raw.trim();
    if (extracted.isEmpty) return null;
    final normalized = normalize(extracted);
    return isValidInstagramUrl(normalized) ? normalized : null;
  }
}
