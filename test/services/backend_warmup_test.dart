import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/constants/app_constants.dart';
import 'package:quicksave/core/network/backend_warmup.dart';

void main() {
  group('backendNeedsWarmUp', () {
    test('detects Render free tier host', () {
      expect(
        backendNeedsWarmUp('https://quicksave-api.onrender.com'),
        isTrue,
      );
    });

    test('local and LAN hosts skip warm-up', () {
      expect(backendNeedsWarmUp('http://10.0.2.2:3000'), isFalse);
      expect(backendNeedsWarmUp('http://192.168.1.5:3000'), isFalse);
    });
  });

  group('backendResolveMaxAttempts', () {
    test('hosted PaaS gets 3 attempts', () {
      expect(
        backendResolveMaxAttempts('https://quicksave-api.onrender.com'),
        3,
      );
    });

    test('self-hosted gets single attempt', () {
      expect(backendResolveMaxAttempts('http://localhost:3000'), 1);
    });
  });

  group('backendResolveOverallTimeout', () {
    test('hosted PaaS capped at 90 seconds', () {
      expect(
        backendResolveOverallTimeout('https://quicksave-api.onrender.com'),
        const Duration(seconds: 90),
      );
    });

    test('self-hosted uses network timeout', () {
      expect(
        backendResolveOverallTimeout('http://10.0.2.2:3000'),
        AppConstants.networkTimeout,
      );
    });
  });
}
