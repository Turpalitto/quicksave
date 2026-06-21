import 'dart:convert';

import '../storage_service.dart';
import 'billing_constants.dart';

/// Local persistence for billing state (no purchase tokens in logs).
class BillingStorage {
  BillingStorage._();
  static final BillingStorage instance = BillingStorage._();

  Future<Map<String, dynamic>> _read() async {
    final raw = StorageService.instance.prefs.getString(
      BillingConstants.billingPrefsKey,
    );
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> data) async {
    await StorageService.instance.prefs.setString(
      BillingConstants.billingPrefsKey,
      jsonEncode(data),
    );
  }

  Future<bool> readPlayActive() async {
    final data = await _read();
    return data['playActive'] as bool? ?? false;
  }

  Future<void> writePlayActive(bool active) async {
    final data = await _read();
    data['playActive'] = active;
    if (active) {
      data['source'] = BillingSource.play.name;
    } else if (data['source'] == BillingSource.play.name) {
      data['source'] = BillingSource.none.name;
    }
    await _write(data);
  }

  Future<BillingSource> readSource() async {
    final data = await _read();
    final raw = data['source'] as String?;
    switch (raw) {
      case 'play':
        return BillingSource.play;
      case 'license':
        return BillingSource.license;
      default:
        return BillingSource.none;
    }
  }

  Future<void> writeSource(BillingSource source) async {
    final data = await _read();
    data['source'] = source.name;
    await _write(data);
  }

  Future<String?> readLicenseHint() async {
    final data = await _read();
    return data['licenseHint'] as String?;
  }

  Future<void> writeLicenseHint(String? hint) async {
    final data = await _read();
    if (hint == null || hint.isEmpty) {
      data.remove('licenseHint');
    } else {
      data['licenseHint'] = hint;
    }
    await _write(data);
  }

  Future<String?> readLicenseTier() async {
    final data = await _read();
    return data['licenseTier'] as String?;
  }

  Future<void> writeLicenseTier(String? tier) async {
    final data = await _read();
    if (tier == null || tier.isEmpty) {
      data.remove('licenseTier');
    } else {
      data['licenseTier'] = tier;
    }
    await _write(data);
  }

  Future<bool> readLicenseIsDemo() async {
    final data = await _read();
    return data['licenseIsDemo'] as bool? ?? false;
  }

  Future<void> writeLicenseIsDemo(bool value) async {
    final data = await _read();
    data['licenseIsDemo'] = value;
    await _write(data);
  }

  Future<void> clearPlay() async {
    final data = await _read();
    data['playActive'] = false;
    if (data['source'] == BillingSource.play.name) {
      data['source'] = BillingSource.none.name;
    }
    await _write(data);
  }

  Future<void> clearAll() async {
    await StorageService.instance.prefs.remove(BillingConstants.billingPrefsKey);
  }
}
