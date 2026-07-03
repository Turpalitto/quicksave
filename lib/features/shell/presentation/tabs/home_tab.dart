import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ios/ios_button.dart';
import '../../../../core/widgets/ios/ios_card.dart';
import '../../../../core/widgets/ios/ios_section.dart';
import '../../../../services/intent_service.dart';
import '../../../../services/recent_links_service.dart';
import '../../../downloader/domain/resolve_result.dart';
import '../../../downloader/presentation/providers/download_provider.dart';
import '../../../downloader/presentation/screens/preview_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../home/presentation/widgets/pending_downloads_section.dart';
import '../../../../services/pending_download_service.dart';
import '../../../downloader/presentation/providers/pending_download_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({
    super.key,
    required this.onSaved,
    required this.onGoToLibrary,
  });

  final VoidCallback onSaved;
  final VoidCallback onGoToLibrary;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with WidgetsBindingObserver {
  final _urlController = TextEditingController();
  StreamSubscription<String>? _sharedSub;
  String? _lastClipboardOffer;
  String? _inlineError;

  static const _examples = [
    ('post', 'https://instagram.com/p/C8xKq2Lt9Ab/'),
    ('reel', 'https://instagram.com/reel/C9mPz4Xw7Qr/'),
    ('profile', '@natgeo'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sharedSub = IntentService.instance.sharedTextStream.listen(_handleShared);
    _urlController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      final pending = IntentService.instance.consumePending();
      if (pending != null) _handleShared(pending);
      _checkClipboard();
      await _maybeShowOnboarding();
      _consumeUrlQuery();
    });
  }

  void _consumeUrlQuery() {
    final url = Uri.base.queryParameters['url'];
    if (url == null || url.isEmpty) return;
    _urlController.text = url;
    _resolve(url);
  }

  Future<void> _maybeShowOnboarding() async {
    final settings = ref.read(settingsProvider);
    if (settings.onboardingCompleted || !mounted) return;
    await showOnboarding(context);
    if (!mounted) return;
    await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sharedSub?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
      _processPendingQueue();
    }
  }

  Future<void> _processPendingQueue() async {
    await ref.read(pendingDownloadsProvider.notifier).refresh();
    final pending = ref.read(pendingDownloadsProvider);
    if (pending.isEmpty) return;
    for (final item in pending) {
      if (item.attempts >= PendingDownloadService.maxAttempts) continue;
      final ok = await ref
          .read(downloadProvider.notifier)
          .retryPendingUrl(item.sourceUrl);
      if (ok) {
        await ref
            .read(pendingDownloadsProvider.notifier)
            .removeByUrl(item.sourceUrl);
        if (ref.read(settingsProvider).autoDownload) {
          await _download();
        }
        widget.onSaved();
        break;
      }
    }
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
            _resolve(url);
          },
        ),
      ),
    );
  }

  Future<void> _handleShared(String text) async {
    final url = Validators.prepareUrl(text);
    if (url == null) {
      setState(() => _inlineError = S.of(context).errorNotRecognized);
      return;
    }
    _urlController.text = url;
    await _resolve(url);
  }

  Future<void> _submit([String? value]) async {
    final s = S.of(context);
    final raw = (value ?? _urlController.text).trim();
    if (raw.isEmpty) {
      setState(() => _inlineError = s.errorEnterUrl);
      return;
    }
    final url = Validators.prepareUrl(raw);
    if (url == null) {
      setState(() => _inlineError = s.errorInvalidUrl);
      return;
    }
    await _resolve(url);
  }

  Future<void> _resolve(String url) async {
    setState(() => _inlineError = null);
    RecentLinksService.instance.addLink(url);
    ref.read(downloadProvider.notifier).reset();
    await ref.read(downloadProvider.notifier).resolve(url);
    final state = ref.read(downloadProvider);
    if (state is DownloadFailureState && mounted) {
      setState(() => _inlineError = state.failure.message);
    }
    if (ref.read(settingsProvider).autoDownload &&
        ref.read(downloadProvider) is DownloadResolved) {
      await _download();
    }
  }

  Future<void> _download() async {
    final s = S.of(context);
    await ref.read(downloadProvider.notifier).download(
      strings: DownloadStrings(
        completeTitle: s.notificationDownloadCompleteTitle,
        completeBodyAuthorPrefix: s.notificationDownloadAuthorPrefix,
        completeBodyFallback: s.notificationDownloadCompleteBodyFallback,
        errorTitle: s.notificationDownloadErrorTitle,
        batchCompleteBody: s.previewBatchSaved('{count}'),
        channelName: s.notificationChannelDownloads,
        channelDescription: s.notificationChannelDownloadsDesc,
      ),
    );
    if (ref.read(downloadProvider) is DownloadSuccess) {
      widget.onSaved();
    }
  }

  void _clearInput() {
    _urlController.clear();
    ref.read(downloadProvider.notifier).reset();
    setState(() => _inlineError = null);
  }

  void _openFullPreview(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          sourceUrl: url,
          autoStart: ref.read(settingsProvider).autoDownload,
        ),
      ),
    ).then((_) => widget.onSaved());
  }

  String _exampleLabel(String key, Strings s) => switch (key) {
    'post' => s.examplePost,
    'reel' => s.exampleReels,
    _ => s.exampleProfile,
  };

  String _kindLabel(ResolveResult result, Strings s) => switch (result.type) {
    ResolveType.carousel => s.previewTypeCarousel(result.items.length),
    ResolveType.story => s.previewTypeStory,
    ResolveType.highlight => s.previewTypeHighlight(result.items.length),
    ResolveType.profile => s.previewTypeProfile(result.items.length),
    ResolveType.single => result.items.first.isVideo
        ? s.libraryFilterReels
        : s.previewTypeSingle,
  };

  Color _kindColor(ResolveResult result) => switch (result.type) {
    ResolveType.profile => IosTokens.green,
    ResolveType.story => IosTokens.orange,
    ResolveType.highlight => IosTokens.purple,
    ResolveType.carousel => IosTokens.blue,
    ResolveType.single =>
      result.items.first.isVideo ? IosTokens.pink : IosTokens.blue,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = IosPalette.of(context);
    final dlState = ref.watch(downloadProvider);
    final hasInput = _urlController.text.trim().isNotEmpty;
    final resolving = dlState is DownloadResolving;
    final resolved = dlState is DownloadResolved ? dlState : null;
    final inProgress = dlState is DownloadInProgress ? dlState : null;
    final success = dlState is DownloadSuccess;
    final failure = dlState is DownloadFailureState ? dlState : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PendingDownloadsSection(),
        const SizedBox(height: 20),
        IosCard(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.link, size: 17, color: p.label3),
              ),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: p.body,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: _submit,
                  decoration: InputDecoration(
                    hintText: s.urlFieldHint,
                    hintStyle: p.body.copyWith(color: p.label3),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (hasInput)
                IconButton(
                  icon: Icon(Icons.cancel, size: 17, color: p.label3),
                  onPressed: _clearInput,
                ),
            ],
          ),
        ),
        IosSectionFooter(s.homeInputFooter),
        const SizedBox(height: 20),
        IosBlueButton(
          label: s.homeFindMedia,
          loading: resolving,
          onPressed: hasInput && !resolving ? () => _submit() : null,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(s.homeExamples, style: p.footnote),
            for (final ex in _examples)
              IosPressable(
                onTap: resolving
                    ? () {}
                    : () {
                        _urlController.text = ex.$2;
                        _submit(ex.$2);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.fill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _exampleLabel(ex.$1, s),
                    style: p.footnote.copyWith(
                      color: IosTokens.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_inlineError != null || failure != null) ...[
          const SizedBox(height: 16),
          IosCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: IosTokens.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: IosTokens.red, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _inlineError ?? failure!.failure.message,
                    style: p.subhead.copyWith(color: p.label2),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (resolved != null && !resolving) ...[
          const SizedBox(height: 20),
          IosSectionHeader(s.homeFound),
          IosCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kindColor(resolved.result),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          resolved.result.isProfile
                              ? Icons.person
                              : resolved.result.items.first.isVideo
                              ? Icons.play_arrow
                              : Icons.image_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_kindLabel(resolved.result, s), style: p.headline),
                            Text(
                              [
                                if (resolved.result.author != null)
                                  '@${resolved.result.author}',
                                '${resolved.result.items.length} медиа',
                              ].join(' · '),
                              style: p.footnote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: IosTokens.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.homePublic,
                          style: IosTokens.caption2.copyWith(
                            color: IosTokens.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildDownloadArea(
                    s,
                    resolved: resolved,
                    inProgress: inProgress,
                    success: success,
                  ),
                ),
                if (resolved.result.isCollection || resolved.result.isProfile)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextButton(
                      onPressed: () => _openFullPreview(resolved.sourceUrl),
                      child: Text(
                        s.previewTitle,
                        style: IosTokens.subhead.copyWith(color: IosTokens.blue),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (success)
            IosSectionFooter(s.homeHowFooter),
        ],
        const SizedBox(height: 28),
        IosSectionHeader(s.homeHowItWorks),
        IosCard(
          separated: true,
          child: Column(
            children: [
              _HowStep(number: '1', title: s.homeHowStep1Title, subtitle: s.homeHowStep1Sub),
              _HowStep(number: '2', title: s.homeHowStep2Title, subtitle: s.homeHowStep2Sub),
              _HowStep(number: '3', title: s.homeHowStep3Title, subtitle: s.homeHowStep3Sub),
            ],
          ),
        ),
        IosSectionFooter(s.homeHowFooter),
      ],
    );
  }

  Widget _buildDownloadArea(
    Strings s, {
    required DownloadResolved resolved,
    required DownloadInProgress? inProgress,
    required bool success,
  }) {
    final p = IosPalette.of(context);
    if (success) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: IosTokens.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.homeSaved,
              style: p.subhead.copyWith(
                color: IosTokens.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IosPressable(
            onTap: widget.onGoToLibrary,
            child: Text(
              s.homeGoToLibrary,
              style: p.subhead.copyWith(color: IosTokens.blue),
            ),
          ),
        ],
      );
    }

    if (inProgress != null) {
      final pct = (inProgress.overallProgress * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.homeDownloading, style: p.subhead),
              Text('$pct%', style: p.subhead.copyWith(color: p.label2)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: inProgress.overallProgress,
              minHeight: 4,
              backgroundColor: p.fill2,
              color: IosTokens.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(s.homeResumeNote, style: p.caption1),
        ],
      );
    }

    final count = resolved.result.items.length;
    return IosBlueButton(
      label: count > 1 ? '${s.downloadButton} ($count)' : s.downloadButton,
      onPressed: _download,
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = IosPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.fill,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: p.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: p.subhead.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(subtitle, style: p.footnote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
