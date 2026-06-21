// Базовая проверка smoke-test.
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  test('mocks initialized', () {
    expect(true, isTrue);
  });
}
