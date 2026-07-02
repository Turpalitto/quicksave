import 'package:flutter/material.dart';

import '../../theme/ios_tokens.dart';

class IosSwitch extends StatelessWidget {
  const IosSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 51,
          height: 31,
          decoration: BoxDecoration(
            color: value ? IosTokens.green : IosTokens.fill2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: const Cubic(0.25, 0.1, 0.25, 1),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 27,
              height: 27,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
