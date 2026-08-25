import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/services/pro_service.dart';

void main() {
  group('ProService', () {
    test('accepts generated personal license format', () {
      final key = ProService.generateKey();
      expect(key.startsWith('QS-PRO-'), isTrue);
      expect(ProService.instance.validateLicenseKey(key), isTrue);
      expect(ProService.instance.isSelfHostedKey(key), isFalse);
    });

    test('accepts generated self-hosted license format', () {
      final key = ProService.generateKey(selfHosted: true);
      expect(ProService.instance.validateLicenseKey(key), isTrue);
      expect(ProService.instance.isSelfHostedKey(key), isTrue);
    });

    test('checksum is deterministic', () {
      expect(
        ProService.checksumFor('ABCD1234'),
        ProService.checksumFor('ABCD1234'),
      );
      expect(
        ProService.checksumFor('SHOSTAB12'),
        isNot(ProService.checksumFor('AB12SHOST')),
      );
    });

    test('rejects tampered checksum', () {
      final key = ProService.generateKey();
      final tampered = '${key.substring(0, key.length - 2)}ZZ';
      expect(ProService.instance.validateLicenseKey(tampered), isFalse);
    });

    test('rejects legacy keys without checksum', () {
      expect(
        ProService.instance.validateLicenseKey('QS-PRO-ABCD1234'),
        isFalse,
      );
    });

    test('accepts demo keys', () {
      expect(ProService.instance.validateLicenseKey('QS-PRO-DEMO1'), isTrue);
      expect(ProService.instance.validateLicenseKey('qs-pro-demo2026'), isTrue);
      expect(ProService.instance.isDemoKey('QS-PRO-REVIEW1'), isTrue);
    });

    test('demo keys are never treated as self-hosted', () {
      expect(ProService.instance.isSelfHostedKey('QS-PRO-DEMO1'), isFalse);
    });

    test('rejects invalid keys', () {
      expect(ProService.instance.validateLicenseKey(''), isFalse);
      expect(ProService.instance.validateLicenseKey('PRO-1234'), isFalse);
      expect(ProService.instance.validateLicenseKey('QS-PRO-!!'), isFalse);
      expect(ProService.instance.validateLicenseKey('QS-PRO-A1B2C3-'), isFalse);
    });
  });
}
