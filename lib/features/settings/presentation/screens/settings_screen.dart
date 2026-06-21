import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/backend_health_service.dart';
import '../../../../services/pro_service.dart';
import '../../../legal/presentation/screens/privacy_policy_screen.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../domain/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(text: s.settingsSectionBehavior, scheme: scheme),
            _SwitchTile(
              title: s.settingsAutoDownload,
              subtitle: s.settingsAutoDownloadSubtitle,
              value: settings.autoDownload,
              onChanged: notifier.setAutoDownload,
            ),
            _SwitchTile(
              title: s.settingsNotifications,
              subtitle: s.settingsNotificationsSubtitle,
              value: settings.notificationsEnabled,
              onChanged: notifier.setNotifications,
            ),
            _SwitchTile(
              title: s.settingsSaveHistory,
              subtitle: s.settingsSaveHistorySubtitle,
              value: settings.saveHistory,
              onChanged: notifier.setSaveHistory,
            ),
            _SwitchTile(
              title: s.settingsWatchClipboard,
              subtitle: s.settingsWatchClipboardSubtitle,
              value: settings.watchClipboard,
              onChanged: notifier.setWatchClipboard,
            ),
            _SwitchTile(
              title: s.settingsSaveInAuthorFolder,
              subtitle: s.settingsSaveInAuthorFolderSubtitle,
              value: settings.saveInAuthorFolder,
              onChanged: notifier.setSaveInAuthorFolder,
            ),
            _SwitchTile(
              title: s.settingsSaveToGallery,
              subtitle: s.settingsSaveToGallerySubtitle,
              value: settings.saveToGallery,
              onChanged: notifier.setSaveToGallery,
            ),
            const SizedBox(height: 16),
            _SectionTitle(text: s.settingsSectionPro, scheme: scheme),
            _ProSection(settings: settings, notifier: notifier),
            if (settings.isPro) ...[
              const SizedBox(height: 8),
              _SchedulerSection(settings: settings, notifier: notifier),
            ],
            const SizedBox(height: 16),
            _SectionTitle(
                text: s.settingsSectionAppearance, scheme: scheme),
            _ThemeSelector(
              current: settings.themeMode,
              onChanged: notifier.setThemeMode,
            ),
            const SizedBox(height: 16),
            _SectionTitle(text: s.settingsSectionBackend, scheme: scheme),
            _BackendModeSelector(
              current: settings.backendMode,
              canSelfHost: settings.canSelfHost,
              onChanged: notifier.setBackendMode,
            ),
            if (settings.backendMode == BackendMode.selfHosted)
              _BackendField(
                current: settings.backendUrl,
                onSubmit: notifier.setBackendUrl,
              )
            else
              _NoteCard(
                scheme: scheme,
                text: settings.effectiveBackendUrl,
              ),
            const SizedBox(height: 8),
            _NoteCard(scheme: scheme, text: s.settingsBackendNote),
            ListTile(
              title: Text(s.settingsPrivacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: s.settingsSectionData, scheme: scheme),
            _DangerTile(
              title: s.settingsClearHistory,
              subtitle: s.settingsClearHistorySubtitle,
              icon: Icons.delete_sweep_outlined,
              onTap: () => _confirmClear(context, ref),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'QuickSave • v${AppInfoService.instance.version}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsCleared)),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  const _SectionTitle({required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      toggled: value,
      child: Card(
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onChanged;
  const _ThemeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = {
      AppThemeMode.system: s.settingsThemeSystem,
      AppThemeMode.light: s.settingsThemeLight,
      AppThemeMode.dark: s.settingsThemeDark,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SegmentedButton<AppThemeMode>(
          segments: [
            for (final mode in AppThemeMode.values)
              ButtonSegment(
                value: mode,
                label: Text(labels[mode] ?? mode.name),
              ),
          ],
          selected: {current},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) onChanged(selected.first);
          },
        ),
      ),
    );
  }
}

class _BackendField extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSubmit;
  const _BackendField({required this.current, required this.onSubmit});

  @override
  State<_BackendField> createState() => _BackendFieldState();
}

class _BackendFieldState extends State<_BackendField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.current);
  bool _testing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final s = S.of(context);
    final ok = await BackendHealthService.instance.ping(_ctrl.text.trim());
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? s.settingsBackendOnline : s.settingsBackendOffline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: s.settingsBackendUrlLabel,
                hintText: s.settingsBackendUrlHint,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(s.settingsBackendTest),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    widget.onSubmit(_ctrl.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.settingsBackendSaved)),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: Text(s.settingsBackendSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendModeSelector extends StatelessWidget {
  final BackendMode current;
  final bool canSelfHost;
  final ValueChanged<BackendMode> onChanged;

  const _BackendModeSelector({
    required this.current,
    required this.canSelfHost,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      label: s.settingsBackendModeHosted,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<BackendMode>(
            segments: [
              ButtonSegment(
                value: BackendMode.hosted,
                label: Text(s.settingsBackendModeHosted),
              ),
              ButtonSegment(
                value: BackendMode.selfHosted,
                label: Text(s.settingsBackendModeSelf),
                enabled: canSelfHost,
              ),
            ],
            selected: {current},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) onChanged(selected.first);
            },
          ),
        ),
      ),
    );
  }
}

class _ProSection extends ConsumerStatefulWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _ProSection({required this.settings, required this.notifier});

  @override
  ConsumerState<_ProSection> createState() => _ProSectionState();
}

class _ProSectionState extends ConsumerState<_ProSection> {
  final _licenseCtrl = TextEditingController();

  @override
  void dispose() {
    _licenseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = widget.settings;

    if (settings.isPro) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.verified, color: Colors.amber),
          title: Text(s.settingsProActive),
          subtitle: Text(s.settingsSchedulerSubtitle),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.settingsProInactive),
            const SizedBox(height: 8),
            TextField(
              controller: _licenseCtrl,
              decoration: InputDecoration(hintText: s.settingsProLicenseHint),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: s.semSettingsProActivate,
              button: true,
              child: FilledButton(
                onPressed: () async {
                  final ok = ProService.instance
                      .validateLicenseKey(_licenseCtrl.text);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.settingsProInvalidKey)),
                    );
                    return;
                  }
                  await widget.notifier.setPro(true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.settingsProActivated)),
                  );
                },
                child: Text(s.settingsProActivate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulerSection extends StatefulWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _SchedulerSection({
    required this.settings,
    required this.notifier,
  });

  @override
  State<_SchedulerSection> createState() => _SchedulerSectionState();
}

class _SchedulerSectionState extends State<_SchedulerSection> {
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addProfile() async {
    final raw = _usernameCtrl.text.trim();
    if (raw.isEmpty) return;
    await widget.notifier.addScheduledProfile(raw);
    _usernameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final profiles = widget.settings.scheduledProfiles;

    return Semantics(
      label: s.settingsSchedulerTitle,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.settingsSchedulerTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                s.settingsSchedulerSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        hintText: s.settingsSchedulerAddHint,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addProfile(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: s.semSettingsSchedulerAdd,
                    button: true,
                    child: IconButton.filled(
                      onPressed: _addProfile,
                      icon: const Icon(Icons.add),
                      tooltip: s.settingsSchedulerTitle,
                    ),
                  ),
                ],
              ),
            if (profiles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.settingsSchedulerAddHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...profiles.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alternate_email, size: 20),
                  title: Text('@${p.username}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        widget.notifier.removeScheduledProfile(p.username),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ColorScheme scheme;
  final String text;
  const _NoteCard({required this.scheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _DangerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.error),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
