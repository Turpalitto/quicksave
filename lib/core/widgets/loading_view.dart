import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  final String? detailMessage;
  const LoadingView({super.key, this.message, this.detailMessage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: scheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
          if (detailMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              detailMessage!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
