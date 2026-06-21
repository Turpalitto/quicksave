import '../../../services/billing/billing_constants.dart';
import '../../../services/billing/billing_storage.dart';
import '../../../services/billing/play_billing_service.dart';
import '../../../services/pro_service.dart';
import '../domain/entitlement.dart';

/// Resolves current product entitlements.
abstract class EntitlementRepository {
  Future<EntitlementState> getState();
  Future<void> activateLicense(String key);
  Future<void> clearEntitlements();
}

/// Play Billing + local license keys (demo and self-hosted).
class CompositeEntitlementRepository implements EntitlementRepository {
  CompositeEntitlementRepository({
    required this.playBilling,
    required this.readIsPro,
    required this.writeIsPro,
    ProService? proService,
  }) : _pro = proService ?? ProService.instance;

  final PlayBillingService playBilling;
  final Future<bool> Function() readIsPro;
  final Future<void> Function(bool isPro) writeIsPro;
  final ProService _pro;

  @override
  Future<EntitlementState> getState() async {
    if (playBilling.playActive ||
        await BillingStorage.instance.readPlayActive()) {
      return const EntitlementState(
        tier: EntitlementTier.proPersonal,
        isDemoMode: false,
        billingSource: EntitlementBillingSource.googlePlay,
      );
    }

    final isPro = await readIsPro();
    if (!isPro) {
      return const EntitlementState(tier: EntitlementTier.free);
    }

    final hint = await BillingStorage.instance.readLicenseHint();
    final source = await BillingStorage.instance.readSource();
    final storedTier = await BillingStorage.instance.readLicenseTier();
    final isDemo = await BillingStorage.instance.readLicenseIsDemo();

    if (source == BillingSource.license) {
      final tier = storedTier == 'selfHosted'
          ? EntitlementTier.proSelfHosted
          : EntitlementTier.proPersonal;
      return EntitlementState(
        tier: tier,
        isDemoMode: isDemo,
        licenseKeyHint: hint,
        billingSource: EntitlementBillingSource.licenseKey,
      );
    }

    return EntitlementState(
      tier: EntitlementTier.proPersonal,
      isDemoMode: isDemo,
      licenseKeyHint: hint,
      billingSource: EntitlementBillingSource.licenseKey,
    );
  }

  @override
  Future<void> activateLicense(String key) async {
    if (!_pro.validateLicenseKey(key)) {
      throw ArgumentError('invalid_license');
    }
    await writeIsPro(true);
    await BillingStorage.instance.writeSource(BillingSource.license);
    await BillingStorage.instance.writeLicenseHint(_pro.licenseHint(key));
    final tier = _pro.isSelfHostedKey(key) ? 'selfHosted' : 'personal';
    await BillingStorage.instance.writeLicenseTier(tier);
    await BillingStorage.instance.writeLicenseIsDemo(_pro.isDemoKey(key));
  }

  @override
  Future<void> clearEntitlements() async {
    await writeIsPro(false);
    await BillingStorage.instance.clearAll();
    playBilling.playActive = false;
  }
}

/// Legacy alias kept for tests.
class LocalDemoEntitlementRepository implements EntitlementRepository {
  LocalDemoEntitlementRepository({
    required this.validateKey,
    required this.readIsPro,
    required this.writeIsPro,
  });

  final bool Function(String key) validateKey;
  final Future<bool> Function() readIsPro;
  final Future<void> Function(bool isPro) writeIsPro;

  @override
  Future<EntitlementState> getState() async {
    final isPro = await readIsPro();
    if (!isPro) {
      return const EntitlementState(
        tier: EntitlementTier.free,
        isDemoMode: true,
      );
    }
    return const EntitlementState(
      tier: EntitlementTier.proPersonal,
      isDemoMode: true,
      billingSource: EntitlementBillingSource.licenseKey,
    );
  }

  @override
  Future<void> activateLicense(String key) async {
    if (!validateKey(key)) throw ArgumentError('invalid_license');
    await writeIsPro(true);
  }

  @override
  Future<void> clearEntitlements() async {
    await writeIsPro(false);
  }
}
