import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/settings/data/entitlement_repository.dart';
import 'package:quicksave/features/settings/domain/entitlement.dart';
import 'package:quicksave/services/billing/billing_constants.dart';
import 'package:quicksave/services/billing/billing_storage.dart';
import 'package:quicksave/services/billing/play_billing_service.dart';

import '../../helpers/mock_setup.dart';

void main() {
  setUp(() async {
    await initPlatformMocks();
    await BillingStorage.instance.clearAll();
  });

  group('CompositeEntitlementRepository', () {
    test('returns free when no play or license', () async {
      final play = PlayBillingService();
      play.playActive = false;
      var isPro = false;

      final repo = CompositeEntitlementRepository(
        playBilling: play,
        readIsPro: () async => isPro,
        writeIsPro: (v) async => isPro = v,
      );

      final state = await repo.getState();
      expect(state.tier, EntitlementTier.free);
      expect(state.isPro, isFalse);
    });

    test('play subscription unlocks pro personal', () async {
      final play = PlayBillingService();
      play.playActive = true;

      final repo = CompositeEntitlementRepository(
        playBilling: play,
        readIsPro: () async => false,
        writeIsPro: (_) async {},
      );

      final state = await repo.getState();
      expect(state.tier, EntitlementTier.proPersonal);
      expect(state.billingSource, EntitlementBillingSource.googlePlay);
    });

    test('license activation stores tier and demo flag', () async {
      final play = PlayBillingService();
      var isPro = false;

      final repo = CompositeEntitlementRepository(
        playBilling: play,
        readIsPro: () async => isPro,
        writeIsPro: (v) async => isPro = v,
      );

      await repo.activateLicense('QS-PRO-DEMO1');
      final state = await repo.getState();

      expect(state.isPro, isTrue);
      expect(state.isDemoMode, isTrue);
      expect(state.billingSource, EntitlementBillingSource.licenseKey);
      expect(await BillingStorage.instance.readSource(), BillingSource.license);
    });

    test('self-hosted license tier', () async {
      final play = PlayBillingService();
      var isPro = false;

      final repo = CompositeEntitlementRepository(
        playBilling: play,
        readIsPro: () async => isPro,
        writeIsPro: (v) async => isPro = v,
      );

      await repo.activateLicense('QS-PRO-SHOST1234');
      final state = await repo.getState();
      expect(state.tier, EntitlementTier.proSelfHosted);
    });
  });
}
