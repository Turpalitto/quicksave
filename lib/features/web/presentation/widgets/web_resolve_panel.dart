import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/strings.dart';
import '../../../downloader/domain/resolve_result.dart';
import '../providers/web_dashboard_provider.dart';

class WebResolvePanel extends ConsumerStatefulWidget {
  const WebResolvePanel({super.key});

  @override
  ConsumerState<WebResolvePanel> createState() => _WebResolvePanelState();
}

class _WebResolvePanelState extends ConsumerState<WebResolvePanel> {
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _consumeUrlQuery());
    }
  }

  void _consumeUrlQuery() {
    final url = Uri.base.queryParameters['url'];
    if (url == null || url.isEmpty) return;
    _urlCtrl.text = url;
    ref.read(webResolveProvider.notifier).resolve(url);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(webResolveProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.webResolveTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.webResolveSubtitle,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _urlCtrl,
          decoration: InputDecoration(
            hintText: s.urlFieldHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => ref
                  .read(webResolveProvider.notifier)
                  .resolve(_urlCtrl.text),
            ),
          ),
          onSubmitted: (v) =>
              ref.read(webResolveProvider.notifier).resolve(v),
        ),
        const SizedBox(height: 16),
        switch (state) {
          WebResolveIdle() => _HintCard(
            icon: Icons.link,
            text: s.webResolveHint,
            scheme: scheme,
          ),
          WebResolveLoading() => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          WebResolveError(:final failure) => _HintCard(
            icon: Icons.error_outline,
            text: failure.message,
            scheme: scheme,
            isError: true,
          ),
          WebResolveReady(:final result, :final sourceUrl) =>
            _ResolveResults(
              result: result,
              sourceUrl: sourceUrl,
              onClear: () {
                ref.read(webResolveProvider.notifier).reset();
                _urlCtrl.clear();
              },
            ),
        },
      ],
    );
  }
}

class _ResolveResults extends StatelessWidget {
  const _ResolveResults({
    required this.result,
    required this.sourceUrl,
    required this.onClear,
  });

  final ResolveResult result;
  final String sourceUrl;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.check_circle, color: scheme.primary),
            title: Text(s.webResolveSuccess(result.items.length)),
            subtitle: Text(sourceUrl, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: TextButton(onPressed: onClear, child: Text(s.previewCancel)),
          ),
        ),
        const SizedBox(height: 12),
        ...result.items.map(
          (item) => Card(
            child: ListTile(
              leading: Icon(
                item.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              ),
              title: Text(item.fileName),
              subtitle: Text(
                result.author ?? item.shortcode ?? s.webResolveMediaItem,
              ),
              trailing: item.mediaUrl.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: s.webOpenMedia,
                      onPressed: () => launchUrl(
                        Uri.parse(item.mediaUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _HintCard(
          icon: Icons.phone_android,
          text: s.webResolveMobileNote,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.text,
    required this.scheme,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final ColorScheme scheme;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isError ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isError ? scheme.error : scheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
