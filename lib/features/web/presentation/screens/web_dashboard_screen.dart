import 'package:flutter/material.dart';

import '../../../../core/utils/strings.dart';
import '../../../../services/app_info_service.dart';
import '../widgets/web_library_panel.dart';
import '../widgets/web_resolve_panel.dart';
import '../widgets/web_settings_panel.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _index = 0;

  static const _panels = [
    WebResolvePanel(),
    WebLibraryPanel(),
    WebSettingsPanel(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.webDashboardTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'v${AppInfoService.instance.version}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.link),
                      label: Text(s.webNavResolve),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.collections_bookmark_outlined),
                      label: Text(s.webNavLibrary),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(s.webNavSettings),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _panels[_index]),
              ],
            )
          : Column(
              children: [
                Expanded(child: _panels[_index]),
                NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.link_outlined),
                      selectedIcon: const Icon(Icons.link),
                      label: s.webNavResolve,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.collections_bookmark_outlined),
                      selectedIcon: const Icon(Icons.collections_bookmark),
                      label: s.webNavLibrary,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: s.webNavSettings,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
