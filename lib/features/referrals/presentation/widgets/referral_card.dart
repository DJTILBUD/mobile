import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/referral_labels.dart';

/// One referred job in the "Dine henvisninger" list. Mirrors the card in the web
/// `ReferralsPage.tsx`: customer, event summary, the job's state and the reward state.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key, required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final state = referralJobState(referral);
    final reward = referralRewardState(referral);
    final badgeColor = switch (state.tone) {
      ReferralJobTone.success => c.state.success,
      ReferralJobTone.progress => c.state.info,
      ReferralJobTone.neutral => c.text.muted,
    };

    return DSSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            referral.job?.leadName.isNotEmpty == true
                                ? referral.job!.leadName
                                : 'Job',
                            style: DSTextStyle.bodyLg.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.text.primary,
                            ),
                          ),
                        ),
                        if (referral.jobRef != null) ...[
                          const SizedBox(width: DSSpacing.s2),
                          Text(
                            referral.jobRef!,
                            style: DSTextStyle.bodySm.copyWith(
                              color: c.text.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (referral.job != null) ...[
                      const SizedBox(height: DSSpacing.s1),
                      Text(
                        referralJobSummary(referral.job),
                        style: DSTextStyle.bodySm.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              DSStatusBadge(label: state.label, color: badgeColor),
            ],
          ),
          if (reward != null) ...[
            const SizedBox(height: DSSpacing.s2),
            Text(
              reward,
              style: DSTextStyle.labelMd.copyWith(
                color: c.brand.primaryActive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (referral.status == ReferralStatus.canceled &&
              (referral.canceledReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: DSSpacing.s2),
            Text(
              referral.canceledReason!,
              style: DSTextStyle.bodySm.copyWith(color: c.text.secondary),
            ),
          ],
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Sendt ${formatReferralDate(referral.createdAt.toLocal())}',
            style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
          ),
        ],
      ),
    );
  }
}
