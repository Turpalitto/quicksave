import 'package:flutter/material.dart';

import '../../theme/ios_tokens.dart';

class IosSegment<T> extends StatelessWidget {
  const IosSegment({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IosTokens.fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: segments.map((segment) {
            final active = segment == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segment),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? IosTokens.segmentActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder?.call(segment) ?? segment.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: IosTokens.label,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
