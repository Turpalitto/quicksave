import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../../services/backend_health_service.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class WebSettingsPanel extends ConsumerStatefulWidget {
  const WebSettingsPanel({super.key});

  @override
  ConsumerState<WebSettingsPanel> createState() => _WebSettingsPanelState();
}

class _WebSettingsPanelState extends ConsumerState<WebSettingsPanel> {
  final _backendCtrl = TextEditingController();
  BackendHealthResult? _health;
  bool _checking = false;

  @override
  void dispose() {
    _backendCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkHealth(String url) async {
    setState(() => _checking = true);
    final result = await BackendHealthService.instance.checkHealth(url);
    if (mounted) {
      setState(() {
        _health = result;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    if (_backendCtrl.text.isEmpty && settings.backendUrl.isNotEmpty) {
      _backendCtrl.text = settings.backendUrl;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.webSettingsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(s.webSettingsSubtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        SegmentedButton<BackendMode>(
          segments: [
            ButtonSegment(
              value: BackendMode.hosted,
              label: Text(s.settingsBackendModeHosted),
            ),
            ButtonSegment(
              value: BackendMode.selfHosted,
              label: Text(s.settingsBackendModeSelf),
            ),
          ],
          selected: {settings.backendMode},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) notifier.setBackendMode(selected.first);
          },
        ),
        const SizedBox(height: 16),
        if (settings.backendMode == BackendMode.selfHosted)
          TextField(
            controller: _backendCtrl,
            decoration: InputDecoration(
              labelText: s.settingsBackendUrlLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: notifier.setBackendUrl,
          )
        else
          Card(
            child: ListTile(
              title: Text(s.settingsBackendModeHosted),
              subtitle: Text(settings.effectiveBackendUrl),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: settings.backendMode == BackendMode.selfHosted
                  ? () => notifier.setBackendUrl(_backendCtrl.text.trim())
                  : null,
              child: Text(s.settingsBackendSave),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _checking
                  ? null
                  : () => _checkHealth(settings.effectiveBackendUrl),
              child: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.webSettingsCheckBackend),
            ),
          ],
        ),
        if (_health != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _health!.available ? Icons.cloud_done : Icons.cloud_off,
                color: _health!.available ? scheme.primary : scheme.error,
              ),
              title: Text(
                _health!.available
                    ? s.webSettingsBackendOk
                    : s.webSettingsBackendFail,
              ),
              subtitle: Text(
                _health!.latencyMs != null
                    ? '${_health!.latencyMs} ms'
                    : (_health!.error ?? ''),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          color: scheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.webSettingsPrivacyNote),
          ),
        ),
      ],
    );
  }
}
