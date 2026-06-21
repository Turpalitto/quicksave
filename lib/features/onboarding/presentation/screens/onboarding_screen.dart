import 'package:flutter/material.dart';

import '../../../../core/utils/strings.dart';

/// Первый запуск: подсказки Share Intent, Quick Settings tile, Gallery.
Future<void> showOnboarding(BuildContext context) {
  final s = S.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.onboardingTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _OnboardStep(
              icon: Icons.ios_share,
              title: s.onboardingShareTitle,
              body: s.onboardingShareBody,
            ),
            const SizedBox(height: 12),
            _OnboardStep(
              icon: Icons.grid_view_rounded,
              title: s.onboardingTileTitle,
              body: s.onboardingTileBody,
            ),
            const SizedBox(height: 12),
            _OnboardStep(
              icon: Icons.photo_library_outlined,
              title: s.onboardingGalleryTitle,
              body: s.onboardingGalleryBody,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.onboardingGotIt),
            ),
          ],
        ),
      );
    },
  );
}

class _OnboardStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
