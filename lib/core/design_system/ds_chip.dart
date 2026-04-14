import 'package:flutter/material.dart';
import 'tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A selectable pill chip with optional icon and delete action.
///
/// Visual states driven by [selected] and [enabled]:
/// - **Default** – white surface, dark border, dark content.
/// - **Selected** – brand-primary fill, onPrimary content.
/// - **Disabled** – muted fill, muted content, no interaction.
/// - **Tinted** – read-only brand-tinted tag (e.g. genre labels).
///
/// ```dart
/// // Interactive selection chip
/// DSChip(
///   label: 'Pop',
///   icon: LucideIcons.mic,
///   selected: _selectedGenres.contains('Pop'),
///   onTap: () => setState(() => _toggle('Pop')),
/// )
///
/// // With delete (e.g. venue tags)
/// DSChip(label: 'Rust', onDelete: () => _removeVenue('Rust'))
///
/// // Read-only genre / taxonomy tag
/// DSChip(label: 'House', tinted: true)
/// ```
class DSChip extends StatelessWidget {
  const DSChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.tinted = false,
    this.onTap,
    this.onDelete,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;

  /// When true renders as a soft brand-tinted read-only tag.
  /// Ignores [selected], [enabled], [onTap], and [onDelete].
  final bool tinted;

  /// When set, a close (×) button appears on the right.
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final bg = tinted
        ? c.brand.primary.withValues(alpha: 0.15)
        : !enabled
            ? c.bg.inputBg
            : selected
                ? c.brand.primary
                : c.bg.surface;

    final content = tinted
        ? c.brand.primaryActive
        : !enabled
            ? c.text.muted
            : selected
                ? c.brand.onPrimary
                : c.text.primary;

    final border = tinted
        ? null
        : !enabled
            ? Border.all(color: c.border.subtle)
            : selected
                ? Border.all(color: c.brand.primary)
                : Border.all(color: c.border.strong);

    return GestureDetector(
      onTap: tinted ? null : (enabled ? onTap : null),
      child: AnimatedContainer(
        duration: DSMotion.fast,
        curve: DSMotion.ease,
        padding: EdgeInsets.symmetric(
          horizontal: (icon != null || onDelete != null) ? 10 : 12,
          vertical: tinted ? 3 : 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: tinted ? 13 : 18, color: content),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tinted ? 11 : 13,
                  fontWeight: tinted ? FontWeight.w600 : FontWeight.w500,
                  color: content,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!tinted && onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: enabled ? onDelete : null,
                child: Icon(LucideIcons.x, size: 14, color: content),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
