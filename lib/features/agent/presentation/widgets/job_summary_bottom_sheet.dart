import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:lucide_icons/lucide_icons.dart';

class JobSummaryBottomSheet extends ConsumerStatefulWidget {
  const JobSummaryBottomSheet({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<JobSummaryBottomSheet> createState() =>
      _JobSummaryBottomSheetState();
}

class _JobSummaryBottomSheetState extends ConsumerState<JobSummaryBottomSheet> {
  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    // Must defer until after build() so ref.watch is subscribed first —
    // otherwise the autoDispose provider may be disposed before the stream
    // state updates arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(agentSessionProvider.notifier).generateSummary(
            jobContext: jobToContext(widget.job),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentSessionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
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
                    Icon(LucideIcons.sparkle,
                        size: 18, color: _c.brand.primaryActive),
                    const SizedBox(width: DSSpacing.s2),
                    Text(
                      'AI Joboversigt',
                      style: DSTextStyle.headingMd.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: _c.text.primary, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
                child: Text(
                  'Opsummerer jobbet så du hurtigt kan vurdere det...',
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
                    AgentStreaming(:final text) =>
                      _SummaryText(text: text, streaming: true),
                    AgentDone(:final text) =>
                      _SummaryText(text: text, streaming: false),
                    AgentError(:final message) => _ErrorView(message: message),
                  },
                ),
              ),

              // Bottom action bar
              if (agentState is AgentDone || agentState is AgentError)
                _BottomBar(
                  agentState: agentState,
                  onRetry: () {
                    ref.read(agentSessionProvider.notifier).reset();
                    ref.read(agentSessionProvider.notifier).generateSummary(
                          jobContext: jobToContext(widget.job),
                        );
                  },
                  onClose: () => Navigator.of(context).pop(),
                ),

              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + DSSpacing.s4),
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

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.text, required this.streaming});

  final String text;
  final bool streaming;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.canvas,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Text(
        text,
        style: DSTextStyle.labelMd.copyWith(fontSize: 15, color: _c.text.primary, height: 1.6),
      ),
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
          'Kunne ikke hente joboversigt',
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.agentState,
    required this.onRetry,
    required this.onClose,
  });

  final AgentState agentState;
  final VoidCallback onRetry;
  final VoidCallback onClose;

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
          Expanded(
            child: DSButton(
              label: 'Luk',
              variant: DSButtonVariant.primary,
              expand: true,
              onTap: onClose,
            ),
          ),
          if (agentState is AgentError) ...[
            const SizedBox(width: DSSpacing.s3),
            DSButton(
              label: 'Prøv igen',
              variant: DSButtonVariant.tertiary,
              onTap: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
