import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/download_queue.dart';

final downloadQueueProvider = StreamProvider<List<DownloadQueueTask>>(
  (ref) => DownloadQueue.instance.tasksStream,
);

final downloadQueueTasksProvider = Provider<List<DownloadQueueTask>>((ref) {
  return ref
      .watch(downloadQueueProvider)
      .maybeWhen(
        data: (tasks) => tasks,
        orElse: () => DownloadQueue.instance.tasks,
      );
});
