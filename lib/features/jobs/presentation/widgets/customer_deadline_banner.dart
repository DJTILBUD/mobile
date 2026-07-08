import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The customer's decision-window countdown banner — ONE widget for normal Jobs and ext jobs.
/// Pass the computed deadline (`Job.customerDeadline` or `ExtJob.decisionDeadline`); the banner
/// self-labels and self-colors: not-yet-sent (null), urgent (<24h, amber), expired (red), or the
/// remaining "X dage / t / min". Mirrors the web countdown so both platforms read identically.
class CustomerDeadlineBanner extends StatelessWidget {
  const CustomerDeadlineBanner({super.key, required this.deadline});

  final DateTime? deadline;

  bool get _isExpired {
    final d = deadline;
    return d != null && d.isBefore(DateTime.now());
  }

  bool get _isUrgent {
    final d = deadline;
    return d != null &&
        !_isExpired &&
        d.difference(DateTime.now()).inHours < 24;
  }

  String _label() {
    final d = deadline;
    if (d == null) return 'Tilbuddet er endnu ikke sendt til kunden';
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'Fristen for kundens valg er udløbet';
    if (diff.inDays >= 2) return 'Kunden skal svare inden ${diff.inDays} dage';
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return 'Kunden skal svare inden ${h}t ${m}m';
    }
    return 'Kunden skal svare inden ${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final hasDeadline = deadline != null;
    final color =
        _isExpired
            ? c.state.danger
            : _isUrgent
            ? c.state.warning
            : c.text.secondary;
    final bg =
        _isExpired
            ? c.state.danger.withValues(alpha: 0.15)
            : _isUrgent
            ? c.state.warning.withValues(alpha: 0.18)
            : c.bg.inputBg;
    final icon =
        !hasDeadline
            ? LucideIcons.send
            : _isExpired
            ? LucideIcons.timerOff
            : LucideIcons.hourglass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label(),
              style: DSTextStyle.labelMd.copyWith(
                color: c.text.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
