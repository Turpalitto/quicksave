import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../../../../core/widgets/ios/ios_button.dart';
import '../../../../core/widgets/ios/ios_card.dart';
import '../../../../core/widgets/ios/ios_section.dart';
import '../../../../core/widgets/ios/ios_segment.dart';
import '../../../../core/widgets/ios/ios_switch.dart';
import '../../../../services/app_info_service.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/providers/entitlement_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _emailCtrl = TextEditingController();
  final _selfUrlCtrl = TextEditingController();
  bool _emailLoading = false;
  String? _emailMsg;
  bool _emailOk = false;
  bool _selfUrlInitialized = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _selfUrlCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _selfUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (_emailLoading || !_emailCtrl.text.contains('@')) return;
    setState(() {
      _emailLoading = true;
      _emailMsg = null;
    });

    try {
      final settings = ref.read(settingsProvider);
      final backend = settings.effectiveBackendUrl.replaceAll(
        RegExp(r'/$'),
        '',
      );
      final dio = Dio();
      await dio.post(
        '$backend/api/waitlist',
        data: {'email': _emailCtrl.text.trim(), 'plan': 'pro'},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;
      setState(() {
        _emailLoading = false;
        _emailOk = true;
        _emailMsg = S.of(context).settingsWaitlistOk;
        _emailCtrl.clear();
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('quicksave.waitlist') ?? [];
      list.add(_emailCtrl.text.trim());
      await prefs.setStringList('quicksave.waitlist', list);
      if (!mounted) return;
      setState(() {
        _emailLoading = false;
        _emailOk = true;
        _emailMsg = S.of(context).settingsWaitlistOk;
        _emailCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final entitlement = ref.watch(entitlementProvider);

    if (!_selfUrlInitialized && settings.backendUrl.isNotEmpty) {
      _selfUrlCtrl.text = settings.backendUrl;
      _selfUrlInitialized = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IosPressable(
          onTap: () => ref.read(entitlementProvider.notifier).purchasePro(),
          child: IosCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: IosTokens.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_downward, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.settingsProTitle, style: IosTokens.headline),
                      Text(s.settingsProSubtitle, style: IosTokens.footnote),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: IosTokens.blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    s.settingsProPrice,
                    style: IosTokens.subhead.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!entitlement.isPro)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              s.settingsProInactive,
              style: IosTokens.caption1.copyWith(color: IosTokens.orange),
            ),
          ),
        const SizedBox(height: 24),
        IosSectionHeader(s.settingsSectionStorage),
        IosCard(
          separated: true,
          child: Column(
            children: [
              _SettingsRow(
                color: IosTokens.green,
                icon: Icons.photo_outlined,
                label: s.settingsSaveToGallery,
                trailing: IosSwitch(
                  value: settings.saveToGallery,
                  onChanged: notifier.setSaveToGallery,
                  semanticLabel: s.settingsSaveToGallery,
                ),
              ),
              _SettingsRow(
                color: IosTokens.red,
                icon: Icons.notifications_outlined,
                label: s.settingsNotifications,
                trailing: IosSwitch(
                  value: settings.notificationsEnabled,
                  onChanged: notifier.setNotifications,
                  semanticLabel: s.settingsNotifications,
                ),
              ),
            ],
          ),
        ),
        IosSectionFooter(s.settingsStorageFooter),
        const SizedBox(height: 24),
        IosSectionHeader(s.settingsSectionServer),
        IosCard(
          separated: true,
          child: Column(
            children: [
              _SettingsRow(
                color: IosTokens.blue,
                icon: Icons.public,
                label: s.settingsBackendModeHosted,
                value: settings.backendMode == BackendMode.hosted
                    ? s.settingsHostedOn
                    : null,
                onTap: () => notifier.setBackendMode(BackendMode.hosted),
              ),
              _SettingsRow(
                color: IosTokens.purple,
                icon: Icons.dns_outlined,
                label: s.settingsBackendModeSelf,
                value: settings.backendMode == BackendMode.selfHosted
                    ? s.settingsHostedOn
                    : null,
                onTap: settings.canSelfHost
                    ? () => notifier.setBackendMode(BackendMode.selfHosted)
                    : null,
              ),
            ],
          ),
        ),
        if (settings.backendMode == BackendMode.selfHosted) ...[
          const SizedBox(height: 8),
          IosCard(
            child: TextField(
              controller: _selfUrlCtrl,
              style: IosTokens.callout,
              decoration: const InputDecoration(
                hintText: 'https://my-server.example.com',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: notifier.setBackendUrl,
              onEditingComplete: () =>
                  notifier.setBackendUrl(_selfUrlCtrl.text.trim()),
            ),
          ),
        ] else
          IosSectionFooter(s.settingsHostedFooter),
        const SizedBox(height: 24),
        IosSectionHeader(s.settingsSectionLanguage),
        IosSegment<AppLocale>(
          segments: const [AppLocale.ru, AppLocale.en],
          selected: settings.locale == AppLocale.en
              ? AppLocale.en
              : AppLocale.ru,
          onChanged: notifier.setLocale,
          labelBuilder: (l) => l == AppLocale.ru ? 'Русский' : 'English',
        ),
        const SizedBox(height: 24),
        IosSectionHeader(s.settingsSectionAppearance),
        IosSegment<AppThemeMode>(
          segments: const [AppThemeMode.dark, AppThemeMode.light],
          selected: settings.themeMode == AppThemeMode.light
              ? AppThemeMode.light
              : AppThemeMode.dark,
          onChanged: notifier.setThemeMode,
          labelBuilder: (mode) => mode == AppThemeMode.light ? 'Light' : 'Dark',
        ),
        const SizedBox(height: 24),
        IosSectionHeader(s.settingsSectionAndroid),
        IosCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.settingsWaitlistHint, style: IosTokens.footnote),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: IosTokens.callout,
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        filled: true,
                        fillColor: IosTokens.fill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: IosBlueButton(
                      label: 'OK',
                      loading: _emailLoading,
                      onPressed: _emailCtrl.text.contains('@')
                          ? _subscribe
                          : null,
                    ),
                  ),
                ],
              ),
              if (_emailMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  _emailMsg!,
                  style: IosTokens.footnote.copyWith(
                    color: _emailOk ? IosTokens.green : IosTokens.red,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        IosCard(
          separated: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.settingsVersion, style: IosTokens.body),
                    Text(
                      AppInfoService.instance.version,
                      style: IosTokens.body.copyWith(color: IosTokens.label2),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/Turpalitto/quicksave'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.settingsGithub,
                          style: IosTokens.body.copyWith(color: IosTokens.blue),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: IosTokens.label3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IosSectionFooter(s.settingsLegalFooter, center: true),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          child: Text(
            s.settingsAdvanced,
            style: IosTokens.subhead.copyWith(color: IosTokens.blue),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.color,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: IosTokens.body)),
          if (value != null)
            Text(
              value!,
              style: IosTokens.body.copyWith(color: IosTokens.label2),
            ),
          ?trailing,
          if (onTap != null && trailing == null)
            const Icon(Icons.chevron_right, size: 16, color: IosTokens.label3),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}
