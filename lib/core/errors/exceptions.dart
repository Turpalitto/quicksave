/// Исключения нижнего слоя (data/services).
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Нет интернета.
class NoInternetException extends AppException {
  const NoInternetException()
      : super('Нет подключения к интернету. Проверьте сеть.');
}

/// Ссылка не похожа на Instagram.
class InvalidUrlException extends AppException {
  const InvalidUrlException()
      : super('Ссылка не похожа на публичный Instagram-пост.');
}

/// Пост приватный или требует авторизации.
class PrivatePostException extends AppException {
  const PrivatePostException()
      : super('Пост приватный или требует входа в Instagram.');
}

/// Пост не найден (удалён или неверная ссылка).
class NotFoundPostException extends AppException {
  const NotFoundPostException()
      : super('Пост не найден. Проверьте ссылку или удалите её из истории.');
}

/// Не удалось получить прямую ссылку.
class ResolverException extends AppException {
  const ResolverException()
      : super('Не удалось получить прямую ссылку. '
            'Попробуйте другой публичный пост.');
}

/// Backend недоступен / ошибка 5xx.
class ServerException extends AppException {
  const ServerException([String? message])
      : super(message ?? 'Ошибка сервера. Попробуйте позже.');
}

/// Превышён rate limit бэкенда (429).
class RateLimitedException extends AppException {
  const RateLimitedException()
      : super('Слишком много запросов. Подождите минуту и попробуйте снова.');
}

/// Недостаточно места на устройстве.
class NoSpaceException extends AppException {
  const NoSpaceException()
      : super('Недостаточно места на устройстве.');
}

/// Ошибка записи файла.
class FileWriteException extends AppException {
  const FileWriteException()
      : super('Не удалось сохранить файл на устройство.');
}

/// Отмена пользователем.
class DownloadCancelledException extends AppException {
  const DownloadCancelledException()
      : super('Скачивание отменено.');
}

/// Неизвестная ошибка.
class UnknownException extends AppException {
  const UnknownException([String? message])
      : super(message ?? 'Неизвестная ошибка.');
}
