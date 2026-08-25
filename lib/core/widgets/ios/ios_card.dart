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
    final palette = IosPalette.of(context);
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final decoration = BoxDecoration(
      color: palette.elevated,
      borderRadius: BorderRadius.circular(12),
      border: palette.isDark
          ? null
          : Border.all(color: palette.separator.withValues(alpha: 0.35)),
      boxShadow: palette.isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );

    if (!separated) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return DecoratedBox(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _IosSeparatorList(
          separatorColor: palette.separator,
          child: content,
        ),
      ),
    );
  }
}

class _IosSeparatorList extends StatelessWidget {
  const _IosSeparatorList({required this.child, required this.separatorColor});

  final Widget child;
  final Color separatorColor;

  @override
  Widget build(BuildContext context) {
    if (child is! Column) return child;
    final column = child as Column;
    final children = <Widget>[];
    for (var i = 0; i < column.children.length; i++) {
      if (i > 0) {
        children.add(
          Divider(height: 0.5, thickness: 0.5, color: separatorColor),
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
