import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/settings/domain/entitlement.dart';

void main() {
  group('EntitlementTier', () {
    test('free cannot use scheduler', () {
      expect(EntitlementTier.free.canUseScheduler, isFalse);
    });

    test('pro personal can export zip', () {
      expect(EntitlementTier.proPersonal.canExportZip, isTrue);
    });

    test('self-hosted tier has advanced backend', () {
      expect(EntitlementTier.proSelfHosted.canSelfHostAdvanced, isTrue);
    });
  });
}
