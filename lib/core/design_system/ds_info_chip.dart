import 'package:flutter/material.dart';
import 'tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A small read-only metadata chip — icon + label, rounded-square shape.
/// Used to surface key facts at a glance (guests, price, time, etc.)
///
/// Set [highlight] to true for primary metrics (e.g. offer price) — renders
/// with a brand-primary tint instead of the neutral grey background.
///
/// ```dart
/// DSInfoChip(icon: LucideIcons.users, label: '120 gæster')
/// DSInfoChip(icon: LucideIcons.banknote,  label: '4.500 kr.', highlight: true)
/// ```
class DSInfoChip extends StatelessWidget {
  const DSInfoChip({
    super.key,
    required this.label,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final IconData? icon;

  /// When true renders with a brand-primary tint — use for the key metric
  /// (price, revenue) so it stands out among neutral chips.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final bg = highlight
        ? c.brand.primary.withValues(alpha: 0.12)
        : c.bg.inputBg;
    final contentColor =
        highlight ? c.brand.primaryActive : c.text.secondary;
    final iconColor = highlight ? c.brand.primaryActive : c.text.muted;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s2, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
