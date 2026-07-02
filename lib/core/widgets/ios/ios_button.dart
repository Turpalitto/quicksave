import 'package:flutter/material.dart';

import '../../theme/ios_tokens.dart';

class IosBlueButton extends StatelessWidget {
  const IosBlueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: IosTokens.blue.withValues(alpha: enabled ? 1 : 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(label, style: IosTokens.headline.copyWith(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IosPressable extends StatefulWidget {
  const IosPressable({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<IosPressable> createState() => _IosPressableState();
}

class _IosPressableState extends State<IosPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.55 : 1,
        child: widget.child,
      ),
    );
  }
}
