import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_ai_button.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/utils/unsaved_changes_dialog.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/copy_hint_row.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';

class InstrumentalistOfferFormScreen extends ConsumerStatefulWidget {
  const InstrumentalistOfferFormScreen({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<InstrumentalistOfferFormScreen> createState() =>
      _InstrumentalistOfferFormScreenState();
}

class _InstrumentalistOfferFormScreenState
    extends ConsumerState<InstrumentalistOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salesPitchController = TextEditingController();
  int _pitchLength = 0;
  bool _usedAiDraft = false;

  bool get _isDirty => _salesPitchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _salesPitchController.addListener(() {
      setState(() => _pitchLength = _salesPitchController.text.length);
    });
  }

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    final confirmed = await showUnsavedChangesDialog(context);
    if (confirmed == true && mounted) {
      AnalyticsService.logOfferFormAbandoned(widget.job.id, role: 'musician');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _salesPitchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final job = widget.job;
    final customerPrice = calculateCustomerMusicianPrice(
      job.requestedMusicianHours,
      job.createdAt,
    );
    final musicianPayout = calculateMusicianOfferPrice(
      job.requestedMusicianHours,
      job.createdAt,
    );
    // Self-billing constraint (client-side): a musician must complete their billing info
    // (business type, CVR/CPR and billing email) before they can send an offer. Mirrors the
    // web client gate; nudges to the payment screen instead of submitting.
    final paymentInfo = await ref.read(musicianPaymentInfoProvider.future);
    if (!mounted) return;
    final billingComplete = isSelfBillingComplete(
      SelfBillingInfo(
        businessType: paymentInfo?.businessType,
        cpr: paymentInfo?.cpr,
        cvr: paymentInfo?.cvr,
        billingEmail: paymentInfo?.billingEmail,
      ),
    );
    if (!billingComplete) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Udfyld dine faktureringsoplysninger, før du kan sende tilbud.',
      );
      context.pushNamed(AppRoutes.payment, extra: MusicianRole.instrumentalist);
      return;
    }

    final success = await ref
        .read(createServiceOfferProvider.notifier)
        .submit(
          jobId: job.isExtJob ? null : job.id,
          extJobId: job.isExtJob ? job.extJobId : null,
          priceDkk: customerPrice,
          musicianPayoutDkk: musicianPayout,
          salesPitch: _salesPitchController.text.trim(),
          instrument: 'saxophone',
        );

    if (!mounted) return;

    if (success) {
      AnalyticsService.logOfferSubmitted(
        job.id,
        job.eventType,
        role: 'musician',
        pitchLength: _salesPitchController.text.trim().length,
        usedAiDraft: _usedAiDraft,
      );
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Dit tilbud er sendt!',
      );
      context.pop();
    } else {
      // Surface the server's reason for meaningful rejections (e.g. job paused,
      // outside the regional window) — these are Danish from the API. Fall back
      // to a generic message otherwise.
      final error = ref.read(createServiceOfferProvider).error;

      // Self-billing gate: the server blocks the offer until billing info is
      // complete. Surface its Danish message and deep-link to the billing screen.
      if (error is BillingInfoIncompleteException) {
        final billingMessage =
            error.message.isNotEmpty
                ? error.message
                : 'Udfyld dine faktureringsoplysninger, før du kan sende tilbud.';
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: billingMessage,
        );
        context.pushNamed(
          AppRoutes.payment,
          extra: MusicianRole.instrumentalist,
        );
        return;
      }

      final message =
          error is AppException && error.message.isNotEmpty
              ? error.message
              : 'Kunne ikke sende tilbud. Prøv igen.';
      DSToast.show(context, variant: DSToastVariant.error, title: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final job = widget.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final createState = ref.watch(createServiceOfferProvider);
    final isLoading = createState is AsyncLoading;
    final conflictAsync = ref.watch(dateConflictProvider(job.date));
    final hasConflict = conflictAsync.valueOrNull == true;
    final hasActiveOffer = job.hasActiveOffer;
    final musicianPayout = calculateMusicianOfferPrice(
      job.requestedMusicianHours,
      job.createdAt,
    );
    final customerPrice = calculateCustomerMusicianPrice(
      job.requestedMusicianHours,
      job.createdAt,
    );
    String fmt(int n) =>
        NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: _c.bg.canvas,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  eventTypeLabel(job.eventType),
                  style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              JobIdBadge(
                id: job.isExtJob ? (job.extJobId ?? job.id) : job.id,
                isExtJob: job.isExtJob,
              ),
              const SizedBox(width: 8),
            ],
          ),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(DSSpacing.s4),
            children: [
              // Taken by another musician
              if (hasActiveOffer) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DSSpacing.s4),
                  decoration: BoxDecoration(
                    color: _c.state.warning.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(DSRadius.md),
                    border: Border.all(
                      color: _c.state.warning.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 16,
                            color: _c.state.warning,
                          ),
                          const SizedBox(width: DSSpacing.s2),
                          Text(
                            'Jobbet er desværre optaget',
                            style: DSTextStyle.headingSm.copyWith(
                              color: _c.text.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DSSpacing.s2),
                      Text(
                        'En anden saxofonist har allerede afgivet et aktivt tilbud på dette job. Skulle tilbuddet blive trukket tilbage, vil jobbet automatisk blive tilgængeligt igen.',
                        style: DSTextStyle.bodyMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.s4),
              ],

              // Date conflict warning
              if (!hasActiveOffer && hasConflict) ...[
                Container(
                  padding: const EdgeInsets.all(DSSpacing.s3),
                  decoration: BoxDecoration(
                    color: _c.state.danger.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    border: Border.all(
                      color: _c.state.danger.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: _c.state.danger,
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Expanded(
                        child: Text(
                          'Du har allerede et aktivt tilbud på denne dato. Du kan kun afgive ét tilbud pr. dag.',
                          style: DSTextStyle.labelMd.copyWith(
                            color: _c.state.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.s4),
              ],
              // Job summary
              DSSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eventTypeLabel(job.eventType),
                            style: DSTextStyle.headingSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _c.text.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        JobIdBadge(
                          id: job.isExtJob ? (job.extJobId ?? job.id) : job.id,
                          isExtJob: job.isExtJob,
                        ),
                      ],
                    ),
                    const SizedBox(height: DSSpacing.s2),
                    _InfoRow(LucideIcons.calendar, dateStr),
                    const SizedBox(height: DSSpacing.s1),
                    // Mirrors the open job card (job_card.dart, musician view).
                    if (job.roleType == 'musician_only') ...[
                      _InfoRow(
                        job.musicianStartTime != null
                            ? LucideIcons.music
                            : LucideIcons.clock,
                        job.musicianStartTime != null
                            ? 'Saxofonist: ${job.musicianStartTime}'
                            : job.timeDisplay,
                      ),
                      const SizedBox(height: DSSpacing.s1),
                    ] else ...[
                      _InfoRow(LucideIcons.clock, 'DJ: ${job.timeDisplay}'),
                      const SizedBox(height: DSSpacing.s1),
                      if (job.musicianStartTime != null) ...[
                        _InfoRow(
                          LucideIcons.music,
                          'Saxofonist: ${job.musicianStartTime}',
                        ),
                        const SizedBox(height: DSSpacing.s1),
                      ],
                    ],
                    _InfoRow(LucideIcons.flag, job.region),
                    if (job.placeLabel.isNotEmpty) ...[
                      const SizedBox(height: DSSpacing.s1),
                      _InfoRow(LucideIcons.mapPin, job.placeLabel),
                    ],
                    if (job.guestsAmount > 0) ...[
                      const SizedBox(height: DSSpacing.s1),
                      _InfoRow(LucideIcons.users, '${job.guestsAmount} gæster'),
                    ],
                    if (job.requestedMusicianHours != null) ...[
                      const SizedBox(height: DSSpacing.s1),
                      _InfoRow(
                        LucideIcons.timer,
                        '${job.musicianHoursDisplay} timers musik ønsket',
                      ),
                    ],
                    if (job.leadRequest != null &&
                        job.leadRequest!.isNotEmpty) ...[
                      const SizedBox(height: DSSpacing.s3),
                      const Divider(height: 1),
                      const SizedBox(height: DSSpacing.s3),
                      Text(
                        'Kundens ønske',
                        style: DSTextStyle.labelSm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _c.text.muted,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s1),
                      Text(
                        job.leadRequest!,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s2),
                      CopyHintRow(
                        text: job.leadRequest!,
                        copiedTitle: 'Kundens ønske kopieret',
                      ),
                    ],
                    if (job.additionalInformation != null &&
                        job.additionalInformation!.isNotEmpty) ...[
                      const SizedBox(height: DSSpacing.s3),
                      const Divider(height: 1),
                      const SizedBox(height: DSSpacing.s3),
                      Text(
                        'Yderligere information',
                        style: DSTextStyle.labelSm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _c.text.muted,
                        ),
                      ),
                      const SizedBox(height: DSSpacing.s1),
                      Text(
                        job.additionalInformation!,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                    if (job.musicianSpecialRequest != null &&
                        job.musicianSpecialRequest!.isNotEmpty) ...[
                      const SizedBox(height: DSSpacing.s3),
                      const Divider(height: 1),
                      const SizedBox(height: DSSpacing.s3),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            size: 14,
                            color: _c.state.warning,
                          ),
                          const SizedBox(width: DSSpacing.s1),
                          Text(
                            'Særligt ønske til musikeren',
                            style: DSTextStyle.labelSm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _c.state.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DSSpacing.s1),
                      Text(
                        job.musicianSpecialRequest!,
                        style: DSTextStyle.labelMd.copyWith(
                          color: _c.text.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DSSpacing.s6),

              if (!hasActiveOffer) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Din betaling',
                      style: DSTextStyle.labelMd.copyWith(
                        color: _c.text.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fmt(musicianPayout)} kr.',
                      style: DSTextStyle.headingLg.copyWith(
                        color: _c.text.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kundepris: ${fmt(customerPrice)} kr.',
                      style: DSTextStyle.labelMd.copyWith(
                        color: _c.text.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.s4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Besked til kunden',
                      style: DSTextStyle.labelLg.copyWith(
                        color: _c.text.primary,
                      ),
                    ),
                    AgentAiButton(
                      job: widget.job,
                      isDj: false,
                      onDraftAccepted: (draft) {
                        setState(() {
                          _salesPitchController.text = draft;
                          _usedAiDraft = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.s2),
                DSInput(
                  hint:
                      'Fortæl kunden om din erfaring, hvorfor du er den rette til jobbet...',
                  controller: _salesPitchController,
                  maxLines: 5,
                  maxLength: 450,
                  showCounter: true,
                  helperText: '$_pitchLength / 450',
                  textInputAction: TextInputAction.newline,
                  validator: (v) {
                    if (v == null || v.trim().length < 100) {
                      return 'Beskeden skal være mindst 100 tegn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DSSpacing.s6),
              ],

              if (!hasActiveOffer && !hasConflict)
                DSButton(
                  label: 'Send tilbud',
                  variant: DSButtonVariant.primary,
                  expand: true,
                  isLoading: isLoading,
                  onTap: isLoading ? null : _handleSubmit,
                ),
              const SizedBox(height: DSSpacing.s8),
            ],
          ),
        ),
      ), // PopScope
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: _c.text.secondary),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
          ),
        ),
      ],
    );
  }
}
