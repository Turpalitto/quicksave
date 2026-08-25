import 'dart:math';

import '../core/constants/app_constants.dart';

/// Pro license validation and tier hints.
///
/// License key formats:
/// - Demo (public, review builds only): `QS-PRO-DEMO1`, `QS-PRO-DEMO2026`, `QS-PRO-REVIEW1`
/// - Personal:  `QS-PRO-<PAYLOAD>-CC` where PAYLOAD is `[A-Z0-9]{6,10}`
/// - Self-host: `QS-PRO-SHOST<PAYLOAD>-CC` where PAYLOAD is `[A-Z0-9]{4,10}`
///
/// `CC` is a two-character checksum over the payload (tier salted), so keys
/// cannot be guessed by trying arbitrary suffixes. Issue keys with
/// [generateKey] or `scripts/generate-license-key.mjs`.
class ProService {
  ProService._();
  static final ProService instance = ProService._();

  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Public demo keys (beta / review builds).
  static const demoKeys = {'DEMO1', 'DEMO2026', 'REVIEW1'};

  /// Two-character checksum over [payload], salted per tier.
  static String checksumFor(String payload) {
    final salted = payload.startsWith('SHOST')
        ? 'selfhosted:$payload'
        : 'personal:$payload';
    var h = 5381;
    for (final code in salted.codeUnits) {
      h = ((h * 33) + code) & 0x3FFFFFFF;
    }
    final a = _alphabet[(h >> 5) % _alphabet.length];
    final b = _alphabet[h % _alphabet.length];
    return '$a$b';
  }

  /// Generates a valid license key (owner tooling and tests).
  static String generateKey({bool selfHosted = false, Random? random}) {
    final rng = random ?? Random.secure();
    const bodyLength = 8;
    final payload = selfHosted
        ? 'SHOST${List.generate(bodyLength - 2, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join()}'
        : List.generate(
            bodyLength,
            (_) => _alphabet[rng.nextInt(_alphabet.length)],
          ).join();
    return '${AppConstants.proLicensePrefix}$payload-${checksumFor(payload)}';
  }

  bool validateLicenseKey(String key) {
    final trimmed = key.trim().toUpperCase();
    if (!trimmed.startsWith(AppConstants.proLicensePrefix)) return false;
    final suffix = suffixOf(trimmed);
    if (demoKeys.contains(suffix)) return true;

    // New format: <PAYLOAD>-<CC> with a verified checksum.
    if (suffix.contains('-')) {
      final sep = suffix.lastIndexOf('-');
      if (sep <= 0 || sep == suffix.length - 1) return false;
      final payload = suffix.substring(0, sep);
      final cc = suffix.substring(sep + 1);
      if (!RegExp(r'^(SHOST)?[A-Z0-9]{4,12}$').hasMatch(payload)) return false;
      if (!RegExp(r'^[A-Z0-9]{2}$').hasMatch(cc)) return false;
      return checksumFor(payload) == cc;
    }

    // Legacy format without checksum — no longer accepted for new activations.
    return false;
  }

  bool isDemoKey(String key) {
    final suffix = suffixOf(key.trim().toUpperCase());
    return demoKeys.contains(suffix);
  }

  bool isSelfHostedKey(String key) {
    final trimmed = key.trim().toUpperCase();
    if (isDemoKey(trimmed)) return false;
    final suffix = suffixOf(trimmed);
    if (suffix.startsWith('SHOST')) return true;
    final sep = suffix.lastIndexOf('-');
    final payload = sep > 0 ? suffix.substring(0, sep) : '';
    return payload.startsWith('SHOST');
  }

  String suffixOf(String normalizedKey) {
    if (!normalizedKey.startsWith(AppConstants.proLicensePrefix)) return '';
    return normalizedKey.substring(AppConstants.proLicensePrefix.length);
  }

  /// Last 4 chars for display — never store full key in analytics/logs.
  String licenseHint(String key) {
    final trimmed = key.trim().toUpperCase();
    if (trimmed.length <= 4) return '****';
    return trimmed.substring(trimmed.length - 4);
  }
}
