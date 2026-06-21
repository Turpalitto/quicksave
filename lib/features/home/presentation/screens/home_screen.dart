import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/intent_service.dart';
import '../../../../services/recent_links_service.dart';
import '../../../downloader/presentation/providers/download_provider.dart';
import '../../../downloader/presentation/screens/preview_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _urlController = TextEditingController();
  final _focusNode = FocusNode();
  StreamSubscription<String>? _sharedSub;
  List<String> _recentLinks = [];
  String? _lastClipboardOffer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sharedSub =
        IntentService.instance.sharedTextStream.listen(_handleShared);
    _loadRecentLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      final pending = IntentService.instance.consumePending();
      if (pending != null) _handleShared(pending);
      _checkClipboard();
      await _maybeShowOnboarding();
    });
  }

  Future<void> _maybeShowOnboarding() async {
    final settings = ref.read(settingsProvider);
    if (settings.onboardingCompleted || !mounted) return;
    await showOnboarding(context);
    if (!mounted) return;
    await ref
        .read(settingsProvider.notifier)
        .setOnboardingCompleted(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sharedSub?.cancel();
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _loadRecentLinks() async {
    final links = await RecentLinksService.instance.getLinks();
    if (mounted) setState(() => _recentLinks = links);
  }

  Future<void> _checkClipboard() async {
    if (!ref.read(settingsProvider).watchClipboard) return;
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || text == _lastClipboardOffer) return;
    final url = Validators.prepareUrl(text);
    if (url == null) return;
    _lastClipboardOffer = text;
    if (!mounted) return;
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.homeClipboardDetected),
        action: SnackBarAction(
          label: s.downloadButton,
          onPressed: () {
            _urlController.text = url;
            _openPreview(url);
          },
        ),
      ),
    );
  }

  Future<void> _handleShared(String text) async {
    final url = Validators.prepareUrl(text);
    if (url == null) {
      _showError(S.of(context).errorNotRecognized);
      return;
    }
    _urlController.text = url;
    _openPreview(url);
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      _showError(s.errorEnterUrl);
      return;
    }
    final url = Validators.prepareUrl(raw);
    if (url == null) {
      _showError(s.errorInvalidUrl);
      return;
    }
    _openPreview(url);
  }

  void _openPreview(String url) {
    _focusNode.unfocus();
    RecentLinksService.instance.addLink(url).then((_) => _loadRecentLinks());
    final autoStart = ref.read(settingsProvider).autoDownload;
    ref.read(downloadProvider.notifier).reset();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          sourceUrl: url,
          autoStart: autoStart,
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.isNotEmpty) {
      _urlController.text = text;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final version = AppInfoService.instance.version;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          IconButton(
            tooltip: s.historyTitle,
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: s.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _Hero(
                scheme: scheme,
                title: s.homeHeroTitle,
                subtitle: s.homeHeroSubtitle,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _urlController,
                focusNode: _focusNode,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: s.urlFieldHint,
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    tooltip: s.urlFieldPaste,
                    icon: const Icon(Icons.content_paste_outlined),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.download),
                label: Text(s.downloadButton),
              ),
              if (_recentLinks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  s.recentLinksTitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentLinks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final link = _recentLinks[i];
                      final label = link.length > 28
                          ? '${link.substring(0, 28)}…'
                          : link;
                      return ActionChip(
                        label:
                            Text(label, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _urlController.text = link;
                          _openPreview(link);
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _TipCard(text: s.homeTip),
              const Spacer(),
              _Footer(text: s.homeFooter(version)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ColorScheme scheme;
  final String title;
  final String subtitle;
  const _Hero({
    required this.scheme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.collections_outlined,
                size: 32, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        scheme.onPrimaryContainer.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String text;
  const _Footer({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}
