import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../downloader/presentation/screens/preview_screen.dart';
import '../../domain/scheduled_profile.dart';
import '../../../../services/watchlist_service.dart';
import '../providers/settings_provider.dart';

/// Watchlist for public profiles — manual / low-frequency checks only.
class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  String? _checkingUsername;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.watchlistCheckFailed)));
      return;
    }

    if (result.newItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.watchlistNoNewItems(result.alreadySavedCount)),
        ),
      );
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.watchlistNewItemsTitle),
        content: Text(
          s.watchlistNewItemsBody(
            result.newItems.length,
            result.alreadySavedCount,
          ),
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
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.watchlistTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  s.watchlistDisclaimer,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...settings.scheduledProfiles.map(
              (p) => _ProfileCard(
                profile: p,
                loading: _checkingUsername == p.username,
                onToggle: (v) =>
                    notifier.updateScheduledProfile(p.copyWith(enabled: v)),
                onCheckNow: () => _checkNow(p),
              ),
            ),
            if (settings.scheduledProfiles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.watchlistEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onToggle,
    required this.onCheckNow,
    this.loading = false,
  });

  final ScheduledProfile profile;
  final ValueChanged<bool> onToggle;
  final VoidCallback onCheckNow;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(value: profile.enabled, onChanged: onToggle),
              ],
            ),
            Text(
              profile.profileUrl,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('${s.watchlistFrequency}: ${profile.frequency.storageValue}'),
            if (profile.lastCheckedAt != null)
              Text(
                '${s.watchlistLastChecked}: ${profile.lastCheckedAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (profile.newItemsFound > 0)
              Text(
                s.watchlistNewItemsCount(profile.newItemsFound),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            if (profile.lastError != null)
              Text(
                profile.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: loading ? null : onCheckNow,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(s.watchlistCheckNow),
            ),
          ],
        ),
      ),
    );
  }
}
