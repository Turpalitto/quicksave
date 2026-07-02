import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shell/presentation/tabs/home_tab.dart';

/// Legacy entry — main app uses [AppShellScreen] with [HomeTab].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: HomeTab(
            onSaved: () {},
            onGoToLibrary: () {},
          ),
        ),
      ),
    );
  }
}
