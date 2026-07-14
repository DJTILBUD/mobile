import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/router/app_routes.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/features/jobs/domain/dj_fee.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_ai_button.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/date_collision.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_complete.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_picker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/standard_message_picker_button.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/utils/unsaved_changes_dialog.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

enum _JobAction { busy, notInterested }

String _fmt(num n) =>
    NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

class DjQuoteFormScreen extends ConsumerStatefulWidget {
  const DjQuoteFormScreen({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<DjQuoteFormScreen> createState() => _DjQuoteFormScreenState();
}

class _DjQuoteFormScreenState extends ConsumerState<DjQuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _salesPitchController = TextEditingController();
  final _earlySetupPriceController = TextEditingController();
  int _pitchLength = 0;

  // Equipment picker state
  List<String> _selectedEquipment = [];
  int _topSpeakerCount = 2;
  int _bottomSpeakerCount = 2;
  bool _noEquipmentSelected = false;
  bool _equipmentError = false;

  bool _offersEarlySetup = false;
  bool _earlySetupHasPrice = false;

  bool _usedAiDraft = false;

  bool get _isDirty =>
      _priceController.text.isNotEmpty ||
      _salesPitchController.text.isNotEmpty ||
      _selectedEquipment.isNotEmpty ||
      _noEquipmentSelected ||
      _offersEarlySetup;

  @override
  void initState() {
    super.initState();
    _salesPitchController.addListener(() {
      setState(() => _pitchLength = _salesPitchController.text.length);
    });
    _priceController.addListener(() => setState(() {}));
    _earlySetupPriceController.addListener(() => setState(() {}));
  }

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    final confirmed = await showUnsavedChangesDialog(context);
    if (confirmed == true && mounted) {
      AnalyticsService.logOfferFormAbandoned(widget.job.id, role: 'dj');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _salesPitchController.dispose();
    _earlySetupPriceController.dispose();
    super.dispose();
  }

  int get _price => int.tryParse(_priceController.text) ?? 0;
  int get _earlySetupPriceValue =>
      int.tryParse(_earlySetupPriceController.text) ?? 0;
  int get _totalPrice =>
      _price +
      (_offersEarlySetup && _earlySetupHasPrice ? _earlySetupPriceValue : 0);
  double get _fee => getFeeForJob(widget.job.createdAt);
  int get _payout => (_totalPrice * (1 - _fee)).toInt();

  double? _adjustedBudgetEnd(String? djTier) {
    final job = widget.job;
    final raw = adjustBudgetForDjView(
      budget: job.budgetEnd,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );
    final start = adjustBudgetForDjView(
      budget: job.budgetStart,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );
    if (raw == null) return null;
    if (start != null && start > raw) return start;
    return raw;
  }

  String _adjustedBudgetDisplay(String? djTier) {
    final job = widget.job;
    final noBudget = job.budgetStart == null && job.budgetEnd == null;
    if (djTier == 'B' && noBudget) return '3.500 – 6.500 kr.';

    final adjEnd = adjustBudgetForDjView(
      budget: job.budgetEnd ?? job.budgetStart,
      requestedSaxophonist: job.requestedSaxophonist,
      requestedMusicianHours: job.requestedMusicianHours,
      djTier: djTier,
      maxBudget: job.budgetEnd,
      jobCreatedAt: job.createdAt,
    );
    if (adjEnd == null) return 'Ikke angivet';

    if (job.budgetStart != null && job.budgetStart != job.budgetEnd) {
      final adjStart = adjustBudgetForDjView(
        budget: job.budgetStart,
        requestedSaxophonist: job.requestedSaxophonist,
        requestedMusicianHours: job.requestedMusicianHours,
        djTier: djTier,
        maxBudget: job.budgetEnd,
        jobCreatedAt: job.createdAt,
      );
      if (adjStart != null) {
        final adjEndClamped = adjEnd > adjStart ? adjEnd : adjStart;
        return '${_fmtNum(adjStart.toInt())} – ${_fmtNum(adjEndClamped.toInt())} kr.';
      }
    }
    return '${_fmtNum(adjEnd.toInt())} kr.';
  }

  static String _fmtNum(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  Future<void> _handleSubmit() async {
    final equipmentValid =
        _selectedEquipment.isNotEmpty || _noEquipmentSelected;
    if (!equipmentValid) {
      setState(() => _equipmentError = true);
    }
    if (!_formKey.currentState!.validate() || !equipmentValid) return;

    // Date-collision guard (server also enforces this; this avoids a wasted
    // round-trip and an unclear failure when reached via deep-link).
    final collisionMessage = dateCollisionMessage(
      widget.job,
      ref.read(djQuotesProvider).valueOrNull ?? [],
      ref.read(djExtJobsProvider).valueOrNull ?? [],
    );
    if (collisionMessage != null) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: collisionMessage,
      );
      return;
    }

    final djTier = ref.read(djProfileProvider).valueOrNull?.tier;
    final adjustedBudget = _adjustedBudgetEnd(djTier);
    final priceOverBudget =
        adjustedBudget != null && _price > adjustedBudget * 1.1;
    final withinFourHours = isWithinFirstFourHours(widget.job.createdAt);

    if (priceOverBudget && withinFourHours) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title:
            'Du kan ikke byde over budget inden for de første 4 timer efter jobbet er oprettet. Prøv igen senere eller reducer dit tilbud.',
      );
      return;
    }

    // Self-billing constraint (client-side): a DJ must complete their billing info
    // (business type, CVR/CPR and billing email) before they can bid. Mirrors the
    // web client gate; nudges to the payment screen instead of submitting.
    final paymentInfo = await ref.read(djPaymentInfoProvider.future);
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
        title: 'Udfyld dine faktureringsoplysninger, før du kan afgive bud.',
      );
      context.pushNamed(AppRoutes.payment, extra: MusicianRole.dj);
      return;
    }

    final success = await ref
        .read(createDjQuoteProvider.notifier)
        .submit(
          jobId: widget.job.id,
          priceDkk: _price,
          equipmentDescription: serializeEquipmentDescription(
            _selectedEquipment,
            _topSpeakerCount,
            _bottomSpeakerCount,
          ),
          salesPitch: _salesPitchController.text.trim(),
          earlySetupStatus: _offersEarlySetup ? 'offered' : null,
          earlySetupPrice:
              _offersEarlySetup &&
                      _earlySetupHasPrice &&
                      _earlySetupPriceValue > 0
                  ? _earlySetupPriceValue
                  : null,
        );

    if (!mounted) return;

    if (success) {
      AnalyticsService.logOfferSubmitted(
        widget.job.id,
        widget.job.eventType,
        role: 'dj',
        pitchLength: _salesPitchController.text.trim().length,
        usedAiDraft: _usedAiDraft,
      );
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Dit bud er afgivet!',
      );
      context.pop();
    } else {
      // Surface the server's reason when it's a meaningful rejection (e.g. tier
      // quota full, 3 quotes already placed, suppressed DJ) — these are
      // permanent, so the generic "try again" would be misleading. Note we read
      // AppException.message directly: DatabaseException.toString() returns a
      // generic fallback, but .message carries the route's Danish message.
      final error = ref.read(createDjQuoteProvider).error;

      // Self-billing gate: the server blocks the quote until billing info is
      // complete. Surface its Danish message and deep-link to the billing screen.
      if (error is BillingInfoIncompleteException) {
        final message =
            error.message.isNotEmpty
                ? error.message
                : 'Udfyld dine faktureringsoplysninger, før du kan afgive bud.';
        DSToast.show(context, variant: DSToastVariant.error, title: message);
        context.pushNamed(AppRoutes.payment, extra: MusicianRole.dj);
        return;
      }

      final message =
          error is AppException && error.message.isNotEmpty
              ? error.message
              : 'Kunne ikke afgive bud. Prøv igen.';
      DSToast.show(context, variant: DSToastVariant.error, title: message);
    }
  }

  /// "Jeg er optaget den dag" — marks the job's date as unavailable and hides the job.
  Future<void> _handleMarkBusy() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || !mounted) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.job.date);

    final success = await ref
        .read(djUnavailableDatesProvider.notifier)
        .addDate(userId, dateStr);

    if (!mounted) return;

    if (success) {
      AnalyticsService.logDateMarkedUnavailable();
      DSToast.show(
        context,
        variant: DSToastVariant.info,
        title: 'Dato markeret som optaget',
        description: 'Jobbet er nu skjult fra din oversigt.',
      );
      context.pop();
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke markere dato. Prøv igen.',
      );
    }
  }

  /// "Ikke interesseret" — shows a reason picker sheet then records the rejection.
  Future<void> _handleNotInterested() async {
    final reasons = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotInterestedSheet(),
    );

    if (reasons == null || !mounted) return;

    final success = await ref
        .read(rejectDjJobProvider.notifier)
        .reject(widget.job.id, reasons: reasons);

    if (!mounted) return;

    if (success) {
      DSToast.show(
        context,
        variant: DSToastVariant.info,
        title: 'Tak for din feedback',
        description: 'Jobbet er nu skjult fra din oversigt.',
      );
      context.pop();
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke registrere. Prøv igen.',
      );
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

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final job = widget.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final createState = ref.watch(createDjQuoteProvider);
    final isLoading = createState is AsyncLoading;

    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;
    final adjustedBudget = _adjustedBudgetEnd(djTier);
    final priceOverBudget =
        adjustedBudget != null && _price > 0 && _price > adjustedBudget * 1.1;
    final withinFourHours = isWithinFirstFourHours(job.createdAt);

    // Date-collision guard (mirrors web `collidingQuote`; server enforces it too).
    // This screen is reachable via push deep-link, bypassing the job list's own
    // collision check, so it must guard independently.
    final quotes = ref.watch(djQuotesProvider).valueOrNull ?? [];
    final extJobs = ref.watch(djExtJobsProvider).valueOrNull ?? [];
    final collisionMessage = dateCollisionMessage(job, quotes, extJobs);

    final isBlocked =
        (priceOverBudget && withinFourHours) || collisionMessage != null;

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
              JobIdBadge(id: job.id),
              const SizedBox(width: 8),
            ],
          ),
          backgroundColor: _c.bg.surface,
          surfaceTintColor: _c.bg.surface,
          actions: [
            PopupMenuButton<_JobAction>(
              icon: Icon(LucideIcons.moreVertical, color: _c.text.primary),
              color: _c.bg.surface,
              onSelected: (action) {
                if (action == _JobAction.busy) _handleMarkBusy();
                if (action == _JobAction.notInterested) _handleNotInterested();
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: _JobAction.busy,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendarX,
                            size: 18,
                            color: _c.text.secondary,
                          ),
                          const SizedBox(width: DSSpacing.s3),
                          Text(
                            'Jeg er optaget den dag',
                            style: DSTextStyle.bodyMd.copyWith(
                              color: _c.text.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _JobAction.notInterested,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.thumbsDown,
                            size: 18,
                            color: _c.text.secondary,
                          ),
                          const SizedBox(width: DSSpacing.s3),
                          Text(
                            'Ikke interesseret',
                            style: DSTextStyle.bodyMd.copyWith(
                              color: _c.text.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(DSSpacing.s4),
            children: [
              _JobSummary(
                job: job,
                dateStr: dateStr,
                budgetDisplay: _adjustedBudgetDisplay(djTier),
              ),
              const SizedBox(height: DSSpacing.s6),

              if (collisionMessage != null) ...[
                _CollisionBanner(message: collisionMessage),
                const SizedBox(height: DSSpacing.s6),
              ],

              DSInput(
                label: 'Din pris',
                hint: 'F.eks. 5.000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixText: 'kr.',
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final price = int.tryParse(v ?? '') ?? 0;
                  if (price <= 0) return 'Indtast en gyldig pris';
                  return null;
                },
              ),
              const SizedBox(height: DSSpacing.s2),

              // Payout info
              AnimatedOpacity(
                opacity: _totalPrice > 0 ? 1.0 : 0.0,
                duration: DSMotion.normal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.s3,
                    vertical: DSSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: _c.brand.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: 16,
                        color: _c.text.secondary,
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      Expanded(
                        child: Text(
                          'Du bliver betalt: ${_fmt(_payout)} kr.  (${formatFeePercent(_fee)}% servicegebyr)',
                          style: DSTextStyle.labelMd.copyWith(
                            color: _c.text.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s2),

              // Over-budget warning / blocking banner
              if (priceOverBudget) ...[
                _BudgetWarningBanner(
                  price: _price,
                  adjustedBudget: adjustedBudget,
                  isBlocked: isBlocked,
                  jobCreatedAt: job.createdAt,
                ),
                const SizedBox(height: DSSpacing.s2),
              ],

              const SizedBox(height: DSSpacing.s2),

              EquipmentPicker(
                selectedEquipment: _selectedEquipment,
                topSpeakerCount: _topSpeakerCount,
                bottomSpeakerCount: _bottomSpeakerCount,
                noEquipmentSelected: _noEquipmentSelected,
                onChanged: (selected, top, bund) {
                  setState(() {
                    _selectedEquipment = selected;
                    _topSpeakerCount = top;
                    _bottomSpeakerCount = bund;
                    if (selected.isNotEmpty) {
                      _noEquipmentSelected = false;
                      _equipmentError = false;
                    }
                  });
                },
                onNoEquipmentChanged: (value) {
                  setState(() {
                    _noEquipmentSelected = value;
                    if (value) {
                      _selectedEquipment = [];
                      _equipmentError = false;
                    }
                  });
                },
              ),
              if (_equipmentError) ...[
                const SizedBox(height: DSSpacing.s1),
                Text(
                  'Vælg mindst ét stykke udstyr',
                  style: DSTextStyle.bodySm.copyWith(color: _c.state.danger),
                ),
              ],
              const SizedBox(height: DSSpacing.s4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Salgstale',
                    style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StandardMessagePickerButton(
                        onSelected:
                            (text) => setState(() {
                              _salesPitchController.text = text;
                              _pitchLength = text.length;
                            }),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                      AgentAiButton(
                        job: widget.job,
                        isDj: true,
                        onDraftAccepted: (draft) {
                          setState(() {
                            _salesPitchController.text = draft;
                            _usedAiDraft = true;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.s2),
              DSInput(
                hint:
                    'Fortæl kunden hvorfor du er det rette valg til deres event...',
                controller: _salesPitchController,
                minLines: 8,
                maxLines: 15,
                maxLength: 450,
                showCounter: true,
                textInputAction: TextInputAction.newline,
                validator: (v) {
                  if (v == null || v.trim().length < 100) {
                    return 'Salgstalen skal være mindst 100 tegn';
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

              _EarlySetupSection(
                offersEarlySetup: _offersEarlySetup,
                earlySetupHasPrice: _earlySetupHasPrice,
                earlySetupPriceController: _earlySetupPriceController,
                onOffersChanged: (v) {
                  setState(() {
                    _offersEarlySetup = v;
                    if (!v) _earlySetupHasPrice = false;
                  });
                },
                onHasPriceChanged: (v) {
                  setState(() => _earlySetupHasPrice = v);
                },
              ),
              const SizedBox(height: DSSpacing.s6),

              DSButton(
                label: 'Afgiv bud',
                variant: DSButtonVariant.primary,
                expand: true,
                isLoading: isLoading,
                enabled: !isBlocked,
                onTap: isLoading || isBlocked ? null : _handleSubmit,
              ),
              const SizedBox(height: DSSpacing.s8),
            ],
          ),
        ),
      ), // PopScope
    );
  }
}

class _CollisionBanner extends StatelessWidget {
  const _CollisionBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.state.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _c.state.danger.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.calendarX, size: 18, color: _c.state.danger),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konflikt med eksisterende booking',
                  style: DSTextStyle.labelSm.copyWith(
                    color: _c.state.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DSSpacing.s1),
                Text(
                  message,
                  style: DSTextStyle.bodySm.copyWith(
                    color: _c.text.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlySetupSection extends StatelessWidget {
  const _EarlySetupSection({
    required this.offersEarlySetup,
    required this.earlySetupHasPrice,
    required this.earlySetupPriceController,
    required this.onOffersChanged,
    required this.onHasPriceChanged,
  });

  final bool offersEarlySetup;
  final bool earlySetupHasPrice;
  final TextEditingController earlySetupPriceController;
  final ValueChanged<bool> onOffersChanged;
  final ValueChanged<bool> onHasPriceChanged;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tidlig opsætning',
                      style: DSTextStyle.labelLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _c.text.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tilbyd at møde op tidligt og sætte udstyr op inden eventet',
                      style: DSTextStyle.bodySm.copyWith(
                        color: _c.text.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DSSpacing.s3),
              DSSwitch(value: offersEarlySetup, onChanged: onOffersChanged),
            ],
          ),
          if (offersEarlySetup) ...[
            const SizedBox(height: DSSpacing.s4),
            const Divider(height: 1),
            const SizedBox(height: DSSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pris for tidlig opsætning',
                    style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
                  ),
                ),
                DSSwitch(
                  value: earlySetupHasPrice,
                  onChanged: onHasPriceChanged,
                ),
              ],
            ),
            if (earlySetupHasPrice) ...[
              const SizedBox(height: DSSpacing.s3),
              DSInput(
                hint: 'F.eks. 500',
                controller: earlySetupPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixText: 'kr.',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({
    required this.job,
    required this.dateStr,
    required this.budgetDisplay,
  });

  final Job job;
  final String dateStr;
  final String budgetDisplay;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return DSSurface(
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
              JobIdBadge(id: job.id),
            ],
          ),
          const SizedBox(height: DSSpacing.s2),
          _SummaryRow(LucideIcons.calendar, dateStr),
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.clock, job.timeDisplay),
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.flag, job.region),
          if (job.placeLabel.isNotEmpty) ...[
            const SizedBox(height: DSSpacing.s1),
            _SummaryRow(LucideIcons.mapPin, job.placeLabel),
          ],
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.users, '${job.guestsAmount} gæster'),
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.banknote, budgetDisplay),
          if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
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
              style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
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
              style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetWarningBanner extends StatelessWidget {
  const _BudgetWarningBanner({
    required this.price,
    required this.adjustedBudget,
    required this.isBlocked,
    required this.jobCreatedAt,
  });

  final int price;
  final double adjustedBudget;
  final bool isBlocked;
  final DateTime jobCreatedAt;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final overPercent = ((price / adjustedBudget - 1) * 100).round();
    final color = isBlocked ? _c.state.danger : _c.state.warning;
    final icon = isBlocked ? LucideIcons.ban : LucideIcons.alertTriangle;

    final deadline = jobCreatedAt.add(const Duration(hours: 4));
    final remaining = deadline.difference(DateTime.now());
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dit bud er $overPercent% over kundens maksimale budget på ${_fmt(adjustedBudget.toInt())} kr.',
                  style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
                ),
                if (isBlocked) ...[
                  const SizedBox(height: DSSpacing.s1),
                  Text(
                    'Du kan ikke byde over budget de første 4 timer. Prøv igen om ${hh}t ${mm}m, eller reducer prisen.',
                    style: DSTextStyle.bodySm.copyWith(
                      color: _c.text.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.icon, this.text);

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

// ─── Not Interested Bottom Sheet ─────────────────────────────────────────────

class _NotInterestedSheet extends StatefulWidget {
  const _NotInterestedSheet();

  @override
  State<_NotInterestedSheet> createState() => _NotInterestedSheetState();
}

class _NotInterestedSheetState extends State<_NotInterestedSheet> {
  static const _predefined = [
    'Budgettet er for lavt',
    'Jeg spiller ikke til denne type events',
    'Andet',
  ];

  final Set<String> _selected = {};
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selected.isNotEmpty;

  List<String> get _reasons {
    final list = _selected.where((r) => r != 'Andet').toList();
    if (_selected.contains('Andet') &&
        _otherController.text.trim().isNotEmpty) {
      list.add(_otherController.text.trim());
    } else if (_selected.contains('Andet')) {
      list.add('Andet');
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: DSSpacing.s4,
        right: DSSpacing.s4,
        top: DSSpacing.s4,
        bottom: DSSpacing.s4 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _c.border.subtle,
                borderRadius: BorderRadius.circular(DSRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.s4),
          Text(
            'Ikke interesseret?',
            style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            'Fortæl os hvorfor — vi bruger din feedback til at forbedre vores jobudbud.',
            style: DSTextStyle.bodyMd.copyWith(
              color: _c.text.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DSSpacing.s4),
          ..._predefined.map(
            (reason) => _ReasonRow(
              label: reason,
              selected: _selected.contains(reason),
              onChanged:
                  (v) => setState(() {
                    if (v) {
                      _selected.add(reason);
                    } else {
                      _selected.remove(reason);
                      if (reason == 'Andet') _otherController.clear();
                    }
                  }),
            ),
          ),
          if (_selected.contains('Andet')) ...[
            const SizedBox(height: DSSpacing.s2),
            DSInput(
              hint: 'Beskriv årsagen...',
              controller: _otherController,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Ikke interesseret',
            expand: true,
            onTap: _canSubmit ? () => Navigator.pop(context, _reasons) : null,
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: DSCheckbox(label: label, value: selected, onChanged: onChanged),
      ),
    );
  }
}
