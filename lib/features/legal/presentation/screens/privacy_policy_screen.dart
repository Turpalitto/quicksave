import 'package:flutter/material.dart';

import '../../../../core/utils/strings.dart';

/// In-app privacy policy (Google Play requirement).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.privacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.privacyIntro,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(s.privacyBody),
          ],
        ),
      ),
    );
  }
}
