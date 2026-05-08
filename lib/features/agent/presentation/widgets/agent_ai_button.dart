import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/agent/presentation/providers/agent_provider.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_bottom_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AgentAiButton extends ConsumerWidget {
  const AgentAiButton({
    super.key,
    required this.job,
    required this.isDj,
    required this.onDraftAccepted,
  });

  final Job job;
  final bool isDj;
  final ValueChanged<String> onDraftAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final usageAsync = ref.watch(agentUsageProvider);
    final usage = usageAsync.valueOrNull;
    final isLimited = usage?.isLimitReached ?? false;
    final dailyRemaining = usage?.dailyRemaining;

    final activeColor = isLimited ? c.text.muted : c.brand.primaryActive;
    final bgColor = isLimited
        ? c.bg.inputBg
        : c.brand.primary.withValues(alpha: 0.12);
    final borderColor = isLimited
        ? c.border.subtle
        : c.brand.primary.withValues(alpha: 0.5);

    String label = 'Skriv med AI';
    if (usage != null) {
      if (usage.isMonthlyLimitReached) {
        label = 'AI: maks nået';
      } else if (usage.isDailyLimitReached) {
        label = 'AI: 0 i dag';
      } else if (dailyRemaining != null && dailyRemaining <= 3) {
        label = 'Skriv med AI · $dailyRemaining';
      }
    }

    return GestureDetector(
      onTap: isLimited ? () => _showLimitDialog(context, usage!) : () => _openSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 13, color: activeColor),
            const SizedBox(width: DSSpacing.s1),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activeColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    AnalyticsService.logAiDraftRequested(
      job.id,
      job.eventType,
      role: isDj ? 'dj' : 'musician',
    );
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

  void _showLimitDialog(BuildContext context, AgentUsage usage) {
    final isDailyLimit = usage.isDailyLimitReached && !usage.isMonthlyLimitReached;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDailyLimit ? 'Daglig grænse nået' : 'Månedlig grænse nået'),
        content: Text(
          isDailyLimit
              ? 'Du har brugt dine ${usage.dailyLimit} AI-udkast for i dag. Prøv igen i morgen.'
              : 'Du har brugt dine ${usage.monthlyLimit} AI-udkast for denne måned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
