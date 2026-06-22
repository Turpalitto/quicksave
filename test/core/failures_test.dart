import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/errors/exceptions.dart';
import 'package:quicksave/core/errors/failures.dart';

void main() {
  test('BackendUnreachableException maps to BackendUnreachableFailure', () {
    final failure = mapExceptionToFailure(const BackendUnreachableException());
    expect(failure, isA<BackendUnreachableFailure>());
    expect(failure.message, contains('Сервер QuickSave'));
  });
}
