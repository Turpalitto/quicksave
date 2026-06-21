import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/strings.dart';
import '../../../../services/app_info_service.dart';
import '../../../../services/backend_health_service.dart';
import '../providers/settings_provider.dart';

/// Privacy-safe local diagnostics (no URLs, no PII).
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  BackendHealthResult? _hostedHealth;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final settings = ref.read(settingsProvider);
    final hosted = await BackendHealthService.instance.checkHealth(
      settings.effectiveBackendUrl,
    );
    BackendHealthResult? selfHosted;
    if (settings.backendMode.name == 'selfHosted') {
      selfHosted = await BackendHealthService.instance.checkHealth(
        settings.backendUrl,
      );
    }
    if (!mounted) return;
    setState(() {
      _hostedHealth = hosted;
      _loading = false;
    });
    BackendHealthService.instance.lastHostedResult = hosted;
    BackendHealthService.instance.lastSelfHostedResult = selfHosted;
  }

  Future<void> _copyDiagnostics() async {
    final settings = ref.read(settingsProvider);
    final info = AppInfoService.instance;
    final lines = [
      'QuickSave Diagnostics',
      'appVersion: ${info.version}',
      'backendMode: ${settings.backendMode.name}',
      'hostedAvailable: ${_hostedHealth?.available ?? false}',
      'hostedLatencyMs: ${_hostedHealth?.latencyMs}',
      'hostedVersion: ${_hostedHealth?.version}',
      'lastSuccessfulCheck: ${BackendHealthService.instance.lastSuccessfulCheck}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).diagnosticsCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.diagnosticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: s.diagnosticsRefresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row(s.diagnosticsAppVersion, AppInfoService.instance.version),
                _row(s.diagnosticsBackendMode, settings.backendMode.name),
                _row(
                  s.diagnosticsHostedStatus,
                  _hostedHealth?.available == true
                      ? s.diagnosticsAvailable
                      : s.diagnosticsUnavailable,
                ),
                if (_hostedHealth?.latencyMs != null)
                  _row(s.diagnosticsLatency, '${_hostedHealth!.latencyMs} ms'),
                if (_hostedHealth?.version != null)
                  _row(s.diagnosticsBackendVersion, _hostedHealth!.version!),
                const SizedBox(height: 24),
                Text(
                  s.diagnosticsPrivacyNote,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _copyDiagnostics,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(s.diagnosticsCopy),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
