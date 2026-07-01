import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/strings.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/backend_health_service.dart';
import '../../../../services/filename_template_engine.dart';
import '../../../../services/export/cloud/cloud_backup_adapter.dart';
import '../../../../services/export/cloud/cloud_backup_service.dart';
import '../../domain/cloud_backup_config.dart';
import '../../../legal/presentation/screens/privacy_policy_screen.dart';
import 'diagnostics_screen.dart';
import 'watchlist_screen.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../domain/app_settings.dart';
import '../../domain/entitlement.dart';
import '../providers/settings_provider.dart';
import '../providers/entitlement_provider.dart';

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
              if (AppConstants.profileWatchlistEnabled)
                _SchedulerSection(settings: settings, notifier: notifier),
              _FilenameTemplateSection(settings: settings, notifier: notifier),
              _CloudBackupSection(settings: settings, notifier: notifier),
              if (AppConstants.profileWatchlistEnabled)
                ListTile(
                  title: Text(s.watchlistTitle),
                  subtitle: Text(s.watchlistOpenSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            _SectionTitle(text: s.settingsSectionAppearance, scheme: scheme),
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
              _NoteCard(scheme: scheme, text: settings.effectiveBackendUrl),
            const SizedBox(height: 8),
            _NoteCard(scheme: scheme, text: s.settingsBackendNote),
            ListTile(
              title: Text(s.diagnosticsTitle),
              subtitle: Text(s.diagnosticsOpenSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
              ),
            ),
            ListTile(
              title: Text(s.settingsPrivacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
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
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.settingsCleared)));
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
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
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.current,
  );
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
  bool _busy = false;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final entitlement = ref.watch(entitlementProvider);
    final billingAvailable = ref.watch(playBillingAvailableProvider);
    final products = ref.watch(playBillingProductsProvider);
    final notifier = ref.read(entitlementProvider.notifier);
    final settingsNotifier = widget.notifier;

    if (entitlement.isPro) {
      final subtitle = _activeSubtitle(s, entitlement);
      return Card(
        child: ListTile(
          leading: const Icon(Icons.verified, color: Colors.amber),
          title: Text(s.settingsProActive),
          subtitle: Text(subtitle),
          trailing: entitlement.isDemoMode
              ? Chip(label: Text(s.settingsProDemoBadge))
              : null,
        ),
      );
    }

    final product = products.isNotEmpty ? products.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.settingsProInactive),
            const SizedBox(height: 8),
            if (billingAvailable && product != null) ...[
              Text(
                s.settingsProSubscribePrice(product.price),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final ok = await notifier.purchasePro();
                        if (!context.mounted) return;
                        if (ok) {
                          await settingsNotifier.setPro(true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProActivated)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProBillingFailed)),
                          );
                        }
                      }),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.settingsProSubscribe),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await notifier.restorePurchases();
                        if (!context.mounted) return;
                        final active = ref.read(entitlementProvider).isPro;
                        if (active) {
                          await settingsNotifier.setPro(true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProRestored)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProRestoreEmpty)),
                          );
                        }
                      }),
                child: Text(s.settingsProRestore),
              ),
              const Divider(height: 24),
              Text(
                s.settingsProLicenseDivider,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
            ] else if (!billingAvailable) ...[
              _NoteCard(
                scheme: Theme.of(context).colorScheme,
                text: s.settingsProBillingUnavailable,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _licenseCtrl,
              decoration: InputDecoration(hintText: s.settingsProLicenseHint),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: s.semSettingsProActivate,
              button: true,
              child: FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        try {
                          await notifier.activateLicense(_licenseCtrl.text);
                          await settingsNotifier.setPro(true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProActivated)),
                          );
                        } on ArgumentError {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.settingsProInvalidKey)),
                          );
                        }
                      }),
                child: Text(s.settingsProActivate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activeSubtitle(Strings s, EntitlementState entitlement) {
    switch (entitlement.billingSource) {
      case EntitlementBillingSource.googlePlay:
        return s.settingsProActivePlay;
      case EntitlementBillingSource.licenseKey:
        if (entitlement.isDemoMode) return s.settingsProActiveDemo;
        final hint = entitlement.licenseKeyHint;
        if (hint != null) return s.settingsProActiveLicense(hint);
        return s.settingsSchedulerSubtitle;
      case EntitlementBillingSource.none:
        return s.settingsSchedulerSubtitle;
    }
  }
}

