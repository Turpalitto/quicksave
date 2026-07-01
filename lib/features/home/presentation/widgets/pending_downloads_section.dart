import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../downloader/domain/pending_download.dart';
import '../../../downloader/presentation/providers/download_provider.dart';
import '../../../downloader/presentation/providers/pending_download_provider.dart';
import '../../../downloader/presentation/screens/preview_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PendingDownloadsSection extends ConsumerWidget {
  const PendingDownloadsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingDownloadsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    final tiles = <Widget>[
      Row(
        children: [
          Icon(Icons.schedule, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.pendingDownloadsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        s.pendingDownloadsSubtitle(pending.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
    ];

    for (final item in pending.take(3)) {
      final short = item.sourceUrl.length > 48
          ? '${item.sourceUrl.substring(0, 48)}…'
          : item.sourceUrl;
      tiles.add(
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(short, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            tooltip: s.pendingDownloadsRemove,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () =>
                ref.read(pendingDownloadsProvider.notifier).remove(item.id),
          ),
          onTap: () => _openRetry(context, ref, item.sourceUrl),
        ),
      );
    }

    if (pending.length > 3) {
      tiles.add(
        Text(
          '+${pending.length - 3}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    tiles.add(
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _retryAll(ref, pending),
          icon: const Icon(Icons.refresh),
          label: Text(s.pendingDownloadsRetryNow),
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
      ),
    );
  }

  void _openRetry(BuildContext context, WidgetRef ref, String url) {
    ref.read(downloadProvider.notifier).reset();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          sourceUrl: url,
          autoStart: ref.read(settingsProvider).autoDownload,
        ),
      ),
    );
  }

  Future<void> _retryAll(WidgetRef ref, List<PendingDownload> pending) async {
    for (final item in pending) {
      final ok = await ref
          .read(downloadProvider.notifier)
          .retryPendingUrl(item.sourceUrl);
      if (ok) {
        await ref
            .read(pendingDownloadsProvider.notifier)
            .removeByUrl(item.sourceUrl);
      }
    }
  }
}
