import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// "Fast kunde · [name]" pill shown on an ext job that belongs to a recurring
/// (venue) customer, so the DJ/musician sees at a glance they're playing for a
/// fixed customer. Mirrors the purple badge on the web app's "Udvalgte jobs"
/// list + detail (`dj/udvalgte-jobs`). The venue name is resolved server-side
/// (DJs can't read `RecurringCustomers` via RLS) — see
/// `djExtJobRecurringNamesProvider`.
class RecurringCustomerBadge extends StatelessWidget {
  const RecurringCustomerBadge({
    super.key,
    required this.name,
    this.compact = false,
  });

  final String name;

  /// Tighter padding + a shorter label for dense list cards.
  final bool compact;

  // Purple accent, kept intentionally distinct from the neutral/brand chips so
  // "fixed customer" reads as its own signal. Theme-aware for light + dark.
  static const _accent = Color(0xFF9333EA);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE);
    final bg = _accent.withValues(alpha: isDark ? 0.24 : 0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DSSpacing.s2 : DSSpacing.s3,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.building2,
            size: compact ? 12 : 14,
            color: textColor,
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              compact ? name : 'Fast kunde · $name',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
