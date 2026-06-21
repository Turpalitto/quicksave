import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/file_import.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/utils/web_download.dart';
import '../../data/web_library_repository.dart';
import '../providers/web_dashboard_provider.dart';

class WebLibraryPanel extends ConsumerStatefulWidget {
  const WebLibraryPanel({super.key});

  @override
  ConsumerState<WebLibraryPanel> createState() => _WebLibraryPanelState();
}

class _WebLibraryPanelState extends ConsumerState<WebLibraryPanel> {
  final _importCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _importJson(String raw) async {
    final s = S.of(context);
    try {
      final count = await WebLibraryRepository.instance.importFromJsonString(
        raw,
      );
      ref.invalidate(webLibraryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.webLibraryImported(count))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.webLibraryImportFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final libraryAsync = ref.watch(webLibraryProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.webLibraryTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(s.webLibrarySubtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: s.webLibrarySearchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () async {
                final raw = await pickJsonFileText();
                if (raw != null) await _importJson(raw);
              },
              icon: const Icon(Icons.upload_file),
              label: Text(s.webLibraryImportFile),
            ),
            OutlinedButton.icon(
              onPressed: libraryAsync.maybeWhen(
                data: (items) => items.isEmpty
                    ? null
                    : () async {
                        final csv = WebLibraryRepository.instance.toCsv(items);
                        await downloadTextFile(
                          fileName: 'quicksave-library.csv',
                          content: csv,
                          mimeType: 'text/csv',
                        );
                      },
                orElse: () => null,
              ),
              icon: const Icon(Icons.download),
              label: Text(s.webLibraryExportCsv),
            ),
            TextButton.icon(
              onPressed: () async {
                await WebLibraryRepository.instance.clear();
                ref.invalidate(webLibraryProvider);
              },
              icon: Icon(Icons.delete_outline, color: scheme.error),
              label: Text(s.webLibraryClear),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(s.webLibraryPasteJson),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _importCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: s.webLibraryPasteHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => _importJson(_importCtrl.text),
                      child: Text(s.webLibraryImport),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        libraryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(s.errorNotRecognized),
          data: (items) {
            final filtered = _query.isEmpty
                ? items
                : items.where((item) {
                    final hay = [
                      item['author'],
                      item['sourceUrl'],
                      item['caption'],
                      item['mediaType'],
                    ].whereType<String>().join(' ').toLowerCase();
                    return hay.contains(_query);
                  }).toList();

            if (filtered.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.webLibraryEmpty),
                ),
              );
            }

            return Column(
              children: filtered
                  .map(
                    (item) => Card(
                      child: ListTile(
                        leading: Icon(
                          (item['mediaType'] as String?) == 'video'
                              ? Icons.videocam_outlined
                              : Icons.image_outlined,
                        ),
                        title: Text(
                          item['author'] as String? ??
                              item['sourceUrl'] as String? ??
                              s.webResolveMediaItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item['caption'] as String? ??
                              item['createdAt'] as String? ??
                              '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
