import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

/// "🎶 Til festen" purple card with the couple-facing event details a partner-portal booking collects
/// (how the couple is addressed, guest age, first dance, playlist, special conditions) plus a
/// saxophonist subsection. Mirrors the web DJ udvalgte-jobs / instrumentalist ext-job "Til festen" card
/// so a DJ (ext-job detail) and a won saxophonist (offer detail) see the same info. Self-hides when
/// nothing is set, so it's safe to drop in unconditionally.
class PartnerEventWishesCard extends StatelessWidget {
  const PartnerEventWishesCard({
    super.key,
    this.addressAs,
    this.guestAge,
    this.firstDanceSong,
    this.spotifyPlaylistUrl,
    this.specialConditions,
    this.earlySetup = false,
    this.wantsIc,
    this.saxType,
    this.musicianStartTime,
    this.requestedMusicianHours,
    this.musicianSpecialRequest,
    this.musicianView = false,
  });

  final String? addressAs;
  final String? guestAge;
  final String? firstDanceSong;
  final String? spotifyPlaylistUrl;
  final String? specialConditions;
  final bool earlySetup;

  /// "Vil parret kontaktes af DJ'en inden festen?" (JobMetadata.wants_ic). Null when not a partner
  /// booking; true/false is an explicit answer the DJ needs (whether to call the couple beforehand).
  final bool? wantsIc;
  final String? saxType;
  final String? musicianStartTime;
  final double? requestedMusicianHours;
  final String? musicianSpecialRequest;

  /// The saxophonist's view: only the two fields relevant to them (how the couple is addressed +
  /// special conditions). The DJ-oriented details (playliste, brudevals, alder, opsætning, and the sax
  /// subsection) are hidden. The sax type is shown elsewhere on the sax offer page.
  final bool musicianView;

  // Off-palette purple (matches RecurringCustomerBadge) — there's no DS purple token.
  static const _purple = Color(0xFF9333EA);

  bool get _hasAny =>
      musicianView
          ? (_has(addressAs) || _has(specialConditions))
          : (_has(addressAs) ||
              _has(guestAge) ||
              _has(firstDanceSong) ||
              _has(spotifyPlaylistUrl) ||
              _has(specialConditions) ||
              earlySetup ||
              wantsIc != null ||
              _has(saxType));

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;

  String _hoursDisplay(double h) => h.toStringAsFixed(h % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    final c = DSTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? const Color(0xFFC9A7F0) : const Color(0xFF7E22CE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(
          color: _purple.withValues(alpha: isDark ? 0.4 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎶 Til festen',
            style: DSTextStyle.headingSm.copyWith(
              fontSize: 15,
              color: c.text.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          if (_has(addressAs))
            _Field(
              icon: LucideIcons.messageCircle,
              label: 'Sådan omtales parret',
              value: addressAs!,
              labelColor: labelColor,
            ),
          if (!musicianView && _has(guestAge))
            _Field(
              icon: LucideIcons.users,
              label: 'Alder på gæsterne',
              value: guestAge!,
              labelColor: labelColor,
            ),
          if (!musicianView && _has(firstDanceSong))
            _Field(
              icon: LucideIcons.music,
              label: 'Brudevals',
              value: firstDanceSong!,
              labelColor: labelColor,
            ),
          // Tidlig opsætning — explicit Ja/Nej for a partner booking (wantsIc collected), or whenever
          // early setup is requested. Tells the DJ if they must be set up before guests arrive.
          if (!musicianView && (wantsIc != null || earlySetup))
            _Field(
              icon: LucideIcons.clock,
              label: 'Tidlig opsætning',
              value: earlySetup ? 'Ja, inden gæsterne ankommer' : 'Nej',
              labelColor: labelColor,
            ),
          // Kontakt parret inden festen — the couple's wish for a pre-party call (JobMetadata.wants_ic).
          if (!musicianView && wantsIc != null)
            _Field(
              icon: LucideIcons.phone,
              label: 'Kontakt parret inden festen',
              value: wantsIc! ? 'Ja' : 'Nej',
              labelColor: labelColor,
            ),
          if (!musicianView && _has(spotifyPlaylistUrl))
            _Field(
              icon: LucideIcons.music,
              label: 'Playliste / ønskesange',
              value: spotifyPlaylistUrl!.trim(),
              labelColor: labelColor,
              copyable: true,
            ),
          if (_has(specialConditions))
            _Field(
              icon: LucideIcons.info,
              label: 'Særlige forhold',
              value: specialConditions!,
              labelColor: labelColor,
            ),
          if (!musicianView && _has(saxType)) ...[
            const SizedBox(height: DSSpacing.s3),
            Divider(color: _purple.withValues(alpha: 0.28), height: 1),
            const SizedBox(height: DSSpacing.s3),
            Row(
              children: [
                Icon(LucideIcons.mic, size: 15, color: labelColor),
                const SizedBox(width: 6),
                Text(
                  'Saxofonist',
                  style: DSTextStyle.labelLg.copyWith(
                    color: c.text.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s2),
            _Field(
              icon: LucideIcons.music2,
              label: 'Stil',
              value: saxType == 'lounge' ? 'Lounge' : 'Party',
              labelColor: labelColor,
            ),
            if (_has(musicianStartTime))
              _Field(
                icon: LucideIcons.clock,
                label: 'Starttid',
                value: musicianStartTime!,
                labelColor: labelColor,
              ),
            if (requestedMusicianHours != null)
              _Field(
                icon: LucideIcons.clock,
                label: 'Varighed',
                value: '${_hoursDisplay(requestedMusicianHours!)} timer',
                labelColor: labelColor,
              ),
            if (_has(musicianSpecialRequest))
              _Field(
                icon: LucideIcons.sparkles,
                label: 'Særlige ønsker til saxofonisten',
                value: musicianSpecialRequest!,
                labelColor: labelColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;

  /// When true, render a copy button next to the value (used for the playlist link).
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final valueText = Text(
      value,
      style: DSTextStyle.bodyMd.copyWith(color: c.text.primary),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: labelColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: DSTextStyle.labelSm.copyWith(
                  color: c.text.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (copyable)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: valueText),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    DSToast.show(
                      context,
                      variant: DSToastVariant.success,
                      title: 'Link kopieret',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, size: 14, color: labelColor),
                        const SizedBox(width: 4),
                        Text(
                          'Kopiér',
                          style: DSTextStyle.labelSm.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            valueText,
        ],
      ),
    );
  }
}
