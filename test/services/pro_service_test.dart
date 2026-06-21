import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/services/pro_service.dart';

void main() {
  group('ProService', () {
    test('accepts valid license format', () {
      expect(ProService.instance.validateLicenseKey('QS-PRO-ABCD1234'), isTrue);
    });

    test('accepts demo keys', () {
      expect(ProService.instance.validateLicenseKey('QS-PRO-DEMO1'), isTrue);
      expect(ProService.instance.validateLicenseKey('qs-pro-demo2026'), isTrue);
    });

    test('rejects invalid keys', () {
      expect(ProService.instance.validateLicenseKey(''), isFalse);
      expect(ProService.instance.validateLicenseKey('PRO-1234'), isFalse);
      expect(ProService.instance.validateLicenseKey('QS-PRO-!!'), isFalse);
    });
  });
}
