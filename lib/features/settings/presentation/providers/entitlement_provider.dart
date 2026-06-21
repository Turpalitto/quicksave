import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../services/billing/play_billing_service.dart';
import '../../../../services/entitlement_service.dart';
import '../../domain/entitlement.dart';

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier() : super(EntitlementService.instance.current) {
    _sync();
  }

  PlayBillingService get _billing => EntitlementService.instance.playBilling;

  Future<void> _sync() async {
    state = await EntitlementService.instance.refresh();
  }

  Future<void> refresh() => _sync();

  Future<bool> purchasePro() async {
    final product = _billing.preferredProduct;
    if (product == null) return false;
    final started = await _billing.purchase(product);
    if (started) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _sync();
    }
    return started;
  }

  Future<void> restorePurchases() async {
    await _billing.restorePurchases();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _sync();
  }

  Future<void> activateLicense(String key) async {
    await EntitlementService.instance.activateLicense(key);
    state = EntitlementService.instance.current;
  }

  Future<void> clearEntitlements() async {
    await EntitlementService.instance.clearEntitlements();
    state = EntitlementService.instance.current;
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, EntitlementState>(
      (ref) => EntitlementNotifier(),
    );

final playBillingProductsProvider = Provider<List<ProductDetails>>((ref) {
  ref.watch(entitlementProvider);
  return EntitlementService.instance.playBilling.products;
});

final playBillingAvailableProvider = Provider<bool>((ref) {
  ref.watch(entitlementProvider);
  return EntitlementService.instance.playBilling.canBill;
});
