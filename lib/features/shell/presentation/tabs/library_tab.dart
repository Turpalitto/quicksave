import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/widgets/cached_thumbnail.dart';
import '../../../../core/widgets/ios/ios_button.dart';
import '../../../../core/widgets/ios/ios_card.dart';
import '../../../../core/widgets/ios/ios_section.dart';
import '../../../../core/widgets/ios/ios_segment.dart';
import '../../../history/domain/download_item.dart';
import '../../../history/domain/library_filter.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/presentation/screens/history_screen.dart';

enum _LibraryFilter { all, post, reel, story }

class _LibraryGroup {
  const _LibraryGroup({required this.key, required this.items});

  final String key;
  final List<DownloadItem> items;

  DownloadItem get representative {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  int get mediaCount => items.length;
}

class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key, this.version = 0});

  final int version;

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  _LibraryFilter _filter = _LibraryFilter.all;
  bool _editing = false;

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      ref.invalidate(historyProvider);
    }
  }

  List<_LibraryGroup> _groupItems(List<DownloadItem> items) {
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

    return [
      ...singles.map((i) => _LibraryGroup(key: i.id, items: [i])),
      ...map.entries.map((e) => _LibraryGroup(key: e.key, items: e.value)),
    ]..sort(
        (a, b) => b.representative.createdAt.compareTo(a.representative.createdAt),
      );
  }

  bool _matchesFilter(_LibraryGroup group) {
    final kind = group.representative.effectiveSourceKind;
    return switch (_filter) {
      _LibraryFilter.all => true,
      _LibraryFilter.post =>
        kind == MediaSourceKind.post ||
        kind == MediaSourceKind.profile ||
        kind == MediaSourceKind.carousel,
      _LibraryFilter.reel => kind == MediaSourceKind.reel,
      _LibraryFilter.story =>
        kind == MediaSourceKind.story || kind == MediaSourceKind.highlight,
    };
  }

  Future<void> _openGroup(_LibraryGroup group) async {
    final item = group.representative;
    if (item.filePath.isEmpty || !File(item.filePath).existsSync()) return;
    await OpenFilex.open(item.filePath);
  }

  Future<void> _deleteGroup(_LibraryGroup group) async {
    final notifier = ref.read(historyProvider.notifier);
    for (final item in group.items) {
      await notifier.remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = ref.watch(historyProvider);
    final groups = _groupItems(items);
    final visible = groups.where(_matchesFilter).toList();
    final totalFiles = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: IosSegment<_LibraryFilter>(
                segments: _LibraryFilter.values,
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
                labelBuilder: (f) => switch (f) {
                  _LibraryFilter.all => s.libraryFilterAll,
                  _LibraryFilter.post => s.libraryFilterPosts,
                  _LibraryFilter.reel => s.libraryFilterReels,
                  _LibraryFilter.story => s.libraryFilterStories,
                },
              ),
            ),
            const SizedBox(width: 12),
            IosPressable(
              onTap: () => setState(() => _editing = !_editing),
              child: Text(
                _editing ? s.libraryDone : s.libraryEdit,
                style: IosTokens.subhead.copyWith(color: IosTokens.blue),
              ),
            ),
          ],
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            s.libraryStats(groups.length, totalFiles),
            style: IosTokens.footnote,
          ),
        ],
        const SizedBox(height: 12),
        if (visible.isEmpty)
          IosCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: IosTokens.fill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.grid_view, color: IosTokens.label3, size: 26),
                ),
                const SizedBox(height: 16),
                Text(s.libraryEmptyTitle, style: IosTokens.title3),
                const SizedBox(height: 4),
                Text(
                  s.libraryEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: IosTokens.footnote,
                ),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: visible.length,
              itemBuilder: (_, i) => _LibraryTile(
                group: visible[i],
                index: i,
                editing: _editing,
                onTap: () => _openGroup(visible[i]),
                onDelete: () => _deleteGroup(visible[i]),
              ),
            ),
          ),
        const SizedBox(height: 8),
        IosSectionFooter(_editing ? s.libraryFooterEdit : s.libraryFooter),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
          child: Text(
            s.libraryOpenHistory,
            style: IosTokens.subhead.copyWith(color: IosTokens.blue),
          ),
        ),
      ],
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.group,
    required this.index,
    required this.editing,
    required this.onTap,
    required this.onDelete,
  });

  final _LibraryGroup group;
  final int index;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final item = group.representative;
    final gradient = IosTokens.libraryGradients[index % IosTokens.libraryGradients.length];
    final label = item.author != null ? '@${item.author}' : 'Instagram';

    return GestureDetector(
      onTap: editing ? null : onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
            CachedThumbnail(
              imageUrl: item.thumbnailUrl,
              width: double.infinity,
              height: double.infinity,
              fallback: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            )
          else
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (group.mediaCount > 1)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.copy, color: Colors.white, size: 14),
            )
          else if (item.mediaType == 'video' ||
              item.effectiveSourceKind == MediaSourceKind.reel)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 14),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IosTokens.caption2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (editing)
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: IosTokens.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
