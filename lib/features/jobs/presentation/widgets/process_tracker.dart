import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProcessTracker extends StatelessWidget {
  const ProcessTracker({
    super.key,
    required this.steps,
    this.completedSteps = 0,
  });

  final List<String> steps;
  final int completedSteps;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
                    isCompleted: i < completedSteps,
                    isCurrent: i == completedSteps,
                    number: i + 1,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: i < completedSteps
                          ? _c.state.success
                          : _c.border.strong,
                    ),
                ],
              ),
              const SizedBox(width: DSSpacing.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    steps[i],
                    style: DSTextStyle.bodyMd.copyWith(
                      fontWeight: i == completedSteps
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i < completedSteps
                          ? _c.text.secondary
                          : i == completedSteps
                              ? _c.text.primary
                              : _c.text.muted,
                    ),
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

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.isCompleted,
    required this.isCurrent,
    required this.number,
  });

  final bool isCompleted;
  final bool isCurrent;
  final int number;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
        color: isCurrent ? _c.text.primary : Colors.transparent,
        border: Border.all(
          color: isCurrent ? _c.text.primary : _c.border.strong,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: DSTextStyle.labelSm.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrent ? _c.text.onDark : _c.text.muted,
          ),
        ),
      ),
    );
  }
}
