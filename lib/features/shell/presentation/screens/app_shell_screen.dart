import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/ios_tokens.dart';
import '../../../../core/utils/strings.dart';
import '../tabs/home_tab.dart';
import '../tabs/library_tab.dart';
import '../tabs/settings_tab.dart';
import '../tabs/watchlist_tab.dart';

enum AppTab { home, library, watchlist, settings }

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  AppTab _tab = AppTab.home;
  int _libraryVersion = 0;

  String _title(BuildContext context) {
    final s = S.of(context);
    return switch (_tab) {
      AppTab.home => s.appTitle,
      AppTab.library => s.libraryTitle,
      AppTab.watchlist => s.watchlistTitle,
      AppTab.settings => s.settingsTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellBg = isDark ? IosTokens.bg : const Color(0xFFF2F2F7);
    final titleStyle = IosTokens.largeTitle.copyWith(
      color: isDark ? IosTokens.label : Colors.black,
    );

    return Scaffold(
      backgroundColor: isDesktop ? (isDark ? IosTokens.desktopBg : shellBg) : shellBg,
      body: Stack(
        children: [
          if (isDesktop)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1),
                    radius: 1.2,
                    colors: [
                      IosTokens.blue.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 430 : double.infinity,
                maxHeight: isDesktop ? 900 : double.infinity,
              ),
              child: Container(
                margin: isDesktop ? const EdgeInsets.symmetric(vertical: 32) : null,
                decoration: isDesktop
                    ? BoxDecoration(
                        color: shellBg,
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 100,
                            offset: const Offset(0, 40),
                          ),
                        ],
                      )
                    : null,
                clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: const Cubic(0.25, 0.1, 0.25, 1),
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _title(context),
                                          style: titleStyle,
                                        ),
                                      ),
                                      if (_tab == AppTab.home)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            children: [
                                              _PulsingDot(),
                                              const SizedBox(width: 6),
                                              Text(
                                                S.of(context).homeOnline,
                                                style: IosPalette.of(context).caption1,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                                sliver: SliverToBoxAdapter(
                                  child: switch (_tab) {
                                    AppTab.home => HomeTab(
                                      onSaved: () => setState(() => _libraryVersion++),
                                      onGoToLibrary: () =>
                                          setState(() => _tab = AppTab.library),
                                    ),
                                    AppTab.library => LibraryTab(version: _libraryVersion),
                                    AppTab.watchlist => const WatchlistTab(),
                                    AppTab.settings => const SettingsTab(),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _IosTabBar(
                      selected: _tab,
                      onChanged: (tab) => setState(() => _tab = tab),
                      roundedBottom: isDesktop,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: IosTokens.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  const _IosTabBar({
    required this.selected,
    required this.onChanged,
    this.roundedBottom = false,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onChanged;
  final bool roundedBottom;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = IosPalette.of(context);
    final items = <(AppTab, String, IconData, IconData)>[
      (AppTab.home, s.tabHome, Icons.arrow_downward_outlined, Icons.arrow_downward),
      (AppTab.library, s.webNavLibrary, Icons.grid_view_outlined, Icons.grid_view),
      (AppTab.watchlist, s.watchlistTitle, Icons.visibility_outlined, Icons.visibility),
      (AppTab.settings, s.settingsTitle, Icons.settings_outlined, Icons.settings),
    ];

    return ClipRRect(
      borderRadius: roundedBottom
          ? const BorderRadius.vertical(bottom: Radius.circular(38))
          : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.blurBar,
            border: Border(top: BorderSide(color: palette.separator, width: 0.5)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom
                  : 8,
              top: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final active = selected == item.$1;
                return Expanded(
                  child: InkWell(
                    onTap: () => onChanged(item.$1),
                    child: Opacity(
                      opacity: active ? 1 : 0.55,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? item.$4 : item.$3,
                            size: 26,
                            color: active ? IosTokens.blue : palette.label3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: active ? IosTokens.blue : palette.label3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
