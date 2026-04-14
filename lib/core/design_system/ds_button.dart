import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

enum DSButtonVariant { primary, secondary, tertiary, ghost }
enum DSButtonSize { sm, md, lg }

/// Design-system button — pill-shaped, matches web marketplace `Button`.
class DSButton extends StatelessWidget {
  const DSButton({
    super.key,
    required this.label,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.md,
    this.iconLeft,
    this.iconRight,
    this.isLoading = false,
    this.enabled = true,
    this.onTap,
    this.expand = false,
  });

  final String label;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final IconData? iconLeft;
  final IconData? iconRight;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onTap;
  final bool expand;

  double get _height => switch (size) {
    DSButtonSize.sm => 28,   // h-7
    DSButtonSize.md => 32,   // h-8
    DSButtonSize.lg => 40,   // h-10
  };

  double get _fontSize => switch (size) {
    DSButtonSize.sm => 13,
    DSButtonSize.md => 14,
    DSButtonSize.lg => 15,
  };

  double get _iconSize => switch (size) {
    DSButtonSize.sm => 14,
    DSButtonSize.md => 16,
    DSButtonSize.lg => 18,
  };

  EdgeInsets get _padding => switch (size) {
    DSButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12),
    DSButtonSize.md => const EdgeInsets.symmetric(horizontal: 16),
    DSButtonSize.lg => const EdgeInsets.symmetric(horizontal: 20),
  };

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final active = enabled && !isLoading;

    final bg = !enabled
        ? c.border.subtle
        : switch (variant) {
            DSButtonVariant.primary => c.brand.primary,
            DSButtonVariant.secondary => c.brand.primary.withValues(alpha: 0.1),
            DSButtonVariant.tertiary => Colors.transparent,
            DSButtonVariant.ghost => Colors.transparent,
          };

    final fg = !enabled
        ? c.text.muted
        : switch (variant) {
            DSButtonVariant.primary => c.brand.onPrimary,
            DSButtonVariant.secondary => c.brand.primary,
            DSButtonVariant.tertiary => c.text.primary,
            DSButtonVariant.ghost => c.text.secondary,
          };

    final borderColor = (!enabled && variant == DSButtonVariant.tertiary)
        ? c.border.subtle
        : switch (variant) {
            DSButtonVariant.tertiary => c.border.strong,
            _ => null,
          };

    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: DSMotion.fast,
        height: _height,
        padding: _padding,
        constraints: expand ? const BoxConstraints(minWidth: double.infinity) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: isLoading
            ? SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconLeft != null) ...[
                    Icon(iconLeft, size: _iconSize, color: fg),
                    const SizedBox(width: DSSpacing.s2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600, color: fg),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (iconRight != null) ...[
                    const SizedBox(width: DSSpacing.s2),
                    Icon(iconRight, size: _iconSize, color: fg),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Icon-only button ──

enum DSIconButtonVariant { primary, secondary, tertiary, ghost, brand }

/// Design-system icon button — circular, matches web marketplace `IconButton`.
class DSIconButton extends StatelessWidget {
  const DSIconButton({
    super.key,
    required this.icon,
    this.variant = DSIconButtonVariant.ghost,
    this.size = DSButtonSize.md,
    this.isLoading = false,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final DSIconButtonVariant variant;
  final DSButtonSize size;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onTap;

  double get _size => switch (size) {
    DSButtonSize.sm => 36,
    DSButtonSize.md => 40,
    DSButtonSize.lg => 48,
  };

  double get _iconSize => switch (size) {
    DSButtonSize.sm => 16,
    DSButtonSize.md => 20,
    DSButtonSize.lg => 24,
  };

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final bg = !enabled
        ? c.border.subtle
        : switch (variant) {
            DSIconButtonVariant.primary => c.brand.primary,
            DSIconButtonVariant.secondary => c.brand.primary.withValues(alpha: 0.1),
            DSIconButtonVariant.tertiary => Colors.transparent,
            DSIconButtonVariant.ghost => Colors.transparent,
            DSIconButtonVariant.brand => c.brand.accent,
          };

    final fg = !enabled
        ? c.text.muted
        : switch (variant) {
            DSIconButtonVariant.primary => c.brand.onPrimary,
            DSIconButtonVariant.secondary => c.brand.primary,
            DSIconButtonVariant.tertiary => c.text.primary,
            DSIconButtonVariant.ghost => c.text.secondary,
            DSIconButtonVariant.brand => c.brand.onAccent,
          };

    final borderColor = switch (variant) {
      DSIconButtonVariant.tertiary => c.border.subtle,
      _ => null,
    };

    return GestureDetector(
      onTap: (enabled && !isLoading) ? onTap : null,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: isLoading
            ? Center(child: SizedBox(
                width: _iconSize * 0.8,
                height: _iconSize * 0.8,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ))
            : Icon(icon, size: _iconSize, color: fg),
      ),
    );
  }
}