class _SchedulerSection extends StatefulWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _SchedulerSection({required this.settings, required this.notifier});

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
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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

class _FilenameTemplateSection extends StatefulWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _FilenameTemplateSection({
    required this.settings,
    required this.notifier,
  });

  @override
  State<_FilenameTemplateSection> createState() =>
      _FilenameTemplateSectionState();
}

class _FilenameTemplateSectionState extends State<_FilenameTemplateSection> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(
      text: widget.settings.customFilenameTemplate,
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final preset = widget.settings.filenameTemplatePreset;
    final preview = FilenameTemplateEngine.preview(
      preset: preset,
      customTemplate: _customController.text,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.settingsFilenameTemplateTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.settingsFilenameTemplateSubtitle,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...FilenameTemplatePreset.values.map(
              (p) => RadioListTile<FilenameTemplatePreset>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_presetLabel(s, p)),
                value: p,
                // ignore: deprecated_member_use
                groupValue: preset,
                // ignore: deprecated_member_use
                onChanged: (v) {
                  if (v == null) return;
                  widget.notifier.setFilenameTemplatePreset(v);
                },
              ),
            ),
            if (preset == FilenameTemplatePreset.custom) ...[
              TextField(
                controller: _customController,
                decoration: InputDecoration(
                  hintText: s.settingsFilenameTemplateCustomHint,
                  helperText: s.settingsFilenameTemplateTokens,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: widget.notifier.setCustomFilenameTemplate,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.notifier.setCustomFilenameTemplate(
                    _customController.text,
                  ),
                  child: Text(s.settingsBackendSave),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              s.settingsFilenameTemplatePreview,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            SelectableText(
              preview,
              style: TextStyle(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _presetLabel(Strings s, FilenameTemplatePreset p) {
    switch (p) {
      case FilenameTemplatePreset.defaultTemplate:
        return s.settingsFilenamePresetDefault;
      case FilenameTemplatePreset.dateFirst:
        return s.settingsFilenamePresetDateFirst;
      case FilenameTemplatePreset.folderStyle:
        return s.settingsFilenamePresetFolder;
      case FilenameTemplatePreset.custom:
        return s.settingsFilenamePresetCustom;
    }
  }
}

class _CloudBackupSection extends StatefulWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _CloudBackupSection({required this.settings, required this.notifier});

  @override
  State<_CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends State<_CloudBackupSection> {
  late CloudBackupConfig _draft;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.settings.cloudBackup;
  }

  @override
  void didUpdateWidget(covariant _CloudBackupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.cloudBackup != widget.settings.cloudBackup) {
      _draft = widget.settings.cloudBackup;
    }
  }

  Future<void> _saveDraft() async {
    await widget.notifier.setCloudBackup(_draft);
  }

  Future<void> _testConnection() async {
    final s = S.of(context);
    setState(() => _testing = true);
    try {
      await CloudBackupService.instance.testConnection(_draft);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.settingsCloudBackupTestOk)));
    } on CloudBackupUnavailableException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsCloudBackupComingSoon(e.message))),
      );
    } on CloudBackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsCloudBackupTestFailed(e.message))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsCloudBackupTestFailed('unknown'))),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.settingsCloudBackupTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.settingsCloudBackupSubtitle,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.settingsCloudBackupEnabled),
              subtitle: Text(s.settingsCloudBackupEnabledSubtitle),
              value: _draft.enabled,
              onChanged: (v) async {
                setState(() => _draft = _draft.copyWith(enabled: v));
                await _saveDraft();
              },
            ),
            DropdownButtonFormField<CloudBackupProvider>(
              // ignore: deprecated_member_use
              value: _draft.provider,
              decoration: InputDecoration(
                labelText: s.settingsCloudBackupProvider,
              ),
              items: [
                DropdownMenuItem(
                  value: CloudBackupProvider.none,
                  child: Text(s.settingsCloudBackupProviderNone),
                ),
                DropdownMenuItem(
                  value: CloudBackupProvider.webdav,
                  child: Text(s.settingsCloudBackupProviderWebDav),
                ),
                DropdownMenuItem(
                  value: CloudBackupProvider.s3,
                  child: Text(s.settingsCloudBackupProviderS3),
                ),
                DropdownMenuItem(
                  value: CloudBackupProvider.googleDrive,
                  child: Text(s.settingsCloudBackupProviderDrive),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _draft = _draft.copyWith(provider: v));
                await _saveDraft();
              },
            ),
            const SizedBox(height: 8),
            if (_draft.provider == CloudBackupProvider.webdav) ...[
              _CloudField(
                label: s.settingsCloudBackupWebDavUrl,
                initial: _draft.webDavUrl,
                onSaved: (v) => _draft = _draft.copyWith(webDavUrl: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupWebDavUser,
                initial: _draft.webDavUsername,
                onSaved: (v) => _draft = _draft.copyWith(webDavUsername: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupWebDavPassword,
                initial: _draft.webDavPassword,
                obscure: true,
                onSaved: (v) => _draft = _draft.copyWith(webDavPassword: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupWebDavPath,
                initial: _draft.webDavBasePath,
                onSaved: (v) => _draft = _draft.copyWith(webDavBasePath: v),
              ),
            ],
            if (_draft.provider == CloudBackupProvider.s3) ...[
              _CloudField(
                label: s.settingsCloudBackupS3Endpoint,
                initial: _draft.s3Endpoint,
                onSaved: (v) => _draft = _draft.copyWith(s3Endpoint: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupS3Bucket,
                initial: _draft.s3Bucket,
                onSaved: (v) => _draft = _draft.copyWith(s3Bucket: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupS3Region,
                initial: _draft.s3Region,
                onSaved: (v) => _draft = _draft.copyWith(s3Region: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupS3Prefix,
                initial: _draft.s3Prefix,
                onSaved: (v) => _draft = _draft.copyWith(s3Prefix: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupS3AccessKey,
                initial: _draft.s3AccessKey,
                onSaved: (v) => _draft = _draft.copyWith(s3AccessKey: v),
              ),
              _CloudField(
                label: s.settingsCloudBackupS3SecretKey,
                initial: _draft.s3SecretKey,
                obscure: true,
                onSaved: (v) => _draft = _draft.copyWith(s3SecretKey: v),
              ),
            ],
            if (_draft.provider == CloudBackupProvider.googleDrive)
              _NoteCard(scheme: scheme, text: s.settingsCloudBackupDriveNote),
            if (_draft.provider != CloudBackupProvider.none &&
                _draft.provider != CloudBackupProvider.googleDrive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await _saveDraft();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.settingsBackendSaved)),
                      );
                    },
                    child: Text(s.settingsBackendSave),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: _testing || !_draft.isConfigured
                        ? null
                        : () async {
                            await _saveDraft();
                            await _testConnection();
                          },
                    child: _testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.settingsCloudBackupTest),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloudField extends StatefulWidget {
  const _CloudField({
    required this.label,
    required this.initial,
    required this.onSaved,
    this.obscure = false,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onSaved;
  final bool obscure;

  @override
  State<_CloudField> createState() => _CloudFieldState();
}

class _CloudFieldState extends State<_CloudField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _CloudField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial &&
        _controller.text != widget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: widget.obscure,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (v) => widget.onSaved(v.trim()),
      onSubmitted: widget.onSaved,
    );
  }
}
