import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/errors/exceptions.dart';
import 'package:quicksave/core/errors/failures.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('NoInternetException → NoInternetFailure', () {
      expect(
        mapExceptionToFailure(const NoInternetException()),
        isA<NoInternetFailure>(),
      );
    });
    test('InvalidUrlException → InvalidUrlFailure', () {
      expect(
        mapExceptionToFailure(const InvalidUrlException()),
        isA<InvalidUrlFailure>(),
      );
    });
    test('PrivatePostException → PrivatePostFailure', () {
      expect(
        mapExceptionToFailure(const PrivatePostException()),
        isA<PrivatePostFailure>(),
      );
    });
    test('NotFoundPostException → NotFoundPostFailure', () {
      expect(
        mapExceptionToFailure(const NotFoundPostException()),
        isA<NotFoundPostFailure>(),
      );
    });
    test('ResolverException → ResolverFailure', () {
      expect(
        mapExceptionToFailure(const ResolverException()),
        isA<ResolverFailure>(),
      );
    });
    test('ServerException → ServerFailure', () {
      final f = mapExceptionToFailure(const ServerException('oops'));
      expect(f, isA<ServerFailure>());
      expect(f.message, 'oops');
    });
    test('RateLimitedException → RateLimitedFailure', () {
      expect(
        mapExceptionToFailure(const RateLimitedException()),
        isA<RateLimitedFailure>(),
      );
    });
    test('NoSpaceException → NoSpaceFailure', () {
      expect(
        mapExceptionToFailure(const NoSpaceException()),
        isA<NoSpaceFailure>(),
      );
    });
    test('FileWriteException → FileWriteFailure', () {
      expect(
        mapExceptionToFailure(const FileWriteException()),
        isA<FileWriteFailure>(),
      );
    });
    test('DownloadCancelledException → CancelledFailure', () {
      expect(
        mapExceptionToFailure(const DownloadCancelledException()),
        isA<CancelledFailure>(),
      );
    });
    test('Unknown → UnknownFailure', () {
      final f = mapExceptionToFailure(const UnknownException('x'));
      expect(f, isA<UnknownFailure>());
      expect(f.message, 'x');
    });
  });

  group('Exceptions have messages', () {
    test('every exception has a non-empty message', () {
      const exceptions = <AppException>[
        NoInternetException(),
        InvalidUrlException(),
        PrivatePostException(),
        NotFoundPostException(),
        ResolverException(),
        ServerException(),
        RateLimitedException(),
        NoSpaceException(),
        FileWriteException(),
        DownloadCancelledException(),
        UnknownException(),
      ];
      for (final e in exceptions) {
        expect(e.message, isNotEmpty);
      }
    });
  });
}
