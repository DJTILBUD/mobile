import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Circular avatar with a brand-tinted placeholder when no image is available.
///
/// ```dart
/// // Placeholder (no image):
/// DSAvatar(size: 56)
///
/// // With a remote image:
/// DSAvatar(imageUrl: profile.photoUrl, size: 40)
/// ```
class DSAvatar extends StatelessWidget {
  const DSAvatar({
    super.key,
    this.imageUrl,
    this.size = 40,
  });

  /// Remote image URL. When `null` the person icon placeholder is shown.
  final String? imageUrl;

  /// Diameter of the circle in logical pixels. Defaults to 40.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final placeholder = Center(
      child: Icon(
        LucideIcons.user,
        size: size * 0.5,
        color: c.brand.primaryActive,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.brand.primary.withValues(alpha: 0.12),
      ),
      clipBehavior: imageUrl != null ? Clip.antiAlias : Clip.none,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}
