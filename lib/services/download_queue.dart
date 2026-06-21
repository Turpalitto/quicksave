import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import 'download_preflight.dart';
import 'download_service.dart';

enum DownloadTaskStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadQueueTask {
  DownloadQueueTask({
    required this.id,
    required this.url,
    required this.fileName,
    this.subfolder,
    this.preflight,
    this.status = DownloadTaskStatus.queued,
    this.progress = 0,
    this.retryCount = 0,
    this.errorMessage,
    this.resultPath,
  });

  final String id;
  final String url;
  final String fileName;
  final String? subfolder;
  DownloadPreflight? preflight;
  DownloadTaskStatus status;
  double progress;
  int retryCount;
  String? errorMessage;
  String? resultPath;

  DownloadQueueTask copyWith({
    DownloadTaskStatus? status,
    double? progress,
    int? retryCount,
    String? errorMessage,
    String? resultPath,
    DownloadPreflight? preflight,
  }) =>
      DownloadQueueTask(
        id: id,
        url: url,
        fileName: fileName,
        subfolder: subfolder,
        preflight: preflight ?? this.preflight,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        retryCount: retryCount ?? this.retryCount,
        errorMessage: errorMessage ?? this.errorMessage,
        resultPath: resultPath ?? this.resultPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'fileName': fileName,
        'subfolder': subfolder,
        'preflight': preflight?.toJson(),
        'status': status.name,
        'progress': progress,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'resultPath': resultPath,
      };
}

typedef QueueProgressCallback = void Function(DownloadQueueTask task);

