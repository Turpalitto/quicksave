import 'exceptions.dart';

/// Failure — результат ошибки для presentation слоя.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NoInternetFailure extends Failure {
  const NoInternetFailure() : super('Нет подключения к интернету.');
}

class InvalidUrlFailure extends Failure {
  const InvalidUrlFailure() : super('Неверная ссылка Instagram.');
}

class PrivatePostFailure extends Failure {
  const PrivatePostFailure()
      : super('Пост приватный или требует входа в Instagram.');
}

class NotFoundPostFailure extends Failure {
  const NotFoundPostFailure()
      : super('Пост не найден. Проверьте ссылку.');
}

class ResolverFailure extends Failure {
  const ResolverFailure()
      : super('Не удалось получить прямую ссылку. '
            'Попробуйте другой публичный пост.');
}

class ServerFailure extends Failure {
  const ServerFailure([String? message])
      : super(message ?? 'Ошибка сервера. Попробуйте позже.');
}

class RateLimitedFailure extends Failure {
  const RateLimitedFailure()
      : super('Слишком много запросов. Подождите минуту.');
}

class NoSpaceFailure extends Failure {
  const NoSpaceFailure() : super('Недостаточно места на устройстве.');
}

class FileWriteFailure extends Failure {
  const FileWriteFailure() : super('Не удалось сохранить файл.');
}

class CancelledFailure extends Failure {
  const CancelledFailure() : super('Скачивание отменено.');
}

class UnknownFailure extends Failure {
  const UnknownFailure([String? message])
      : super(message ?? 'Неизвестная ошибка.');
}

/// Маппер исключений в Failure для presentation.
Failure mapExceptionToFailure(AppException ex) {
  if (ex is NoInternetException) return const NoInternetFailure();
  if (ex is InvalidUrlException) return const InvalidUrlFailure();
  if (ex is PrivatePostException) return const PrivatePostFailure();
  if (ex is NotFoundPostException) return const NotFoundPostFailure();
  if (ex is ResolverException) return const ResolverFailure();
  if (ex is ServerException) return ServerFailure(ex.message);
  if (ex is RateLimitedException) return const RateLimitedFailure();
  if (ex is NoSpaceException) return const NoSpaceFailure();
  if (ex is FileWriteException) return const FileWriteFailure();
  if (ex is DownloadCancelledException) return const CancelledFailure();
  return UnknownFailure(ex.message);
}
