import 'package:flutter/material.dart';

import '../../theme/ios_tokens.dart';

class IosCard extends StatelessWidget {
  const IosCard({
    super.key,
    required this.child,
    this.padding,
    this.separated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (!separated) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: IosTokens.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: IosTokens.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _IosSeparatorList(child: content),
      ),
    );
  }
}

class _IosSeparatorList extends StatelessWidget {
  const _IosSeparatorList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is! Column) return child;
    final column = child as Column;
    final children = <Widget>[];
    for (var i = 0; i < column.children.length; i++) {
      if (i > 0) {
        children.add(
          const Divider(height: 0.5, thickness: 0.5, color: IosTokens.separator),
        );
      }
      children.add(column.children[i]);
    }
    return Column(
      crossAxisAlignment: column.crossAxisAlignment,
      mainAxisAlignment: column.mainAxisAlignment,
      mainAxisSize: column.mainAxisSize,
      children: children,
    );
  }
}
