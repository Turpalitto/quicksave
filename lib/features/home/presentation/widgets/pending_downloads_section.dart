import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/widgets/ios/ios_button.dart';
import '../../../../core/widgets/ios/ios_card.dart';
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

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: IosTokens.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.pendingDownloadsTitle, style: IosTokens.subhead),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.pendingDownloadsSubtitle(pending.length),
            style: IosTokens.footnote,
          ),
          const SizedBox(height: 8),
          for (final item in pending.take(3)) ...[
            _PendingRow(
              item: item,
              onRemove: () =>
                  ref.read(pendingDownloadsProvider.notifier).remove(item.id),
              onTap: () => _openRetry(context, ref, item.sourceUrl),
            ),
          ],
          if (pending.length > 3)
            Text('+${pending.length - 3}', style: IosTokens.footnote),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IosPressable(
              onTap: () => _retryAll(ref, pending),
              child: Text(
                s.pendingDownloadsRetryNow,
                style: IosTokens.subhead.copyWith(color: IosTokens.blue),
              ),
            ),
          ),
        ],
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

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  final PendingDownload item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final short = item.sourceUrl.length > 48
        ? '${item.sourceUrl.substring(0, 48)}…'
        : item.sourceUrl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                short,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: IosTokens.footnote,
              ),
            ),
            IconButton(
              tooltip: s.pendingDownloadsRemove,
              icon: const Icon(Icons.close, size: 18, color: IosTokens.label3),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
