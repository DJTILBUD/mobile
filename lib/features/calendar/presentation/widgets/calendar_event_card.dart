import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    this.showTypeTag = true,
    this.onTap,
  });

  final CalendarEvent event;

  /// Show the type/kind tag.
  final bool showTypeTag;

  /// Optional tap handler. When set, the card shows a chevron and is tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const c = lightColors;
    final isExternal = event.type == CalendarEventType.external;

    // Bar color and tag are driven by kind first, then type for won events
    final Color barColor;
    final String tagLabel;
    final Color tagBg;
    final Color tagFg;

    switch (event.kind) {
      case CalendarEventKind.newJob:
        barColor = c.state.info;
        tagLabel = 'Nyt job';
        tagBg = c.state.info.withValues(alpha: 0.12);
        tagFg = c.state.info;
      case CalendarEventKind.sent:
        barColor = c.state.warning;
        tagLabel = 'Bud afgivet';
        tagBg = c.state.warning.withValues(alpha: 0.12);
        tagFg = c.state.warning;
      case CalendarEventKind.won:
        barColor = isExternal ? c.brand.accent : c.brand.primary;
        tagLabel = isExternal ? 'Eksternt' : 'Internt';
        tagBg = barColor.withValues(alpha: 0.12);
        tagFg = isExternal ? c.brand.accent : c.brand.primaryActive;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s1),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left color bar
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.label,
                          style: DSTextStyle.headingSm.copyWith(
                            fontSize: 15,
                            color: c.text.primary,
                          ),
                        ),
                      ),
                      if (showTypeTag)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DSSpacing.s2, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius:
                                BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            tagLabel,
                            style: DSTextStyle.bodySm.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tagFg,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s1),
                  _InfoRow(
                    icon: LucideIcons.clock,
                    text: event.timeDisplay,
                  ),
                  const SizedBox(height: 2),
                  _InfoRow(
                    icon: LucideIcons.mapPin,
                    text: event.locationDisplay,
                  ),
                  if (event.guestsAmount != null) ...[
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: LucideIcons.users,
                      text: '${event.guestsAmount} gæster',
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(LucideIcons.chevronRight,
                  size: 20, color: c.text.muted),
          ],
        ),
      ),
    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const c = lightColors;
    return Row(
      children: [
        Icon(icon, size: 13, color: c.text.secondary),
        const SizedBox(width: DSSpacing.s1),
        Expanded(
          child: Text(
            text,
            style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
