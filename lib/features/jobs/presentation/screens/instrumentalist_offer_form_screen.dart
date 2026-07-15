import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_ai_button.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/sax_offer_conflict.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/standard_message_picker_button.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/utils/unsaved_changes_dialog.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/copy_hint_row.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';

class InstrumentalistOfferFormScreen extends ConsumerStatefulWidget {
  const InstrumentalistOfferFormScreen({
    super.key,
    required this.job,
    this.source = 'list',
  });

  final Job job;

  /// Where the form was opened from: 'list' | 'notification' | 'calendar' |
  /// 'chat'. This screen is the real funnel entry, so attribution lives here.
  final String source;

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

  /// See the DJ form: stamped on open for time-on-form, and `_submitted` lets
  /// dispose() tell "left after submitting" from "abandoned".
  DateTime? _openedAt;
  bool _submitted = false;

  int? get _msSinceOpen =>
      _openedAt == null
          ? null
          : DateTime.now().difference(_openedAt!).inMilliseconds;

  bool get _isDirty => _salesPitchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _salesPitchController.addListener(() {
      setState(() => _pitchLength = _salesPitchController.text.length);
    });
    // In initState, not the route builder (builders re-run on router rebuilds),
    // and post-frame so the conflict provider has resolved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Same query the form's own block-card uses, so the logged conflict flag
      // and what the sax actually sees can never disagree.
      final conflict = ref.read(
        dateConflictProvider(
          SaxConflictQuery(
            date: widget.job.date,
            startTime: widget.job.musicianStartTime,
            endTime: saxEndTime(
              widget.job.musicianStartTime,
              widget.job.requestedMusicianHours,
            ),
          ),
        ),
      );
      AnalyticsService.logOfferFormOpened(
        widget.job.id,
        widget.job.eventType,
        role: 'musician',
        source: widget.source,
        hasConflict: conflict.valueOrNull == true,
        hasActiveOffer: widget.job.hasActiveOffer,
        isExtJob: widget.job.isExtJob,
      );
    });
  }

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    final confirmed = await showUnsavedChangesDialog(context);
    // Abandon is emitted from dispose() so the not-dirty pop is covered too.
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    if (!_submitted) {
      AnalyticsService.logOfferFormAbandoned(
        widget.job.id,
        role: 'musician',
        wasDirty: _isDirty,
        isExtJob: widget.job.isExtJob,
        pitchLength: _pitchLength,
        msOnForm: _msSinceOpen,
      );
    }
    _salesPitchController.dispose();
    super.dispose();
  }

  /// See the DJ form: every early return logs why, so a submit success rate and
  /// the reason a sax could not bid are measurable.
  void _logSubmitFailed(String reason, {String errorSource = 'client'}) {
    AnalyticsService.logOfferSubmitFailed(
      widget.job.id,
      role: 'musician',
      reason: reason,
      errorSource: errorSource,
      isExtJob: widget.job.isExtJob,
      msSinceFormOpen: _msSinceOpen,
    );
  }

  Future<void> _handleSubmit() async {
    AnalyticsService.logOfferSubmitAttempted(
      widget.job.id,
      role: 'musician',
      isExtJob: widget.job.isExtJob,
      pitchLength: _salesPitchController.text.trim().length,
      usedAiDraft: _usedAiDraft,
      msSinceFormOpen: _msSinceOpen,
    );

    if (!_formKey.currentState!.validate()) {
      _logSubmitFailed(OfferSubmitFailure.invalidInput);
      return;
    }

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
      _logSubmitFailed(OfferSubmitFailure.billingIncomplete);
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
      _submitted = true;
      AnalyticsService.logOfferSubmitted(
        job.id,
        job.eventType,
        role: 'musician',
        pitchLength: _salesPitchController.text.trim().length,
        usedAiDraft: _usedAiDraft,
        isExtJob: job.isExtJob,
        msSinceFormOpen: _msSinceOpen,
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
        _logSubmitFailed(
          OfferSubmitFailure.billingIncomplete,
          errorSource: 'server',
        );
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
      _logSubmitFailed(
        OfferSubmitFailure.fromServerMessage(message),
        errorSource: 'server',
      );
      DSToast.show(context, variant: DSToastVariant.error, title: message);
    }
  }

  /// Saves the current pitch as a reusable [StandardMessage] (the "Gem som
  /// skabelon" action). Templates are keyed by user + event type, so the job's
  /// event type is required.
  Future<void> _saveAsTemplate() async {
    final messageText = _salesPitchController.text.trim();
    if (messageText.isEmpty) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Besked til kunden kan ikke være tom',
      );
      return;
    }
    final eventType = widget.job.eventType.trim();
    if (eventType.isEmpty) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kan ikke gemme standardbesked uden en event-type',
      );
      return;
    }
    try {
      final repo = ref.read(profileRepositoryProvider);
      final userId = supabase.auth.currentUser!.id;
      await repo.createStandardMessage(
        userId: userId,
        messageText: messageText,
        eventType: eventType,
      );
      ref.invalidate(standardMessagesProvider);
      if (context.mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Standardbesked gemt',
        );
      }
    } catch (e) {
      if (context.mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Standardbeskeden kunne ikke gemmes. Prøv igen.',
          ),
        );
      }
    }
  }

  /// The musician's other still-relevant offers (sent or won) on the SAME calendar date as the job
  /// being offered on, excluding this job. Each is paired with whether it time-conflicts with this
  /// booking (gap < 3h) — a conflict means only one of the two can ultimately be won. Drives the
  /// multi-offer notice so the sax can see what they already hold that day and understand the
  /// auto-lost / don't-double-book rules. Business rule lives in [saxBookingsConflict]; this only
  /// filters + labels already-fetched offers for display.
  List<_SameDateOffer> _sameDateOffers(List<ServiceOffer> offers) {
    final job = widget.job;
    final jobDateKey = saxDateKey(job.date);
    final jobStart = job.musicianStartTime;
    final jobEnd = saxEndTime(
      job.musicianStartTime,
      job.requestedMusicianHours,
    );
    final result = <_SameDateOffer>[];
    for (final o in offers) {
      if (o.status != ServiceOfferStatus.sent &&
          o.status != ServiceOfferStatus.won) {
        continue;
      }
      // Exclude any offer already on the very job we're bidding on.
      final sameJob =
          job.isExtJob
              ? (o.extJobId != null && o.extJobId == job.extJobId)
              : (o.jobId != null && o.jobId == job.id);
      if (sameJob) continue;
      if (saxDateKey(o.job.date) != jobDateKey) continue;
      final conflicts = saxBookingsConflict(
        dateA: jobDateKey,
        startA: jobStart,
        endA: jobEnd,
        dateB: saxDateKey(o.job.date),
        startB: o.job.musicianStartTime,
        endB: saxEndTime(o.job.musicianStartTime, o.job.requestedMusicianHours),
      );
      result.add(_SameDateOffer(offer: o, conflicts: conflicts));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final job = widget.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final createState = ref.watch(createServiceOfferProvider);
    final isLoading = createState is AsyncLoading;
    final conflictAsync = ref.watch(
      dateConflictProvider(
        SaxConflictQuery(
          date: job.date,
          startTime: job.musicianStartTime,
          endTime: saxEndTime(
            job.musicianStartTime,
            job.requestedMusicianHours,
          ),
        ),
      ),
    );
    final hasConflict = conflictAsync.valueOrNull == true;
    final hasActiveOffer = job.hasActiveOffer;
    // Other sent/won offers the sax already holds on this date (drives the multi-offer notice).
    final sameDateOffers = _sameDateOffers(
      ref.watch(serviceOffersProvider).valueOrNull ?? const <ServiceOffer>[],
    );
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
                          'Du har allerede vundet et job på et overlappende tidspunkt denne dag. Du kan kun spille to jobs samme dag, hvis der er mindst 3 timer imellem dem.',
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

              // Multi-offer notice — the sax already holds another offer this date. The feature
              // deliberately allows several same-day offers, so this INFORMS (does not block):
              // shows what they already bid on, the auto-lost rule for wins < 3h apart, and that
              // avoiding a real double-booking is their own responsibility.
              if (!hasActiveOffer &&
                  !hasConflict &&
                  sameDateOffers.isNotEmpty) ...[
                _MultiOfferNotice(others: sameDateOffers),
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

                // The label gets its own row; the two actions then share one row directly
                // above the textarea ("Indsæt standardbesked" left, "Skriv med AI" right).
                // The original layout also crammed the label into that row, which was too
                // tight on narrow screens.
                // Mirrors the same block in dj_quote_form_screen.dart.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Besked til kunden',
                    style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
                  ),
                ),
                const SizedBox(height: DSSpacing.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Self-hides when the musician has no saved messages; the Row still
                    // keeps "Skriv med AI" pinned right.
                    StandardMessagePickerButton(
                      onSelected:
                          (text) => setState(() {
                            _salesPitchController.text = text;
                            _pitchLength = text.length;
                          }),
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
                  textInputAction: TextInputAction.newline,
                  validator: (v) {
                    if (v == null || v.trim().length < 100) {
                      return 'Beskeden skal være mindst 100 tegn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DSSpacing.s1),
                Row(
                  children: [
                    Text(
                      '$_pitchLength / 450',
                      style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
                    ),
                    const Spacer(),
                    SaveTemplateButton(onTap: _saveAsTemplate),
                  ],
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

/// One of the musician's existing same-date offers, plus whether it time-conflicts (gap < 3h) with
/// the booking currently being offered on.
class _SameDateOffer {
  const _SameDateOffer({required this.offer, required this.conflicts});

  final ServiceOffer offer;
  final bool conflicts;
}

/// Explains the "several offers on one date" feature on the offer form: lists what the sax already
/// holds this day, and spells out the two outcomes (auto-lost when wins are < 3h apart; own
/// responsibility not to double-book when both can be won). Informational only — never blocks.
class _MultiOfferNotice extends StatelessWidget {
  const _MultiOfferNotice({required this.others});

  final List<_SameDateOffer> others;

  String _timeLabel(ServiceOffer o) {
    final start = o.job.musicianStartTime;
    if (start == null || start.isEmpty) return '';
    final end = saxEndTime(
      o.job.musicianStartTime,
      o.job.requestedMusicianHours,
    );
    return end != null ? 'kl. $start–$end' : 'kl. $start';
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.state.warning.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.state.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 16,
                color: _c.state.warning,
              ),
              const SizedBox(width: DSSpacing.s2),
              Expanded(
                child: Text(
                  others.length == 1
                      ? 'Du har allerede et tilbud på denne dato'
                      : 'Du har allerede ${others.length} tilbud på denne dato',
                  style: DSTextStyle.headingSm.copyWith(
                    color: _c.text.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Det er helt fint at have flere tilbud samme dag. Her er hvad du allerede har budt på:',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s3),
          for (final o in others)
            Padding(
              padding: const EdgeInsets.only(bottom: DSSpacing.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.music, size: 14, color: _c.text.muted),
                  const SizedBox(width: DSSpacing.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            eventTypeLabel(o.offer.job.eventType),
                            if (_timeLabel(o.offer).isNotEmpty)
                              _timeLabel(o.offer),
                            if (o.offer.status == ServiceOfferStatus.won)
                              '(vundet)',
                          ].join(' · '),
                          style: DSTextStyle.labelMd.copyWith(
                            color: _c.text.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o.conflicts
                              ? 'For tæt på dette job (under 3 timer imellem). Kun ét af dem kan vindes.'
                              : 'Mindst 3 timer imellem. Begge kan vindes.',
                          style: DSTextStyle.bodySm.copyWith(
                            color:
                                o.conflicts
                                    ? _c.state.danger
                                    : _c.state.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DSSpacing.s1),
          const Divider(height: 1),
          const SizedBox(height: DSSpacing.s3),
          const _RuleLine(
            'Vinder du to jobs med under 3 timer imellem, sætter vi automatisk det ene tilbud til “tabt”. Du kan ikke vindes til begge.',
          ),
          const SizedBox(height: DSSpacing.s2),
          const _RuleLine(
            'Er der mindst 3 timer imellem, kan du vinde begge. Så er det dit eget ansvar at nå frem og spille begge, så du ikke dobbeltbooker dig selv.',
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(LucideIcons.info, size: 13, color: _c.text.muted),
        ),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: DSTextStyle.bodySm.copyWith(
              color: _c.text.secondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
