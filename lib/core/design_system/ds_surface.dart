import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/tokens.dart';

/// Design-system surface card — matches web marketplace card container.
/// White background, subtle border, small shadow, large radius.
class DSSurface extends StatelessWidget {
  const DSSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DSSpacing.s4),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: child,
    );
  }
}
