import 'package:flutter/material.dart';
import 'tokens.dart';

/// A colored status badge — pill shape with a soft tinted background and
/// a matching border. Used for offer/quote statuses, invoice state, etc.
///
/// Set [expand] to true for full-width banners (e.g. invoice confirmation).
///
/// ```dart
/// // Inline status pill
/// DSStatusBadge(label: 'Afventer', color: c.state.warning)
///
/// // Full-width banner
/// DSStatusBadge(label: 'Aftale bekræftet', color: c.state.success, expand: true)
/// ```
class DSStatusBadge extends StatelessWidget {
  const DSStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.expand = false,
  });

  final String label;
  final Color color;

  /// When true the badge stretches to fill its parent's width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s2, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        textAlign: expand ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
