import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/export_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/widgets/cached_thumbnail.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../domain/download_item.dart';
import '../providers/history_provider.dart';

enum HistoryMediaFilter { all, video, image }

final historyQueryProvider = StateProvider<String>((ref) => '');

final historyFilterProvider =
    StateProvider<HistoryMediaFilter>((ref) => HistoryMediaFilter.all);

final filteredHistoryProvider = Provider<List<DownloadItem>>((ref) {
  final all = ref.watch(historyProvider);
  final q = ref.watch(historyQueryProvider).trim().toLowerCase();
  final filter = ref.watch(historyFilterProvider);

  Iterable<DownloadItem> items = all;
  switch (filter) {
    case HistoryMediaFilter.video:
      items = items.where((i) => i.mediaType != 'image');
    case HistoryMediaFilter.image:
      items = items.where((i) => i.mediaType == 'image');
    case HistoryMediaFilter.all:
      break;
  }

  if (q.isEmpty) return items.toList();
  return items.where((item) {
    final author = (item.author ?? '').toLowerCase();
    final url = item.sourceUrl.toLowerCase();
    return author.contains(q) || url.contains(q);
  }).toList();
});

/// Groups history entries by [DownloadItem.groupId].
final groupedHistoryProvider = Provider<List<HistoryGroup>>((ref) {
  final items = ref.watch(filteredHistoryProvider);
  final map = <String, List<DownloadItem>>{};
  final singles = <DownloadItem>[];

  for (final item in items) {
    final gid = item.groupId;
    if (gid == null || gid.isEmpty) {
      singles.add(item);
    } else {
      map.putIfAbsent(gid, () => []).add(item);
    }
  }

  final groups = <HistoryGroup>[
    ...singles.map(HistoryGroup.single),
    ...map.entries.map((e) => HistoryGroup.batch(e.key, e.value)),
  ];
  groups.sort((a, b) => b.newest.compareTo(a.newest));
  return groups;
});

class HistoryGroup {
  final String? groupId;
  final List<DownloadItem> items;

  const HistoryGroup._({this.groupId, required this.items});

  factory HistoryGroup.single(DownloadItem item) =>
      HistoryGroup._(items: [item]);

  factory HistoryGroup.batch(String groupId, List<DownloadItem> items) {
    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return HistoryGroup._(groupId: groupId, items: sorted);
  }

