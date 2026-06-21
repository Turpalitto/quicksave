import '../features/settings/data/entitlement_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/entitlement.dart';
import 'billing/play_billing_service.dart';

/// Bootstraps billing and syncs entitlements into persisted settings.
class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  final PlayBillingService playBilling = PlayBillingService();
  late final EntitlementRepository repository = CompositeEntitlementRepository(
    playBilling: playBilling,
    readIsPro: () async => (await SettingsRepository.instance.get()).isPro,
    writeIsPro: (isPro) async {
      final current = await SettingsRepository.instance.get();
      await SettingsRepository.instance.save(current.copyWith(isPro: isPro));
    },
  );

  EntitlementState _cached = const EntitlementState();

  EntitlementState get current => _cached;

  Future<void> bootstrap() async {
    await playBilling.init();
    await refresh();
  }

  Future<EntitlementState> refresh() async {
    _cached = await repository.getState();
    final settings = await SettingsRepository.instance.get();
    if (settings.isPro != _cached.isPro) {
      await SettingsRepository.instance.save(
        settings.copyWith(isPro: _cached.isPro),
      );
    }
    return _cached;
  }

  Future<void> activateLicense(String key) async {
    await repository.activateLicense(key);
    await refresh();
  }

  Future<void> clearEntitlements() async {
    await repository.clearEntitlements();
    await refresh();
  }
}
