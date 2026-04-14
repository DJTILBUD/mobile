import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/profile_bio_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileCoachBottomSheet extends ConsumerStatefulWidget {
  const ProfileCoachBottomSheet({
    super.key,
    required this.userContext,
    required this.userRole,
    required this.isDj,
    required this.onEditProfile,
    required this.onBioAccepted,
  });

  final Map<String, dynamic> userContext;
  final String userRole;
  final bool isDj;

  /// Called when the musician taps "Redigér profil" — typically pops the sheet
  /// and navigates to EditProfileScreen.
  final VoidCallback onEditProfile;

  /// Called when a bio draft is accepted inside the nested bio flow.
  final void Function(String draft) onBioAccepted;

  @override
  ConsumerState<ProfileCoachBottomSheet> createState() =>
      _ProfileCoachBottomSheetState();
}

class _ProfileCoachBottomSheetState
    extends ConsumerState<ProfileCoachBottomSheet> {
  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(agentSessionProvider.notifier).generateProfileCoach(
            userContext: widget.userContext,
            userRole: widget.userRole,
          );
    });
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

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentSessionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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
                    DSSpacing.s4, 0, DSSpacing.s4, DSSpacing.s1),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkle,
                        size: 18, color: _c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Text(
                      'Profilcoach',
                      style: DSTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
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
                    // ── Assessment ──────────────────────────────────────────
                    _AssessmentCard(agentState: agentState),

                    if (agentState is AgentDone || agentState is AgentError) ...[
                      const SizedBox(height: DSSpacing.s6),

                      // ── Action cards ────────────────────────────────────
                      _ActionCard(
                        icon: LucideIcons.pencil,
                        title: 'Skriv/forbedre bio',
                        subtitle: 'AI hjælper dig med at skrive en stærk, personlig tekst',
                        onTap: _openBioSheet,
                      ),
                      const SizedBox(height: DSSpacing.s3),
                      _ActionCard(
                        icon: LucideIcons.sliders,
                        title: 'Redigér profil',
                        subtitle: 'Opdater genrer, spillesteder, pris og andre oplysninger',
                        onTap: widget.onEditProfile,
                      ),

                      if (agentState is AgentError) ...[
                        const SizedBox(height: DSSpacing.s3),
                        DSButton(
                          label: 'Prøv igen',
                          variant: DSButtonVariant.tertiary,
                          expand: true,
                          onTap: () => ref
                              .read(agentSessionProvider.notifier)
                              .generateProfileCoach(
                                userContext: widget.userContext,
                                userRole: widget.userRole,
                              ),
                        ),
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

// ── Assessment card ───────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.agentState});

  final AgentState agentState;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    if (agentState is AgentIdle) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DSSpacing.s8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (agentState is AgentError) {
      return Container(
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: _c.state.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.state.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          (agentState as AgentError).message,
          style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
        ),
      );
    }

    final text = agentState is AgentStreaming
        ? (agentState as AgentStreaming).text
        : (agentState as AgentDone).text;

    final isStreaming = agentState is AgentStreaming;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.brand.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.brand.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
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
                  style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              child: Icon(icon, size: 20, color: _c.text.secondary),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            Icon(LucideIcons.chevronRight, size: 18, color: _c.text.muted),
          ],
        ),
      ),
    );
  }
}
