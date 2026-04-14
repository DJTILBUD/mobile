import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum _Phase { questions, generating }

class ProfileBioBottomSheet extends ConsumerStatefulWidget {
  const ProfileBioBottomSheet({
    super.key,
    required this.userContext,
    required this.userRole,
    required this.isDj,
    required this.onDraftAccepted,
  });

  final Map<String, dynamic> userContext;
  final String userRole;
  final bool isDj;
  final void Function(String draft) onDraftAccepted;

  @override
  ConsumerState<ProfileBioBottomSheet> createState() =>
      _ProfileBioBottomSheetState();
}

class _ProfileBioBottomSheetState
    extends ConsumerState<ProfileBioBottomSheet> {
  _Phase _phase = _Phase.questions;

  final _strengthsCtrl = TextEditingController();
  final _eventsCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _c = lightColors;

  @override
  void dispose() {
    _strengthsCtrl.dispose();
    _eventsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (_strengthsCtrl.text.trim().isEmpty &&
        _eventsCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => _phase = _Phase.generating);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(agentSessionProvider.notifier).generateProfileBio(
            userContext: widget.userContext,
            userRole: widget.userRole,
            strengths: _strengthsCtrl.text.trim(),
            preferredEvents: _eventsCtrl.text.trim(),
          );
    });
  }

  void _retry() {
    ref.read(agentSessionProvider.notifier).reset();
    setState(() => _phase = _Phase.questions);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _c.bg.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DSRadius.lg),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkle,
                        size: 18, color: _c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Text(
                      'AI Profilbeskrivelse',
                      style: DSTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700, color: _c.text.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s1),
              Divider(color: _c.border.subtle, height: 1),

              // Content — switches between phases
              Expanded(
                child: _phase == _Phase.questions
                    ? _QuestionsPhase(
                        isDj: widget.isDj,
                        strengthsCtrl: _strengthsCtrl,
                        eventsCtrl: _eventsCtrl,
                        onGenerate: _generate,
                        scrollController: scrollController,
                      )
                    : _GeneratingPhase(
                        scrollController: scrollController,
                        onAccepted: (draft) {
                          widget.onDraftAccepted(draft);
                          Navigator.of(context).pop();
                        },
                        onRetry: _retry,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Phase 1: Questions ────────────────────────────────────────────────────────

class _QuestionsPhase extends StatelessWidget {
  const _QuestionsPhase({
    required this.isDj,
    required this.strengthsCtrl,
    required this.eventsCtrl,
    required this.onGenerate,
    required this.scrollController,
  });

  final bool isDj;
  final TextEditingController strengthsCtrl;
  final TextEditingController eventsCtrl;
  final VoidCallback onGenerate;
  final ScrollController scrollController;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final role = isDj ? 'DJ' : 'musiker';
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        Text(
          'To hurtige spørgsmål, så teksten lyder som dig.',
          style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s6),

        Text(
          'Hvad er dine stærkeste sider som $role?',
          style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s2),
        DSInput(
          hint: isDj
              ? 'F.eks. "Jeg er god til at læse stemningen og holde folk på gulvet"'
              : 'F.eks. "Jeg er god til at improvisere og tilpasse mig musikken"',
          controller: strengthsCtrl,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: DSSpacing.s6),

        Text(
          'Hvad slags events elsker du mest at spille til?',
          style: DSTextStyle.labelLg.copyWith(fontWeight: FontWeight.w600, color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s2),
        DSInput(
          hint: 'F.eks. "Bryllupper og firmafester, helst med 100+ gæster"',
          controller: eventsCtrl,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: DSSpacing.s8),

        ListenableBuilder(
          listenable: Listenable.merge([strengthsCtrl, eventsCtrl]),
          builder: (context, _) {
            final hasInput = strengthsCtrl.text.trim().isNotEmpty ||
                eventsCtrl.text.trim().isNotEmpty;
            return DSButton(
              label: 'Generer udkast',
              variant: DSButtonVariant.primary,
              expand: true,
              onTap: hasInput ? onGenerate : null,
            );
          },
        ),
        const SizedBox(height: DSSpacing.s4),
        Center(
          child: Text(
            'AI kan lave fejl — læs udkastet igennem før du bruger det.',
            style: DSTextStyle.bodySm.copyWith(fontSize: 11, color: _c.text.muted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: DSSpacing.s4),
      ],
    );
  }
}

// ── Phase 2: Streaming result ─────────────────────────────────────────────────

class _GeneratingPhase extends ConsumerWidget {
  const _GeneratingPhase({
    required this.scrollController,
    required this.onAccepted,
    required this.onRetry,
  });

  final ScrollController scrollController;
  final void Function(String) onAccepted;
  final VoidCallback onRetry;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentState = ref.watch(agentSessionProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        if (agentState is AgentStreaming || agentState is AgentDone) ...[
          Container(
            padding: const EdgeInsets.all(DSSpacing.s4),
            decoration: BoxDecoration(
              color: _c.bg.canvas,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.border.subtle),
            ),
            child: Text(
              agentState is AgentStreaming
                  ? agentState.text
                  : (agentState as AgentDone).text,
              style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.primary, height: 1.6),
            ),
          ),
          if (agentState is AgentStreaming)
            Padding(
              padding: const EdgeInsets.only(top: DSSpacing.s3),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _c.brand.primaryActive,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s2),
                  Text(
                    'Skriver...',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                  ),
                ],
              ),
            ),
          if (agentState is AgentDone) ...[
            const SizedBox(height: DSSpacing.s4),
            DSButton(
              label: 'Brug dette udkast',
              variant: DSButtonVariant.primary,
              expand: true,
              onTap: () => onAccepted(agentState.text),
            ),
            const SizedBox(height: DSSpacing.s2),
            DSButton(
              label: 'Prøv igen',
              variant: DSButtonVariant.tertiary,
              expand: true,
              onTap: onRetry,
            ),
          ],
        ] else if (agentState is AgentError) ...[
          Container(
            padding: const EdgeInsets.all(DSSpacing.s4),
            decoration: BoxDecoration(
              color: _c.state.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.state.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              agentState.message,
              style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
            ),
          ),
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Prøv igen',
            variant: DSButtonVariant.tertiary,
            expand: true,
            onTap: onRetry,
          ),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DSSpacing.s8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }
}