/// Production download queue: multi-task, pause/resume/cancel, retry w/ backoff.
class DownloadQueue {
  DownloadQueue._();
  static final DownloadQueue instance = DownloadQueue._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    followRedirects: true,
    validateStatus: (s) => s != null && s < 500,
  ));

  final List<DownloadQueueTask> _tasks = [];
  final _controller = StreamController<List<DownloadQueueTask>>.broadcast();
  bool _processing = false;
  String? _activeTaskId;
  bool _pauseRequested = false;

  Stream<List<DownloadQueueTask>> get tasksStream => _controller.stream;
  List<DownloadQueueTask> get tasks => List.unmodifiable(_tasks);

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_tasks));
    }
  }

  String enqueue({
    required String url,
    required String fileName,
    String? subfolder,
    bool runPreflight = true,
  }) {
    final id = const Uuid().v4();
    _tasks.add(DownloadQueueTask(
      id: id,
      url: url,
      fileName: fileName,
      subfolder: subfolder,
    ));
    _emit();
    unawaited(_processQueue(runPreflight: runPreflight));
    return id;
  }

  void enqueueBatch(List<({String url, String fileName, String? subfolder})> items) {
    for (final item in items) {
      _tasks.add(DownloadQueueTask(
        id: const Uuid().v4(),
        url: item.url,
        fileName: item.fileName,
        subfolder: item.subfolder,
      ));
    }
    _emit();
    unawaited(_processQueue());
  }

  Future<DownloadPreflight> preflight(String url, String fileName) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          headers: _cdnHeaders(url),
          followRedirects: true,
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final len = int.tryParse(response.headers.value('content-length') ?? '');
      final type = response.headers.value('content-type');
      final tooLarge = len != null && len > AppConstants.maxDownloadBytes;
      return DownloadPreflight(
        contentType: type,
        estimatedBytes: len,
        targetFileName: fileName,
        acceptable: !tooLarge,
        rejectionReason: tooLarge ? 'file_too_large' : null,
      );
    } catch (_) {
      return DownloadPreflight(
        contentType: null,
        estimatedBytes: null,
        targetFileName: fileName,
        acceptable: true,
      );
    }
  }

  void pause(String taskId) {
    if (_activeTaskId == taskId) {
      _pauseRequested = true;
      DownloadService.instance.cancelTask(taskId, paused: true);
    }
    _updateTask(taskId, (t) => t.copyWith(
          status: DownloadTaskStatus.paused,
          progress: t.progress,
        ));
  }

  void resume(String taskId) {
    _updateTask(taskId, (t) => t.copyWith(
          status: DownloadTaskStatus.queued,
          progress: 0,
          errorMessage: null,
        ));
    unawaited(_processQueue());
  }

  void cancel(String taskId) {
    if (_activeTaskId == taskId) {
      DownloadService.instance.cancelTask(taskId);
    }
    _updateTask(taskId, (t) => t.copyWith(
          status: DownloadTaskStatus.cancelled,
          progress: 0,
        ));
  }

  void cancelAll() {
    if (_activeTaskId != null) {
      DownloadService.instance.cancelTask(_activeTaskId!);
    }
    for (var i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.status == DownloadTaskStatus.queued ||
          t.status == DownloadTaskStatus.running ||
          t.status == DownloadTaskStatus.paused) {
        _tasks[i] = t.copyWith(status: DownloadTaskStatus.cancelled);
      }
    }
    _emit();
  }

  void retry(String taskId) {
    _updateTask(taskId, (t) => t.copyWith(
          status: DownloadTaskStatus.queued,
          progress: 0,
          errorMessage: null,
        ));
    unawaited(_processQueue());
  }

  void clearCompleted() {
    _tasks.removeWhere((t) =>
        t.status == DownloadTaskStatus.completed ||
        t.status == DownloadTaskStatus.cancelled);
    _emit();
  }

  /// Test-only reset.
  void resetForTests() {
    _tasks.clear();
    _processing = false;
    _activeTaskId = null;
    _pauseRequested = false;
    _emit();
  }

  Future<void> _processQueue({bool runPreflight = true}) async {
    if (_processing) return;
    _processing = true;
    try {
      while (true) {
        DownloadQueueTask? next;
        for (final t in _tasks) {
          if (t.status == DownloadTaskStatus.queued) {
            next = t;
            break;
          }
        }
        if (next == null) break;

        _activeTaskId = next.id;
        _pauseRequested = false;
        _updateTask(next.id, (t) => t.copyWith(
              status: DownloadTaskStatus.running,
              progress: 0,
            ));

        if (runPreflight) {
          final pf = await preflight(next.url, next.fileName);
          _updateTask(next.id, (t) => t.copyWith(preflight: pf));
          if (!pf.acceptable) {
            _updateTask(next.id, (t) => t.copyWith(
                  status: DownloadTaskStatus.failed,
                  errorMessage: pf.rejectionReason ?? 'preflight_rejected',
                ));
            _activeTaskId = null;
            continue;
          }
        }

        final success = await _runWithRetry(next);
        if (!success && _pauseRequested) {
          _updateTask(next.id, (t) => t.copyWith(status: DownloadTaskStatus.paused));
        }
        _activeTaskId = null;
      }
    } finally {
      _processing = false;
    }
  }

  Future<bool> _runWithRetry(DownloadQueueTask task) async {
    const maxRetries = AppConstants.downloadMaxRetries;
    while (task.retryCount <= maxRetries) {
      if (_pauseRequested) return false;
      try {
        final path = await DownloadService.instance.download(
          url: task.url,
          fileName: task.fileName,
          subfolder: task.subfolder,
          taskId: task.id,
          onProgress: (p) {
            _updateTask(task.id, (t) => t.copyWith(progress: p));
          },
        );
        _updateTask(task.id, (t) => t.copyWith(
              status: DownloadTaskStatus.completed,
              progress: 1,
              resultPath: path,
            ));
        return true;
      } on DownloadCancelledException {
        return false;
      } catch (e) {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx < 0) return false;
        final current = _tasks[idx];
        if (current.retryCount >= maxRetries) {
          _tasks[idx] = current.copyWith(
            status: DownloadTaskStatus.failed,
            errorMessage: e.toString(),
          );
          _emit();
          return false;
        }
        final delayMs = min(
          30000,
          AppConstants.downloadRetryBaseMs * pow(2, current.retryCount).toInt(),
        );
        _tasks[idx] = current.copyWith(retryCount: current.retryCount + 1);
        _emit();
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
    return false;
  }

  void _updateTask(
    String id,
    DownloadQueueTask Function(DownloadQueueTask) transform,
  ) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    _tasks[idx] = transform(_tasks[idx]);
    _emit();
  }

  Map<String, String> _cdnHeaders(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('cdninstagram.com') ||
        lower.contains('fbcdn.net') ||
        lower.contains('instagram.com')) {
      return {
        'Referer': 'https://www.instagram.com/',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/122.0 Mobile Safari/537.36',
      };
    }
    return const {};
  }

  Future<DownloadQueueTask> waitForTask(String taskId) async {
    DownloadQueueTask? current;
    for (final t in _tasks) {
      if (t.id == taskId) {
        current = t;
        break;
      }
    }
    if (current == null) {
      throw StateError('Task $taskId not found');
    }
    if (_isTerminal(current.status)) return current;

    await for (final list in tasksStream) {
      final match = list.where((t) => t.id == taskId).firstOrNull;
      if (match != null && _isTerminal(match.status)) {
        return match;
      }
    }
    return current;
  }

  bool _isTerminal(DownloadTaskStatus status) =>
      status == DownloadTaskStatus.completed ||
      status == DownloadTaskStatus.failed ||
      status == DownloadTaskStatus.cancelled;
}
