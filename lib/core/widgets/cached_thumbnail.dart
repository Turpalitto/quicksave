import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached network thumbnail with placeholder and error fallback.
class CachedThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const CachedThumbnail({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return fallback ?? _defaultFallback(context);
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _shimmer(context),
      errorWidget: (_, __, ___) => fallback ?? _defaultFallback(context),
    );
  }

  Widget _shimmer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _defaultFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: scheme.onSurfaceVariant,
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 28,
      ),
    );
  }
}
