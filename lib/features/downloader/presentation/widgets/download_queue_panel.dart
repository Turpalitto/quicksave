import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/strings.dart';
import '../../../../services/download_queue.dart';
import '../providers/download_queue_provider.dart';

/// Per-task download queue panel with pause / resume / cancel controls.
class DownloadQueuePanel extends ConsumerWidget {
  const DownloadQueuePanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueTasksProvider);
    final active = tasks
        .where(
          (t) =>
              t.status == DownloadTaskStatus.queued ||
              t.status == DownloadTaskStatus.running ||
              t.status == DownloadTaskStatus.paused,
        )
        .toList();

    if (active.isEmpty) return const SizedBox.shrink();

    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final queue = DownloadQueue.instance;

    return Semantics(
      label: s.queuePanelTitle,
      child: Card(
        margin: compact
            ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
            : const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.queuePanelTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...active.map(
                (task) => _TaskRow(
                  task: task,
                  scheme: scheme,
                  s: s,
                  onPause: () => queue.pause(task.id),
                  onResume: () => queue.resume(task.id),
                  onCancel: () => queue.cancel(task.id),
                  onRetry: () => queue.retry(task.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.scheme,
    required this.s,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final DownloadQueueTask task;
  final ColorScheme scheme;
  final Strings s;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (task.status) {
      DownloadTaskStatus.queued => s.queueStatusQueued,
      DownloadTaskStatus.running => s.queueStatusRunning,
      DownloadTaskStatus.paused => s.queueStatusPaused,
      DownloadTaskStatus.failed => s.queueStatusFailed,
      DownloadTaskStatus.completed => s.queueStatusCompleted,
      DownloadTaskStatus.cancelled => s.queueStatusCancelled,
    };

    return Semantics(
      label: '${task.fileName}, $statusLabel, ${formatPercent(task.progress)}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: task.progress > 0 ? task.progress.clamp(0, 1) : null,
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == DownloadTaskStatus.running)
                  Semantics(
                    label: s.queuePause,
                    button: true,
                    child: IconButton(
                      tooltip: s.queuePause,
                      onPressed: onPause,
                      icon: const Icon(Icons.pause, size: 20),
                    ),
                  ),
                if (task.status == DownloadTaskStatus.paused)
                  Semantics(
                    label: s.queueResume,
                    button: true,
                    child: IconButton(
                      tooltip: s.queueResume,
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow, size: 20),
                    ),
                  ),
                if (task.status == DownloadTaskStatus.failed)
                  Semantics(
                    label: s.queueRetry,
                    button: true,
                    child: IconButton(
                      tooltip: s.queueRetry,
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                  ),
                Semantics(
                  label: s.queueCancel,
                  button: true,
                  child: IconButton(
                    tooltip: s.queueCancel,
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
