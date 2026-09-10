import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// Danish label for `Jobs`/`ExtJobs.sax_type` ('lounge' | 'party').
///
/// Guards the empty string: `sax_type` can be `''` (not null) in the DB, and
/// `''[0]` throws a RangeError — the same crash `job_card.dart` was hardened
/// against after it took down the whole jobs list in production.
String saxTypeLabel(String saxType) => switch (saxType) {
  'lounge' => 'Lounge',
  'party' => 'Party',
  _ =>
    saxType.isEmpty
        ? 'Sax'
        : '${saxType[0].toUpperCase()}${saxType.substring(1)}',
};

/// Tap-to-expand explanation of what a lounge/party gig asks of the saxophonist.
///
/// Mirrors the badge tooltip in web
/// `instrumentalist/jobs/[job_id]/_components/JobInfo.tsx` — keep the copy in
/// sync with it. Self-hides for an unknown or empty sax type.
class SaxTypeDescription extends StatefulWidget {
  const SaxTypeDescription({super.key, required this.saxType});

  final String saxType;

  @override
  State<SaxTypeDescription> createState() => _SaxTypeDescriptionState();
}

class _SaxTypeDescriptionState extends State<SaxTypeDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);

    final (IconData icon, Color color, String description) = switch (widget
        .saxType) {
      'lounge' => (
        LucideIcons.coffee,
        c.state.info,
        'Du spiller blød baggrundsmusik – jazz, bossa nova og rolige melodier. Du er ikke centrum for opmærksomhed, men sætter stemningen diskret.',
      ),
      'party' => (
        LucideIcons.partyPopper,
        c.state.warning,
        'Du er centrum for opmærksomhed – spil kendte hits, bring energi og dansevibes til festen. Tænd for salen og giv den gas.',
      ),
      _ => (LucideIcons.music, c.text.muted, ''),
    };

    if (description.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: DSSpacing.s2),
            Expanded(
              child:
                  _expanded
                      ? Text(
                        description,
                        style: DSTextStyle.bodySm.copyWith(
                          color: c.text.secondary,
                        ),
                      )
                      : Text(
                        'Tryk for at læse mere',
                        style: DSTextStyle.bodySm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
            Icon(
              _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
