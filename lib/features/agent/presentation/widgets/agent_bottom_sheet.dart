import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/domain/entities/agent_state.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Max fraction of the screen the sheet may take. Also the size it snaps to when the refine
/// input is focused, so the composer has as much room as possible above the keyboard.
const double _maxSheetSize = 0.95;

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
  bool _started = false;
  DateTime? _requestStartTime;
  final _sheetController = DraggableScrollableController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _kickOff();
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Grow the sheet to full height when the refine input takes focus. The sheet keeps its own
  /// height when the keyboard opens (a modal bottom sheet is NOT resized by the keyboard), so
  /// without this the composer + action bar end up behind the keyboard.
  void _expandForKeyboard() {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size >= _maxSheetSize - 0.01) return;
    _sheetController.animateTo(
      _maxSheetSize,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _kickOff() {
    _requestStartTime = DateTime.now();
    final jobContext = jobToContext(widget.job);

    if (widget.isDj) {
      ref
          .read(djProfileProvider.future)
          .then((profile) {
            if (!mounted) return;
            ref
                .read(agentSessionProvider.notifier)
                .generateDraft(
                  jobContext: jobContext,
                  userContext: djToUserContext(profile),
                  userRole: 'dj',
                );
          })
          .catchError((_) {
            if (!mounted) return;
            ref
                .read(agentSessionProvider.notifier)
                .generateDraft(
                  jobContext: jobContext,
                  userContext: {'instrument': 'dj'},
                  userRole: 'dj',
                );
          });
    } else {
      ref
          .read(musicianProfileProvider.future)
          .then((profile) {
            if (!mounted) return;
            ref
                .read(agentSessionProvider.notifier)
                .generateDraft(
                  jobContext: jobContext,
                  userContext: musicianToUserContext(profile),
                  userRole: 'musician',
                );
          })
          .catchError((_) {
            if (!mounted) return;
            ref
                .read(agentSessionProvider.notifier)
                .generateDraft(
                  jobContext: jobContext,
                  userContext: {'instrument': 'saxofon'},
                  userRole: 'musician',
                );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final agentState = ref.watch(agentSessionProvider);

    ref.listen<AgentState>(agentSessionProvider, (prev, next) {
      if (next is AgentDone && prev is! AgentDone) {
        final latencyMs =
            _requestStartTime != null
                ? DateTime.now().difference(_requestStartTime!).inMilliseconds
                : 0;
        AnalyticsService.logAiDraftReceived(
          widget.job.id,
          latencyMs: latencyMs,
        );
        ref.invalidate(agentUsageProvider);
      }
    });

    // A modal bottom sheet is not resized by the keyboard, so shrink the sheet's own content by
    // the keyboard inset — everything below (composer + action bar) then sits above it.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: _maxSheetSize,
      expand: false,
      builder: (context, scrollController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Never eat more than the sheet has: dragging the sheet down while the keyboard is
            // open would otherwise leave the content 0px tall.
            final inset = keyboardInset.clamp(
              0.0,
              (constraints.maxHeight - 260).clamp(0.0, double.infinity),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: Container(
                decoration: BoxDecoration(
                  color: _c.bg.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 18,
                            color: _c.brand.primaryActive,
                          ),
                          const SizedBox(width: DSSpacing.s2),
                          Text(
                            'Salgstale',
                            style: DSTextStyle.headingMd.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _c.text.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DSSpacing.s2),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s4,
                      ),
                      child: Text(
                        'Genererer et udkast baseret på jobbet og din profil...',
                        style: DSTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w400,
                          color: _c.text.secondary,
                        ),
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
                          AgentStreaming(:final text) => _DraftText(
                            text: text,
                            streaming: true,
                          ),
                          AgentDone(:final text) => _DraftText(
                            text: text,
                            streaming: false,
                          ),
                          AgentError(:final message) => _ErrorView(
                            message: message,
                          ),
                        },
                      ),
                    ),

                    // Refine composer — pinned below the scrolling draft (NOT inside the scroll view),
                    // so it stays visible while the musician types with the keyboard open.
                    if (agentState is AgentDone)
                      _RefinementStrip(
                        onRefine:
                            (message) => ref
                                .read(agentSessionProvider.notifier)
                                .refineWith(message),
                        onInputFocused: _expandForKeyboard,
                      ),

                    // Action buttons
                    if (agentState is AgentDone || agentState is AgentError)
                      _ActionBar(
                        agentState: agentState,
                        onAccept: () {
                          if (agentState is AgentDone) {
                            AnalyticsService.logAiDraftAccepted(
                              widget.job.id,
                              role: widget.isDj ? 'dj' : 'musician',
                            );
                            widget.onDraftAccepted(agentState.text);
                            Navigator.of(context).pop();
                          }
                        },
                        onRetry: () {
                          ref.read(agentSessionProvider.notifier).reset();
                          _kickOff();
                        },
                      ),

                    SizedBox(
                      height:
                          inset > 0
                              ? DSSpacing.s2
                              : MediaQuery.of(context).padding.bottom +
                                  DSSpacing.s4,
                    ),
                  ],
                ),
              ),
            );
          },
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
    final _c = DSTheme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final dots = '.' * ((_controller.value * 4).toInt() % 4);
        return Text(
          'Tænker$dots',
          style: DSTextStyle.labelMd.copyWith(
            fontSize: 15,
            color: _c.text.secondary,
          ),
        );
      },
    );
  }
}

