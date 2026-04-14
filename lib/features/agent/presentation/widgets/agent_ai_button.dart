import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AgentAiButton extends StatelessWidget {
  const AgentAiButton({
    super.key,
    required this.job,
    required this.isDj,
    required this.onDraftAccepted,
  });

  final Job job;
  final bool isDj;
  final ValueChanged<String> onDraftAccepted;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: _c.brand.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(color: _c.brand.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkle, size: 13, color: _c.brand.primaryActive),
            const SizedBox(width: DSSpacing.s1),
            Text(
              'Skriv med AI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _c.brand.primaryActive,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgentBottomSheet(
        job: job,
        isDj: isDj,
        onDraftAccepted: onDraftAccepted,
      ),
    );
  }
}
