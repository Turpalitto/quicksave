import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ios/ios_card.dart';
import '../../../../core/widgets/ios/ios_section.dart';
import '../../../downloader/presentation/providers/download_provider.dart';
import '../../../downloader/presentation/screens/preview_screen.dart';
import '../../../settings/domain/scheduled_profile.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../services/watchlist_service.dart';

class WatchlistTab extends ConsumerStatefulWidget {
  const WatchlistTab({super.key});

  @override
  ConsumerState<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends ConsumerState<WatchlistTab> {
  final _usernameCtrl = TextEditingController();
  bool _adding = false;
  String? _error;
  String? _checkingUsername;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_adding) return;
    final raw = _usernameCtrl.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _adding = true;
      _error = null;
    });

    final input = raw.startsWith('@') ? raw : '@$raw';
    final url = Validators.prepareUrl(input);
    if (url == null) {
      setState(() {
        _adding = false;
        _error = S.of(context).errorNotRecognized;
      });
      return;
    }

    final ok = await ref.read(settingsProvider.notifier).addScheduledProfile(url);
    if (mounted) {
      setState(() {
        _adding = false;
        if (ok) {
          _usernameCtrl.clear();
        } else {
          _error = S.of(context).errorNotRecognized;
        }
      });
    }
  }

  Future<void> _remove(ScheduledProfile profile) async {
    await ref.read(settingsProvider.notifier).removeScheduledProfile(profile.username);
  }

  Future<void> _checkNow(ScheduledProfile profile) async {
    final s = S.of(context);
    final settings = ref.read(settingsProvider);
    setState(() => _checkingUsername = profile.username);

    final result = await WatchlistService.instance.checkProfile(
      profile: profile,
      backendUrl: settings.effectiveBackendUrl,
    );

    final updated = WatchlistService.instance.applyCheckResult(
      profile,
      result,
      error: result.errorCode,
    );
    await ref.read(settingsProvider.notifier).updateScheduledProfile(updated);

    if (!mounted) return;
    setState(() => _checkingUsername = null);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.watchlistCheckFailed)),
      );
      return;
    }

    if (result.newItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.watchlistNoNewItems(result.alreadySavedCount))),
      );
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: IosTokens.elevated,
        title: Text(s.watchlistNewItemsTitle, style: IosTokens.title3),
        content: Text(
          s.watchlistNewItemsBody(result.newItems.length, result.alreadySavedCount),
          style: IosTokens.subhead.copyWith(color: IosTokens.label2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.historyClearConfirmNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.watchlistOpenProfile),
          ),
        ],
      ),
    );

    if (open == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PreviewScreen(sourceUrl: profile.profileUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final profiles = ref.watch(settingsProvider).scheduledProfiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: IosCard(
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text('@', style: TextStyle(color: IosTokens.label3, fontSize: 17)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _usernameCtrl,
                        style: IosTokens.body,
                        decoration: InputDecoration(
                          hintText: s.watchlistAddPlaceholder,
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: _usernameCtrl.text.trim().isEmpty
                    ? IosTokens.blue.withValues(alpha: 0.4)
                    : IosTokens.blue,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _adding || _usernameCtrl.text.trim().isEmpty ? null : _add,
                  child: Center(
                    child: _adding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(_error!, style: IosTokens.footnote.copyWith(color: IosTokens.red)),
          )
        else
          IosSectionFooter(s.watchlistDisclaimer),
        const SizedBox(height: 20),
        if (profiles.isEmpty)
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
                  child: const Icon(Icons.visibility_outlined, color: IosTokens.label3, size: 26),
                ),
                const SizedBox(height: 16),
                Text(s.watchlistEmptyTitle, style: IosTokens.title3),
                const SizedBox(height: 4),
                Text(
                  s.watchlistEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: IosTokens.footnote,
                ),
              ],
            ),
          )
        else ...[
          IosSectionHeader(s.watchlistTracking(profiles.length)),
          IosCard(
            separated: true,
            child: Column(
              children: [
                for (var i = 0; i < profiles.length; i++)
                  _ProfileRow(
                    profile: profiles[i],
                    color: IosTokens.avatarColors[i % IosTokens.avatarColors.length],
                    loading: _checkingUsername == profiles[i].username,
                    onRemove: () => _remove(profiles[i]),
                    onCheck: () => _checkNow(profiles[i]),
                  ),
              ],
            ),
          ),
          IosSectionFooter(s.watchlistFooter),
        ],
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.color,
    required this.onRemove,
    required this.onCheck,
    this.loading = false,
  });

  final ScheduledProfile profile;
  final Color color;
  final VoidCallback onRemove;
  final VoidCallback onCheck;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final initial = profile.username.isNotEmpty
        ? profile.username[0].toUpperCase()
        : '?';
    final subtitle = profile.newItemsFound > 0
        ? s.watchlistNewPosts(profile.newItemsFound)
        : s.watchlistNoNewPosts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(initial, style: IosTokens.subhead.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: loading ? null : onCheck,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${profile.username}', style: IosTokens.body.copyWith(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: IosTokens.footnote),
                ],
              ),
            ),
          ),
          if (profile.newItemsFound > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: IosTokens.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${profile.newItemsFound}',
                style: IosTokens.caption2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel, color: IosTokens.label3, size: 20),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
