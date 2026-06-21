import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import 'foreground_service.dart';

typedef ProgressCallback = void Function(double progress);

/// Сервис скачивания файлов.
///
/// Возможности:
///   • Скачивание через Dio с прогрессом.
///   • Возобновление прерванной загрузки через HTTP Range header.
///   • Сохранение в app-specific external dir (без runtime-разрешений).
///   • Отмена через CancelToken.
///   • Устойчивость к обрывам связи (файл .part сохраняется).
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
      followRedirects: true,
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  CancelToken? _activeToken;

  /// Скачивает файл по [url]. Возвращает путь к сохранённому файлу.
  ///
  /// Если файл с таким именем уже существует (или есть .part),
  /// пытается возобновить загрузку с места обрыва.
  Future<String> download({
    required String url,
    required String fileName,
    String? subfolder,
    ProgressCallback? onProgress,
    bool resume = true,
  }) async {
    if (url.isEmpty) {
      throw const InvalidUrlException();
    }

    final dir = await _resolveDownloadDir(subfolder: subfolder);

    // Найти имя без коллизий.
    var target = '${dir.path}${Platform.pathSeparator}$fileName';
    var part = '$target.part';
    var i = 1;
    while (File(target).existsSync() || File(part).existsSync()) {
      // Если файл уже полностью скачан — вернуть его.
      if (File(target).existsSync()) {
        return target;
      }
      final ext = _extension(fileName);
      final base = _basename(fileName);
      final suffix = '_$i';
      target =
          '${dir.path}${Platform.pathSeparator}$base$suffix${ext.isEmpty ? '' : '.$ext'}';
      part = '$target.part';
      i++;
    }

    // Попытка возобновить.
    int existingBytes = 0;
    if (resume && File(part).existsSync()) {
      existingBytes = await File(part).length();
    }

    final cancelToken = CancelToken();
    _activeToken = cancelToken;

    // Foreground-сервис держит процесс живым во время длительной загрузки.
    // Ошибки платформы проглатываются внутри — скачивание продолжится и без него.
    await ForegroundService.instance.start();
    var lastFgPercent = -1;

    try {
      await _dio.download(
        url,
        part,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 400,
          headers: {
            if (existingBytes > 0) 'Range': 'bytes=$existingBytes-',
            if (_isInstagramCdn(url)) ...{
              'Referer': 'https://www.instagram.com/',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
            },
          },
        ),
        onReceiveProgress: (received, total) {
          if (onProgress == null) return;
          final totalBytes = total > 0 ? total + existingBytes : 0;
          final downloaded = received + existingBytes;
          if (totalBytes > 0) {
            final ratio = downloaded / totalBytes;
            onProgress(ratio);
            // Троттлинг обновления foreground-уведомления — только при изменении
            // целого процента, чтобы не спамить MethodChannel на каждый чих.
            final percent = (ratio.clamp(0.0, 1.0) * 100).round();
            if (percent != lastFgPercent) {
              lastFgPercent = percent;
              ForegroundService.instance.updateProgress(ratio);
            }
          } else {
            onProgress(0);
          }
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        try {
          await File(part).delete();
        } catch (_) {}
        throw const DownloadCancelledException();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Сохраняем .part для возобновления.
        throw const NoInternetException();
      }
      if (e.type == DioExceptionType.badResponse) {
        // Если сервер не поддержал Range — попробовать с нуля.
        if (existingBytes > 0 && e.response?.statusCode == 416) {
          // 416 Range Not Satisfiable — диапазон битый. Удаляем и пробуем заново.
          try {
            await File(part).delete();
          } catch (_) {}
          return download(
            url: url,
            fileName: fileName,
            onProgress: onProgress,
            resume: false,
          );
        }
        throw const ServerException();
      }
      throw UnknownException(e.message);
    } finally {
      _activeToken = null;
      await ForegroundService.instance.stop();
    }

    // Атомарно: .part → целевой файл.
    try {
      await File(part).rename(target);
    } catch (_) {
      try {
        await File(part).copy(target);
        await File(part).delete();
      } catch (_) {
        throw const FileWriteException();
      }
    }

    final file = File(target);
    if (!await file.exists()) {
      throw const FileWriteException();
    }
    if (await file.length() == 0) {
      await file.delete();
      throw const FileWriteException();
    }

    return target;
  }

  /// Отмена текущего скачивания (файл .part сохраняется для возобновления).
  void cancel() {
    _activeToken?.cancel('user_cancelled');
    _activeToken = null;
  }

  /// Возвращает список частично скачанных файлов, ожидающих возобновления.
  Future<List<File>> getResumableFiles() async {
    final dir = await _resolveDownloadDir();
    if (!await dir.exists()) return [];
    final files = await dir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.part'))
        .toList();
  }

  /// Очищает все .part файлы (например, при сбросе).
  Future<void> clearPartialFiles() async {
    final parts = await getResumableFiles();
    for (final p in parts) {
      try {
        await p.delete();
      } catch (_) {}
    }
  }

  // ---------------- helpers ----------------

  Future<Directory> _resolveDownloadDir({String? subfolder}) async {
    Directory dir;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        dir = Directory(
          '${ext.path}${Platform.pathSeparator}'
          '${AppConstants.downloadsFolderName}',
        );
      } else {
        final docs = await getApplicationDocumentsDirectory();
        dir = Directory(
          '${docs.path}${Platform.pathSeparator}'
          '${AppConstants.downloadsFolderName}',
        );
      }
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory(
        '${docs.path}${Platform.pathSeparator}'
        '${AppConstants.downloadsFolderName}',
      );
    }

    if (subfolder != null && subfolder.isNotEmpty) {
      dir = Directory('${dir.path}${Platform.pathSeparator}$subfolder');
    }

    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _extension(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return '';
    return name.substring(i + 1);
  }

  String _basename(String name) {
    final i = name.lastIndexOf('.');
    return i < 0 ? name : name.substring(0, i);
  }

  bool _isInstagramCdn(String url) {
    final lower = url.toLowerCase();
    return lower.contains('cdninstagram.com') ||
        lower.contains('fbcdn.net') ||
        lower.contains('instagram.com');
  }
}
