import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/widgets/cached_thumbnail.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/media_preview_dialog.dart';
import '../../../history/domain/download_item.dart';
import '../../domain/resolve_result.dart';
import '../../domain/download_stage.dart';
import '../providers/download_provider.dart';
import '../widgets/download_queue_panel.dart';
import '../widgets/post_save_actions_sheet.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String sourceUrl;
  final bool autoStart;
  const PreviewScreen({
    super.key,
    required this.sourceUrl,
    this.autoStart = false,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _autoStartFired = false;
  bool _postSaveSheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(downloadProvider.notifier).resolve(widget.sourceUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    ref.listen<DownloadState>(downloadProvider, (prev, next) {
      if (next is DownloadSuccess &&
          next.items.length == 1 &&
          next.failedCount == 0 &&
          !_postSaveSheetShown) {
        _postSaveSheetShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          PostSaveActionsSheet.show(
            context,
            items: next.items,
            onSaveMore: () => Navigator.of(context).popUntil((r) => r.isFirst),
          );
        });
      }
      if (!widget.autoStart) return;
      if (_autoStartFired) return;
      if (next is DownloadResolved) {
        if (next.result.items.length == 1) {
          _autoStartFired = true;
          ref
              .read(downloadProvider.notifier)
              .download(strings: _buildStrings(s));
        } else if (next.result.isCollection || next.result.isProfile) {
          _autoStartFired = true;
          ref
              .read(downloadProvider.notifier)
              .download(strings: _buildStrings(s));
        }
      }
      if (widget.autoStart &&
          next is DownloadSuccess &&
          next.failedCount == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    final state = ref.watch(downloadProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.previewTitle)),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildBody(state, scheme, s),
        ),
      ),
    );
  }

  DownloadStrings _buildStrings(Strings s) => DownloadStrings(
    completeTitle: s.notificationDownloadCompleteTitle,
    completeBodyAuthorPrefix: s.notificationDownloadAuthorPrefix,
    completeBodyFallback: s.notificationDownloadCompleteBodyFallback,
    errorTitle: s.notificationDownloadErrorTitle,
    batchCompleteBody: s.previewBatchSaved('{count}'),
    channelName: s.notificationChannelDownloads,
    channelDescription: s.notificationChannelDownloadsDesc,
  );

  Widget _buildBody(DownloadState state, ColorScheme scheme, Strings s) {
    if (state is DownloadResolving) {
      return LoadingView(
        key: const ValueKey('resolving'),
        message: s.previewResolving,
      );
    }

    if (state is DownloadAlreadySaved) {
      return _AlreadySavedView(
        key: const ValueKey('already_saved'),
        item: state.existing,
        scheme: scheme,
      );
    }

    if (state is DownloadFailureState) {
      return ErrorView(
        key: const ValueKey('error'),
        message: state.failure.message,
        retryLabel: s.errorRetry,
        onRetry: () =>
            ref.read(downloadProvider.notifier).resolve(widget.sourceUrl),
      );
    }

    if (state is DownloadResolved) {
      return _CollectionPreview(
        key: const ValueKey('resolved'),
        resolved: state,
        sourceUrl: widget.sourceUrl,
        scheme: scheme,
        strings: _buildStrings(s),
      );
    }

    if (state is DownloadInProgress) {
      return _BatchProgressView(progress: state, scheme: scheme);
    }

    if (state is DownloadSuccess) {
      return _BatchSuccessView(
        key: const ValueKey('success'),
        items: state.items,
        failedCount: state.failedCount,
        scheme: scheme,
      );
    }

    return const SizedBox.shrink();
  }
}

String _downloadStageLabel(Strings s, DownloadStage stage) {
  switch (stage) {
    case DownloadStage.analyzing:
      return s.downloadStageAnalyzing;
    case DownloadStage.resolvingMedia:
      return s.downloadStageResolving;
    case DownloadStage.preparing:
      return s.downloadStagePreparing;
    case DownloadStage.downloading:
      return s.downloadStageDownloading;
    case DownloadStage.saving:
      return s.downloadStageSaving;
    case DownloadStage.addedToLibrary:
      return s.downloadStageAddedToLibrary;
  }
}

class _AlreadySavedView extends StatelessWidget {
  final DownloadItem item;
  final ColorScheme scheme;

