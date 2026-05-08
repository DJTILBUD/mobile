import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Gap data model ────────────────────────────────────────────────────────────

class _GapItem {
  const _GapItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.stat,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? stat;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ProfileCoachBottomSheet extends ConsumerStatefulWidget {
  const ProfileCoachBottomSheet({
    super.key,
    required this.userContext,
    required this.userRole,
    required this.isDj,
    required this.onEditProfile,
    required this.onGoToReviews,
    required this.onGoToMedia,
    required this.onBioAccepted,
  });

  final Map<String, dynamic> userContext;
  final String userRole;
  final bool isDj;
  final VoidCallback onEditProfile;
  final VoidCallback onGoToReviews;
  final VoidCallback onGoToMedia;
  final void Function(String draft) onBioAccepted;

  @override
  ConsumerState<ProfileCoachBottomSheet> createState() =>
      _ProfileCoachBottomSheetState();
}

class _ProfileCoachBottomSheetState
    extends ConsumerState<ProfileCoachBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only generate if no result exists yet — preserves analysis across
      // sheet open/close cycles until the user explicitly refreshes.
      final current = ref.read(profileCoachSessionProvider);
      if (current is AgentIdle) {
        _generate();
      }
    });
  }

  void _generate() {
    ref.read(profileCoachSessionProvider.notifier).generateProfileCoach(
          userContext: widget.userContext,
          userRole: widget.userRole,
        );
  }

  void _refresh() {
    ref.read(profileCoachSessionProvider.notifier).reset();
    _generate();
  }

  void _openBioSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        overrides: [
          agentSessionProvider.overrideWith(
            (ref) => AgentSessionNotifier(ref.watch(agentRepositoryProvider)),
          ),
        ],
        child: ProfileBioBottomSheet(
          userContext: widget.userContext,
          userRole: widget.userRole,
          isDj: widget.isDj,
          onDraftAccepted: widget.onBioAccepted,
        ),
      ),
    );
  }

  List<_GapItem> _buildGaps() {
    final ctx = widget.userContext;
    final reviewCount = ctx['reviewCount'] as int? ?? 0;
    final hasProfileImage = ctx['hasProfileImage'] as bool? ?? false;
    final videoCount = ctx['videoCount'] as int? ?? 0;
    final aboutText =
        (ctx['aboutYou'] as String? ?? ctx['aboutText'] as String? ?? '')
            .trim();
    final genres = (ctx['genres'] as List?)?.cast<dynamic>() ?? [];
    final venuesAndEvents =
        (ctx['venuesAndEvents'] as List?)?.cast<dynamic>() ?? [];

    final gaps = <_GapItem>[];

    if (!hasProfileImage) {
      gaps.add(_GapItem(
        icon: LucideIcons.camera,
        title: 'Tilføj profilbillede',
        stat: '+50% klik',
        description:
            'Kunder klikker 50% sjældnere på profiler uden billede — det er det første de ser. '
            'Upload et godt foto fra et event eller et professionelt portræt.',
        onTap: widget.onGoToMedia,
      ));
    }

    if (reviewCount < 10) {
      gaps.add(_GapItem(
        icon: LucideIcons.star,
        title: 'Få flere anbefalinger',
        stat: '+40% bookinger',
        description: reviewCount == 0
            ? 'Ingen anbefalinger endnu — social proof er afgørende for nye kunder. '
                'Bed dine tidligere kunder om en kort anmeldelse via DJTilbud efter eventet.'
            : 'Du har $reviewCount anbefalinger — profiler med 10+ lukker 40% flere bookinger. '
                'Kontakt tidligere kunder og bed dem skrive en kort anmeldelse.',
        onTap: widget.onGoToReviews,
      ));
    }

    if (videoCount == 0) {
      gaps.add(_GapItem(
        icon: LucideIcons.video,
        title: 'Upload en video',
        stat: '+60% klik',
        description:
            'Kunder klikker 60% sjældnere på profiler uden video — de vil se dig i aktion. '
            'En 1–2 minutters klip fra et event er nok, det behøver ikke være professionelt optaget.',
        onTap: widget.onGoToMedia,
      ));
    }


    if (aboutText.length < 80) {
      gaps.add(_GapItem(
        icon: LucideIcons.fileText,
        title: 'Udbyg din bio',
        stat: '+35% konvertering',
        description: aboutText.isEmpty
            ? 'Ingen bio endnu — kunder springer profiler over uden en personlig tekst. '
                'Tryk her og lad AI hjælpe dig med 3–4 sætninger om din stil og hvad du bringer til eventet.'
            : 'Din bio er kun ${aboutText.length} tegn — for kort til at overbevise. '
                'Tryk her og lad AI hjælpe dig med at udvide den med din stil og erfaring.',
        onTap: _openBioSheet,
      ));
    }

    if (genres.isEmpty) {
      gaps.add(_GapItem(
        icon: LucideIcons.music2,
        title: 'Tilføj genrer',
        description:
            'Uden genrer dukker din profil ikke op, når kunder søger på specifikke musiktyper. '
            'Gå til profil-redigering og tilføj de genrer du oftest spiller — det tager under et minut.',
        onTap: widget.onEditProfile,
      ));
    }

    if (venuesAndEvents.length < 3) {
      gaps.add(_GapItem(
        icon: LucideIcons.mapPin,
        title: 'Tilføj flere spillesteder',
        description: venuesAndEvents.isEmpty
            ? 'Ingen spillesteder angivet — kunder vil gerne vide hvor du har optrådt. '
                'Tilføj navne på venues og eventtyper som bryllupper, firmafester eller klubaftener.'
            : 'Jo mere specifik du er, jo mere tillid skaber du. '
                'Tilføj flere venues og eventtyper — f.eks. konkrete navne og arrangementsstørrelser.',
        onTap: widget.onEditProfile,
      ));
    }

    return gaps;
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final agentState = ref.watch(profileCoachSessionProvider);
    final gaps = _buildGaps();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _c.bg.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DSSpacing.s3),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _c.border.subtle,
                    borderRadius: BorderRadius.circular(DSRadius.pill),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DSSpacing.s4, 0, DSSpacing.s2, DSSpacing.s3),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkles,
                        size: 18, color: _c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        'Profilcoach',
                        style: DSTextStyle.headingSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _c.text.primary),
                      ),
                    ),
                    if (agentState is AgentDone || agentState is AgentError)
                      IconButton(
                        onPressed: _refresh,
                        icon: Icon(LucideIcons.refreshCw,
                            size: 18, color: _c.text.muted),
                        tooltip: 'Generer ny analyse',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              Divider(color: _c.border.subtle, height: 1),

              // Scrollable body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DSSpacing.s4),
                  children: [
                    // AI short intro — streams first, cards appear after done
                    _AssessmentText(agentState: agentState),

                    // Gap cards only shown once AI intro is complete
                    if (agentState is AgentDone ||
                        agentState is AgentError) ...[
                      const SizedBox(height: DSSpacing.s6),
                      if (gaps.isNotEmpty) ...[
                        Text(
                          'Hvad du kan forbedre',
                          style: DSTextStyle.labelLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _c.text.secondary,
                          ),
                        ),
                        const SizedBox(height: DSSpacing.s3),
                        for (final gap in gaps) ...[
                          _GapCard(gap: gap),
                          const SizedBox(height: DSSpacing.s3),
                        ],
                      ] else ...[
                        _CompleteBadge(),
                      ],
                    ],

                    const SizedBox(height: DSSpacing.s4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Assessment text (AI intro) ────────────────────────────────────────────────

class _AssessmentText extends StatelessWidget {
  const _AssessmentText({required this.agentState});

  final AgentState agentState;
  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    if (agentState is AgentIdle) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DSSpacing.s4),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (agentState is AgentError) {
      return const SizedBox.shrink();
    }

    final text = agentState is AgentStreaming
        ? (agentState as AgentStreaming).text
        : (agentState as AgentDone).text;

    final isStreaming = agentState is AgentStreaming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: _c.text.primary,
            height: 1.6,
          ),
        ),
        if (isStreaming) ...[
          const SizedBox(height: DSSpacing.s2),
          Row(
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: _c.brand.primaryActive,
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              Text(
                'Analyserer...',
                style: DSTextStyle.bodySm
                    .copyWith(fontSize: 11, color: _c.text.muted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Gap card ──────────────────────────────────────────────────────────────────

class _GapCard extends StatelessWidget {
  const _GapCard({required this.gap});

  final _GapItem gap;
  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: gap.onTap,
      child: Container(
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
          boxShadow: DSShadow.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _c.bg.inputBg,
                borderRadius: BorderRadius.circular(DSRadius.sm),
              ),
              child: Icon(gap.icon, size: 20, color: _c.text.secondary),
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
                          gap.title,
                          style: DSTextStyle.labelLg.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _c.text.primary),
                        ),
                      ),
                      if (gap.stat != null) ...[
                        const SizedBox(width: DSSpacing.s2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _c.brand.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            gap.stat!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _c.brand.primaryActive,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gap.description,
                    style: DSTextStyle.bodySm.copyWith(
                        color: _c.text.secondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            Icon(LucideIcons.chevronRight,
                size: 18, color: _c.text.muted),
          ],
        ),
      ),
    );
  }
}

// ── Complete badge (shown when no gaps) ──────────────────────────────────────

class _CompleteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.state.success.withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, size: 18, color: _c.state.success),
          const SizedBox(width: DSSpacing.s3),
          Expanded(
            child: Text(
              'Din profil er komplet — godt klaret!',
              style:
                  DSTextStyle.bodyMd.copyWith(color: _c.state.success),
            ),
          ),
        ],
      ),
    );
  }
}
