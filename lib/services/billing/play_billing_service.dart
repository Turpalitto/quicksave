import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_constants.dart';
import 'billing_storage.dart';
import 'remote_billing_validator.dart';

/// Google Play Billing integration for Pro subscriptions.
class PlayBillingService {
  PlayBillingService({InAppPurchase? store}) : _storeOverride = store;

  final InAppPurchase? _storeOverride;
  InAppPurchase? _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool storeAvailable = false;
  bool playActive = false;
  List<ProductDetails> products = [];
  String? lastErrorCode;

  bool get canBill => Platform.isAndroid && storeAvailable;

  InAppPurchase? get _iap {
    if (!Platform.isAndroid) return null;
    return _store ??= _storeOverride ?? InAppPurchase.instance;
  }

  Future<void> init() async {
    if (!Platform.isAndroid) return;
    final store = _iap;
    if (store == null) return;

    try {
      storeAvailable = await store.isAvailable();
    } catch (_) {
      storeAvailable = false;
    }
    if (!storeAvailable) return;

    playActive = await BillingStorage.instance.readPlayActive();

    _purchaseSub ??= store.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );

    await _loadProducts();
    await restorePurchases(silent: true);
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
  }

  Future<void> _loadProducts() async {
    final store = _iap;
    if (!storeAvailable || store == null) return;
    final response = await store.queryProductDetails(
      BillingConstants.proProductIds,
    );
    if (response.error != null) {
      lastErrorCode = response.error!.code;
      return;
    }
    products = response.productDetails.toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  ProductDetails? get preferredProduct {
    if (products.isEmpty) return null;
    return products.firstWhere(
      (p) => p.id == BillingConstants.proPersonalYearly,
      orElse: () => products.first,
    );
  }

  Future<bool> purchase(ProductDetails product) async {
    final store = _iap;
    if (!storeAvailable || store == null) return false;
    lastErrorCode = null;
    final param = PurchaseParam(productDetails: product);
    return store.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases({bool silent = false}) async {
    final store = _iap;
    if (!storeAvailable || store == null) return;
    if (!silent) lastErrorCode = null;
    await store.restorePurchases();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    var active = playActive;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _validatePurchase(purchase);
          if (ok) active = true;
          if (purchase.pendingCompletePurchase) {
            await _iap?.completePurchase(purchase);
          }
        case PurchaseStatus.error:
          lastErrorCode = purchase.error?.code ?? 'purchase_error';
        case PurchaseStatus.canceled:
          lastErrorCode = 'purchase_canceled';
      }
    }

    if (active != playActive) {
      playActive = active;
      await BillingStorage.instance.writePlayActive(active);
    }
  }

  Future<bool> _validatePurchase(PurchaseDetails purchase) async {
    if (!BillingConstants.proProductIds.contains(purchase.productID)) {
      return false;
    }

    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return false;

    final backend = await RemoteBillingValidator.instance.effectiveBackendUrl();
    return RemoteBillingValidator.instance.verifyPlayPurchase(
      productId: purchase.productID,
      purchaseToken: token,
      packageName: purchase.verificationData.source,
      backendUrl: backend,
    );
  }
}