class _DraftText extends StatelessWidget {
  const _DraftText({required this.text, required this.streaming});

  final String text;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(DSSpacing.s4),
          decoration: BoxDecoration(
            color: _c.bg.canvas,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
          ),
          child: Text(
            text,
            style: DSTextStyle.labelMd.copyWith(
              fontSize: 15,
              color: _c.text.primary,
              height: 1.55,
            ),
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

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.alertCircle, color: _c.state.danger, size: 28),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Kunne ikke generere udkast',
          style: DSTextStyle.labelMd.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          message,
          style: DSTextStyle.labelMd.copyWith(
            fontWeight: FontWeight.w400,
            color: _c.text.secondary,
          ),
        ),
      ],
    );
  }
}

// ── Refinement strip ──────────────────────────────────────────────────────────

class _RefinementStrip extends StatefulWidget {
  const _RefinementStrip({
    required this.onRefine,
    required this.onInputFocused,
  });

  final void Function(String message) onRefine;

  /// Fired when the text field gains focus, so the sheet can grow before the keyboard covers it.
  final VoidCallback onInputFocused;

  @override
  State<_RefinementStrip> createState() => _RefinementStripState();
}

class _RefinementStripState extends State<_RefinementStrip> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) widget.onInputFocused();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _sendChip(String message) => widget.onRefine(message);

  void _sendCustom() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onRefine(text);
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);

    return Container(
      // Pinned bar: AgentBottomSheet already lifts the whole sheet above the keyboard, so this
      // must NOT add viewInsets padding of its own (that would double-count the inset).
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s3,
        DSSpacing.s4,
        DSSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        border: Border(top: BorderSide(color: _c.border.subtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vil du ændre noget?',
            style: DSTextStyle.bodySm.copyWith(
              color: _c.text.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: DSSpacing.s2),
          Wrap(
            spacing: DSSpacing.s2,
            runSpacing: DSSpacing.s2,
            children: [
              _Chip(
                label: 'Kortere',
                onTap: () => _sendChip('Gør pitchen kortere.'),
              ),
              _Chip(
                label: 'Varmere tone',
                onTap:
                    () => _sendChip(
                      'Giv pitchen en varmere, mere personlig tone.',
                    ),
              ),
              _Chip(
                label: 'Skift vinkel',
                onTap:
                    () => _sendChip(
                      'Skriv en pitch med et helt nyt åbning og en anderledes vinkel.',
                    ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendCustom(),
                  style: DSTextStyle.labelMd.copyWith(
                    fontSize: 14,
                    color: _c.text.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Skriv til AI\'en...',
                    hintStyle: DSTextStyle.labelMd.copyWith(
                      fontSize: 14,
                      color: _c.text.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: _c.bg.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      borderSide: BorderSide(color: _c.border.subtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      borderSide: BorderSide(color: _c.border.subtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      borderSide: BorderSide(color: _c.brand.primaryActive),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              GestureDetector(
                onTap: _sendCustom,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _c.brand.primaryActive,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                  ),
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: _c.brand.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _c.bg.canvas,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(color: _c.border.subtle),
        ),
        child: Text(
          label,
          style: DSTextStyle.bodySm.copyWith(
            fontSize: 13,
            color: _c.text.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

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
    final _c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s3,
        DSSpacing.s4,
        DSSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        border: Border(top: BorderSide(color: _c.border.subtle)),
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