  bool get isBatch => items.length > 1;
  DateTime get newest => items.first.createdAt;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(historyProvider);
    final groups = ref.watch(groupedHistoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          if (all.isNotEmpty)
            IconButton(
              tooltip: s.historyClearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (all.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: s.historySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(historyQueryProvider.notifier).state =
                                  '';
                            },
                          ),
                  ),
                  onChanged: (v) {
                    ref.read(historyQueryProvider.notifier).state = v;
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: s.historyFilterAll,
                      selected: filter == HistoryMediaFilter.all,
                      onTap: () => ref
                          .read(historyFilterProvider.notifier)
                          .state = HistoryMediaFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: s.historyFilterVideo,
                      selected: filter == HistoryMediaFilter.video,
                      onTap: () => ref
                          .read(historyFilterProvider.notifier)
                          .state = HistoryMediaFilter.video,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: s.historyFilterImage,
                      selected: filter == HistoryMediaFilter.image,
                      onTap: () => ref
                          .read(historyFilterProvider.notifier)
                          .state = HistoryMediaFilter.image,
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: all.isEmpty
                  ? EmptyView(
                      icon: Icons.history,
                      title: s.historyEmpty,
                      subtitle: s.historyEmptySubtitle,
                    )
                  : groups.isEmpty
                      ? EmptyView(
                          icon: Icons.search_off,
                          title: s.historyEmpty,
                          subtitle: s.historySearchEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _HistoryGroupTile(
                            group: groups[i],
                            scheme: scheme,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.historyClearConfirmTitle),
        content: Text(s.historyClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.historyClearConfirmNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.historyClearConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(historyProvider.notifier).clear();
      _searchController.clear();
      ref.read(historyQueryProvider.notifier).state = '';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _HistoryGroupTile extends ConsumerWidget {
  final HistoryGroup group;
  final ColorScheme scheme;

  const _HistoryGroupTile({required this.group, required this.scheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!group.isBatch) {
      return _HistoryTile(item: group.items.first, scheme: scheme);
    }

    final s = S.of(context);
    final isPro = ref.watch(settingsProvider).canExportZip;

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.folder_copy_outlined, color: scheme.primary),
        title: Text(
          group.items.first.author ?? 'Instagram',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(s.historyBatchFiles(group.items.length)),
        children: [
          if (isPro)
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(s.historyExportZip),
              onTap: () async {
                try {
                  await ExportService.instance.shareZip(group.items);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.errorFileMissing)),
                  );
                }
              },
            ),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _HistoryTile(item: item, scheme: scheme, compact: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final DownloadItem item;
  final ColorScheme scheme;
  final bool compact;

  const _HistoryTile({
    required this.item,
    required this.scheme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final exists = File(item.filePath).existsSync();

    return Dismissible(
      key: ValueKey('hist_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
        ),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context, s, deleteFile: false),
      onDismissed: (_) async {
        await ref.read(historyProvider.notifier).remove(item.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.historyDeleted)),
        );
      },
      child: Card(
        margin: compact ? EdgeInsets.zero : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedThumbnail(
                  imageUrl: item.thumbnailUrl,
                  width: 64,
                  height: 64,
                  fallback: _Thumb(scheme: scheme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.author ?? 'Instagram',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.mediaIndex != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.mediaType == 'image'
                                ? Icons.image_outlined
                                : Icons.videocam_outlined,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${item.mediaIndex! + 1}',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.postDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${s.historyPostDate}: ${formatDate(item.postDate!)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      formatDate(item.createdAt),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${formatBytes(item.fileSizeBytes)}'
                      '${exists ? '' : ' • ${s.historyFileUnavailable}'}',
                      style: TextStyle(
                        color: exists ? scheme.onSurfaceVariant : scheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) => _onAction(context, ref, v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow),
                        const SizedBox(width: 8),
                        Text(s.historyActionOpen),
                      ],
                    ),
                  ),
                  if (item.caption != null && item.caption!.isNotEmpty)
                    PopupMenuItem(
                      value: 'copy_caption',
                      child: Row(
                        children: [
                          const Icon(Icons.copy_outlined),
                          const SizedBox(width: 8),
                          Text(s.historyCopyCaption),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined),
                        const SizedBox(width: 8),
                        Text(s.historyActionShare),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_file',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever_outlined),
                        const SizedBox(width: 8),
                        Text(s.historyDeleteFileConfirm),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 8),
                        Text(s.historyActionDelete),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    Strings s, {
    required bool deleteFile,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              deleteFile ? s.historyDeleteFileTitle : s.historyActionDelete,
            ),
            content: Text(
              deleteFile ? s.historyDeleteFileBody : s.historyDeleteRecordBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(s.historyClearConfirmNo),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  deleteFile ? s.historyDeleteFileConfirm : s.historyClearConfirmYes,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final s = S.of(context);
    switch (action) {
      case 'open':
        final r = await OpenFilex.open(item.filePath);
        if (!context.mounted) return;
        if (r.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.errorOpenFailed(r.message))),
          );
        }
        break;
      case 'copy_caption':
        final caption = item.caption;
        if (caption == null || caption.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: caption));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.historyCaptionCopied)),
        );
        break;
      case 'share':
        if (!File(item.filePath).existsSync()) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.errorFileMissing)),
          );
          return;
        }
        await Share.shareXFiles([XFile(item.filePath)], text: s.shareText);
        break;
      case 'delete_file':
        if (await _confirmDelete(context, s, deleteFile: true)) {
          await ref
              .read(historyProvider.notifier)
              .remove(item.id, deleteFile: true);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.historyDeleted)),
          );
        }
        break;
      case 'delete':
        await ref.read(historyProvider.notifier).remove(item.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.historyDeleted)),
        );
        break;
    }
  }
}

class _Thumb extends StatelessWidget {
  final ColorScheme scheme;
  const _Thumb({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined,
          size: 28, color: scheme.onSurfaceVariant),
    );
  }
}
