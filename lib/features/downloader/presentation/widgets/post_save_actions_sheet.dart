import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../history/domain/download_item.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../core/utils/strings.dart';

/// Post-download actions: open, collection, share, save more.
class PostSaveActionsSheet extends ConsumerWidget {
  const PostSaveActionsSheet({
    super.key,
    required this.items,
    required this.onSaveMore,
  });

  final List<DownloadItem> items;
  final VoidCallback onSaveMore;

  static Future<void> show(
    BuildContext context, {
    required List<DownloadItem> items,
    required VoidCallback onSaveMore,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          PostSaveActionsSheet(items: items, onSaveMore: onSaveMore),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final item = items.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.previewSuccess,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.postSaveSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _open(context, item.filePath),
              icon: const Icon(Icons.play_arrow),
              label: Text(s.previewOpen),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addToCollection(context, ref, item.id),
              icon: const Icon(Icons.folder_outlined),
              label: Text(s.historyAddToCollection),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _share(context, item.filePath),
              icon: const Icon(Icons.share_outlined),
              label: Text(s.previewShare),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onSaveMore();
              },
              icon: const Icon(Icons.add_link),
              label: Text(s.postSaveMore),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String path) async {
    final s = S.of(context);
    final r = await OpenFilex.open(path);
    if (!context.mounted) return;
    if (r.type != ResultType.done) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.errorOpenFailed(r.message))));
    }
  }

  Future<void> _share(BuildContext context, String path) async {
    final s = S.of(context);
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.errorFileMissing)));
      return;
    }
    await Share.shareXFiles([XFile(path)], text: s.shareText);
  }

  Future<void> _addToCollection(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    final s = S.of(context);
    final collections = await ref.read(collectionsProvider.future);
    if (!context.mounted) return;
    if (collections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.historyCreateCollection)));
      return;
    }
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(s.historyAddToCollection),
        children: collections
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c.id),
                child: Text(c.name),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null) return;
    await ref.read(historyProvider.notifier).addToCollection(picked, itemId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.historyAddedToCollection)));
  }
}