  const _AlreadySavedView({
    super.key,
    required this.item,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              s.historyAlreadySaved,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              item.displayFileName ?? item.sourceUrl,
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final r = await OpenFilex.open(item.filePath);
                if (!context.mounted) return;
                if (r.type != ResultType.done && item.filePath.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.errorOpenFailed(r.message))),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(s.previewOpen),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.previewGoHome),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionPreview extends ConsumerWidget {
  final DownloadResolved resolved;
  final String sourceUrl;
  final ColorScheme scheme;
  final DownloadStrings strings;

  const _CollectionPreview({
    super.key,
    required this.resolved,
    required this.sourceUrl,
    required this.scheme,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final result = resolved.result;
    final isMulti = result.isCollection || result.isProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(result: result, sourceUrl: sourceUrl, scheme: scheme, s: s),
        const DownloadQueuePanel(compact: true),
        if (isMulti) ...[
          const SizedBox(height: 8),
          _SelectionToolbar(scheme: scheme, s: s),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: isMulti
              ? _MediaGrid(resolved: resolved, scheme: scheme)
              : _SinglePreview(resolved: resolved, scheme: scheme),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.isProfile && result.hasMore)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await ref
                          .read(downloadProvider.notifier)
                          .loadMoreProfile();
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.errorResolverFailed)),
                        );
                      }
                    },
                    icon: const Icon(Icons.expand_more),
                    label: Text(s.previewLoadMore),
                  ),
                ),
              Semantics(
                label: isMulti
                    ? s.previewDownloadSelected(resolved.selectedCount)
                    : s.semPreviewDownload,
                button: true,
                enabled: resolved.selectedCount > 0,
                child: FilledButton.icon(
                  onPressed: resolved.selectedCount == 0
                      ? null
                      : () => ref
                            .read(downloadProvider.notifier)
                            .download(strings: strings),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    isMulti
                        ? s.previewDownloadSelected(resolved.selectedCount)
                        : s.previewDownload,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: s.semPreviewCancel,
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: Text(s.previewCancel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ResolveResult result;
  final String sourceUrl;
  final ColorScheme scheme;
  final Strings s;

  const _HeaderCard({
    required this.result,
    required this.sourceUrl,
    required this.scheme,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (result.type) {
      ResolveType.carousel => s.previewTypeCarousel(result.items.length),
      ResolveType.story => s.previewTypeStory,
      ResolveType.highlight => s.previewTypeHighlight(result.items.length),
      ResolveType.profile => s.previewTypeProfile(result.items.length),
      ResolveType.single => s.previewTypeSingle,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (result.videoCount > 0)
                    _StatChip(
                      icon: Icons.videocam_outlined,
                      label: '${result.videoCount}',
                      scheme: scheme,
                    ),
                  if (result.imageCount > 0) ...[
                    const SizedBox(width: 6),
                    _StatChip(
                      icon: Icons.photo_outlined,
                      label: '${result.imageCount}',
                      scheme: scheme,
                    ),
                  ],
                ],
              ),
              if (result.author != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.author!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(
                s.previewSource(sourceUrl),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _SelectionToolbar extends ConsumerWidget {
  final ColorScheme scheme;
  final Strings s;

  const _SelectionToolbar({required this.scheme, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.select_all, size: 18),
            label: Text(s.previewSelectAll),
            onPressed: () => ref.read(downloadProvider.notifier).selectAll(),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.deselect, size: 18),
            label: Text(s.previewDeselectAll),
            onPressed: () => ref.read(downloadProvider.notifier).deselectAll(),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.videocam_outlined, size: 18),
            label: Text(s.previewVideosOnly),
            onPressed: () =>
                ref.read(downloadProvider.notifier).selectVideosOnly(),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends ConsumerWidget {
  final DownloadResolved resolved;
  final ColorScheme scheme;

  const _MediaGrid({required this.resolved, required this.scheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: resolved.result.items.length,
      itemBuilder: (context, index) {
        final item = resolved.result.items[index];
        final selected = resolved.selectedIds.contains(item.id);
        return _MediaTile(
          item: item,
          selected: selected,
          scheme: scheme,
          onToggle: () =>
              ref.read(downloadProvider.notifier).toggleSelection(item.id),
          onPreview: () => MediaPreviewDialog.show(context, item),
          onQuality: item.hasQualityOptions
              ? () async {
                  final s = S.of(context);
                  final q = await showQualityPicker(
                    context,
                    item,
                    s.previewQualityTitle,
                  );
                  if (q != null) {
                    ref
                        .read(downloadProvider.notifier)
                        .setItemQuality(item.id, q);
                  }
                }
              : null,
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaItem item;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onToggle;
  final VoidCallback? onPreview;
  final VoidCallback? onQuality;

  const _MediaTile({
    required this.item,
    required this.selected,
    required this.scheme,
    required this.onToggle,
    this.onPreview,
    this.onQuality,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPreview,
      onLongPress: onQuality,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.thumbnailUrl != null)
              CachedThumbnail(
                imageUrl: item.thumbnailUrl,
                fallback: _tilePlaceholder(scheme),
              )
            else
              _tilePlaceholder(scheme),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outline,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 14, color: scheme.onPrimary)
                      : null,
                ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isVideo ? Icons.play_arrow : Icons.image,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.isVideo && (item.durationSeconds ?? 0) > 0)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    formatDuration(item.durationSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            if (item.needsResolve && item.isVideo)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.cloud_download_outlined,
                    size: 12,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tilePlaceholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        item.isVideo ? Icons.movie_outlined : Icons.image_outlined,
        color: scheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
}

class _SinglePreview extends StatelessWidget {
  final DownloadResolved resolved;
  final ColorScheme scheme;

  const _SinglePreview({required this.resolved, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final item = resolved.result.items.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => MediaPreviewDialog.show(context, item),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.thumbnailUrl != null
                ? CachedThumbnail(
                    imageUrl: item.thumbnailUrl,
                    fallback: _placeholder(scheme, item),
                  )
                : _placeholder(scheme, item),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, MediaItem item) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          item.isVideo ? Icons.movie_outlined : Icons.image_outlined,
          size: 64,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BatchProgressView extends ConsumerWidget {
  final DownloadInProgress progress;
  final ColorScheme scheme;

  const _BatchProgressView({required this.progress, required this.scheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Column(
      key: const ValueKey('progress'),
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  size: 72,
                  color: scheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  _downloadStageLabel(s, progress.stage),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  s.previewBatchProgress(
                    progress.completed + 1,
                    progress.total,
                  ),
                  style: TextStyle(color: scheme.onSurface, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (progress.currentLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    progress.currentLabel!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.overallProgress > 0
                        ? progress.overallProgress
                        : null,
                    minHeight: 8,
                    color: scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPercent(progress.overallProgress),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: s.semPreviewStop,
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(downloadProvider.notifier).cancelDownload(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(s.previewStop),
                  ),
                ),
              ],
            ),
          ),
        ),
        const DownloadQueuePanel(compact: true),
      ],
    );
  }
}

class _BatchSuccessView extends StatelessWidget {
  final List<DownloadItem> items;
  final int failedCount;
  final ColorScheme scheme;

  const _BatchSuccessView({
    super.key,
    required this.items,
    this.failedCount = 0,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isBatch = items.length > 1;
    final isPartial = failedCount > 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            isPartial ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 72,
            color: isPartial ? scheme.tertiary : scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            s.previewSuccess,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPartial
                ? s.previewPartialSuccess(
                    items.length,
                    items.length + failedCount,
                    failedCount,
                  )
                : isBatch
                ? s.previewBatchSavedCount(items.length)
                : s.previewSavedTo,
            style: TextStyle(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isBatch)
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: scheme.surfaceContainerHighest,
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      item.filePath.split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => _openFile(context, item.filePath),
                    ),
                  );
                },
              ),
            )
          else
            const Spacer(),
          FilledButton.icon(
            onPressed: () => _openFile(context, items.first.filePath),
            icon: const Icon(Icons.play_arrow),
            label: Text(s.previewOpen),
          ),
          const SizedBox(height: 8),
          if (isBatch)
            OutlinedButton.icon(
              onPressed: () => _shareAll(context, items),
              icon: const Icon(Icons.share_outlined),
              label: Text(s.previewShareAll),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _shareOne(context, items.first.filePath),
              icon: const Icon(Icons.share_outlined),
              label: Text(s.previewShare),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_outlined),
            label: Text(s.previewGoHome),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String path) async {
    final s = S.of(context);
    final result = await OpenFilex.open(path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.errorOpenFailed(result.message))),
      );
    }
  }

  Future<void> _shareOne(BuildContext context, String path) async {
    final s = S.of(context);
    if (!File(path).existsSync()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.errorFileMissing)));
      return;
    }
    await Share.shareXFiles([XFile(path)], text: s.shareText);
  }

  Future<void> _shareAll(BuildContext context, List<DownloadItem> items) async {
    final s = S.of(context);
    final files = items
        .where((i) => File(i.filePath).existsSync())
        .map((i) => XFile(i.filePath))
        .toList();
    if (files.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.errorFileMissing)));
      return;
    }
    await Share.shareXFiles(files, text: s.shareText);
  }
}
