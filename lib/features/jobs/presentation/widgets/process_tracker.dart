import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

// @uxid lib/features/jobs/presentation/widgets/process_tracker.dart::ProcessTracker
class ProcessTracker extends StatelessWidget {
  const ProcessTracker({
    super.key,
    required this.steps,
    this.completedSteps = 0,
    this.completed,
    this.subtitles,
  });

  final List<String> steps;
  final int completedSteps;

  /// Per-step done flags, for a process whose steps can finish out of order (a delivery job's
  /// "Indhent leveringsdetaljer"). When set it wins over [completedSteps]; the current step is the
  /// first one not done.
  final List<bool>? completed;

  /// Optional small line under a step (a deadline, a tip), same length as [steps].
  final List<String?>? subtitles;

  bool _isDone(int i) => completed != null ? completed![i] : i < completedSteps;

  int get _current {
    if (completed == null) return completedSteps;
    final i = completed!.indexOf(false);
    return i < 0 ? steps.length : i;
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final current = _current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _StepCircle(
                    isCompleted: _isDone(i),
                    isCurrent: i == current,
                    number: i + 1,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: _isDone(i) ? _c.state.success : _c.border.strong,
                    ),
                ],
              ),
              const SizedBox(width: DSSpacing.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i],
                        style: DSTextStyle.bodyMd.copyWith(
                          fontWeight:
                              i == current ? FontWeight.w600 : FontWeight.w400,
                          color:
                              _isDone(i)
                                  ? _c.text.secondary
                                  : i == current
                                  ? _c.text.primary
                                  : _c.text.muted,
                        ),
                      ),
                      if (subtitles?[i] case final sub?)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            sub,
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// @uxid lib/features/jobs/presentation/widgets/process_tracker.dart::_StepCircle
class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.isCompleted,
    required this.isCurrent,
    required this.number,
  });

  final bool isCompleted;
  final bool isCurrent;
  final int number;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _c.state.success,
        ),
        child: Icon(LucideIcons.check, size: 16, color: _c.text.primary),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? _c.brand.primary : Colors.transparent,
        border: Border.all(
          color: isCurrent ? _c.brand.primary : _c.border.strong,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: DSTextStyle.labelSm.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrent ? _c.brand.onPrimary : _c.text.muted,
          ),
        ),
      ),
    );
  }
}
