import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AgentBottomSheet extends ConsumerStatefulWidget {
  const AgentBottomSheet({
    super.key,
    required this.job,
    required this.isDj,
    required this.onDraftAccepted,
  });

  final Job job;
  final bool isDj;
  final ValueChanged<String> onDraftAccepted;

  @override
  ConsumerState<AgentBottomSheet> createState() => _AgentBottomSheetState();
}

class _AgentBottomSheetState extends ConsumerState<AgentBottomSheet> {
  static const _c = lightColors;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _kickOff();
    }
  }

  void _kickOff() {
    final jobContext = jobToContext(widget.job);

    if (widget.isDj) {
      ref.read(djProfileProvider.future).then((profile) {
        if (!mounted) return;
        ref.read(agentSessionProvider.notifier).generateDraft(
              jobContext: jobContext,
              userContext: djToUserContext(profile),
              userRole: 'dj',
            );
      }).catchError((_) {
        if (!mounted) return;
        ref.read(agentSessionProvider.notifier).generateDraft(
              jobContext: jobContext,
              userContext: {'instrument': 'dj'},
              userRole: 'dj',
            );
      });
    } else {
      ref.read(musicianProfileProvider.future).then((profile) {
        if (!mounted) return;
        ref.read(agentSessionProvider.notifier).generateDraft(
              jobContext: jobContext,
              userContext: musicianToUserContext(profile),
              userRole: 'musician',
            );
      }).catchError((_) {
        if (!mounted) return;
        ref.read(agentSessionProvider.notifier).generateDraft(
              jobContext: jobContext,
              userContext: {'instrument': 'saxofon'},
              userRole: 'musician',
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentSessionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _c.bg.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: DSSpacing.s3),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _c.border.subtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s4),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkle, size: 18, color: _c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Text(
                      'AI Assistent',
                      style: DSTextStyle.headingMd.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: _c.text.primary, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Text(
                  'Genererer et udkast baseret på jobbet og din profil...',
                  style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w400, color: _c.text.secondary),
                ),
              ),
              const SizedBox(height: DSSpacing.s4),

              Divider(height: 1, color: _c.border.subtle),

              // Content area
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DSSpacing.s4),
                  child: switch (agentState) {
                    AgentIdle() => const _LoadingDots(),
                    AgentStreaming(:final text) => _DraftText(text: text, streaming: true),
                    AgentDone(:final text) => _DraftText(text: text, streaming: false),
                    AgentError(:final message) => _ErrorView(message: message),
                  },
                ),
              ),

              // Action buttons
              if (agentState is AgentDone || agentState is AgentError)
                _ActionBar(
                  agentState: agentState,
                  onAccept: () {
                    if (agentState is AgentDone) {
                      widget.onDraftAccepted(agentState.text);
                      Navigator.of(context).pop();
                    }
                  },
                  onRetry: () {
                    ref.read(agentSessionProvider.notifier).reset();
                    _kickOff();
                  },
                ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + DSSpacing.s4),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final dots = '.' * ((_controller.value * 4).toInt() % 4);
        return Text(
          'Tænker$dots',
          style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.secondary),
        );
      },
    );
  }
}

class _DraftText extends StatelessWidget {
  const _DraftText({required this.text, required this.streaming});

  final String text;
  final bool streaming;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.s4),
          decoration: BoxDecoration(
            color: _c.bg.canvas,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
          ),
          child: Text(
            text,
            style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.primary, height: 1.55),
          ),
        ),
        if (!streaming) ...[
          const SizedBox(height: DSSpacing.s3),
          Row(
            children: [
              Icon(LucideIcons.info, size: 13, color: _c.text.muted),
              const SizedBox(width: DSSpacing.s1),
              Expanded(
                child: Text(
                  'Du kan redigere udkastet direkte i tekstfeltet efter du har indsat det.',
                  style: DSTextStyle.bodySm.copyWith(color: _c.text.muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.alertCircle, color: _c.state.danger, size: 28),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Kunne ikke generere udkast',
          style: DSTextStyle.labelMd.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: _c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          message,
          style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w400, color: _c.text.secondary),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.agentState,
    required this.onAccept,
    required this.onRetry,
  });

  final AgentState agentState;
  final VoidCallback onAccept;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, DSSpacing.s3),
      decoration: BoxDecoration(
        color: lightColors.bg.surface,
        border: Border(top: BorderSide(color: lightColors.border.subtle)),
      ),
      child: Row(
        children: [
          if (agentState is AgentDone) ...[
            Expanded(
              child: DSButton(
                label: 'Indsæt udkast',
                variant: DSButtonVariant.primary,
                expand: true,
                onTap: onAccept,
              ),
            ),
            const SizedBox(width: DSSpacing.s3),
            DSButton(
              label: 'Prøv igen',
              variant: DSButtonVariant.tertiary,
              onTap: onRetry,
            ),
          ] else ...[
            Expanded(
              child: DSButton(
                label: 'Prøv igen',
                variant: DSButtonVariant.primary,
                expand: true,
                onTap: onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
