import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_ai_button.dart';
import 'package:dj_tilbud_app/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/standard_message.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/equipment_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

enum _JobAction { busy, notInterested }

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

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    _salesPitchController.addListener(() {
      setState(() => _pitchLength = _salesPitchController.text.length);
    });
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
      _price + (_offersEarlySetup && _earlySetupHasPrice ? _earlySetupPriceValue : 0);
  int get _payout => (_totalPrice * 0.75).toInt();

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

  Future<void> _handleSubmit() async {
    final equipmentValid = _selectedEquipment.isNotEmpty || _noEquipmentSelected;
    if (!equipmentValid) {
      setState(() => _equipmentError = true);
    }
    if (!_formKey.currentState!.validate() || !equipmentValid) return;

    final djTier = ref.read(djProfileProvider).valueOrNull?.tier;
    final adjustedBudget = _adjustedBudgetEnd(djTier);
    final priceOverBudget = adjustedBudget != null && _price > adjustedBudget * 1.1;
    final withinFourHours = isWithinFirstFourHours(widget.job.createdAt);

    if (priceOverBudget && withinFourHours) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Du kan ikke byde over budget inden for de første 4 timer efter jobbet er oprettet. Prøv igen senere eller reducer dit tilbud.',
      );
      return;
    }

    final success = await ref.read(createDjQuoteProvider.notifier).submit(
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
              _offersEarlySetup && _earlySetupHasPrice && _earlySetupPriceValue > 0
                  ? _earlySetupPriceValue
                  : null,
        );

    if (!mounted) return;

    if (success) {
      DSToast.show(context, variant: DSToastVariant.success, title: 'Dit bud er afgivet!');
      context.pop();
    } else {
      DSToast.show(context, variant: DSToastVariant.error, title: 'Kunne ikke afgive bud. Prøv igen.');
    }
  }

  /// "Jeg er optaget den dag" — marks the job's date as unavailable and hides the job.
  Future<void> _handleMarkBusy() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || !mounted) return;

    final dateStr =
        DateFormat('yyyy-MM-dd').format(widget.job.date);

    final success = await ref
        .read(djUnavailableDatesProvider.notifier)
        .addDate(userId, dateStr);

    if (!mounted) return;

    if (success) {
      DSToast.show(context,
          variant: DSToastVariant.info,
          title: 'Dato markeret som optaget',
          description: 'Jobbet er nu skjult fra din oversigt.');
      context.pop();
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Kunne ikke markere dato. Prøv igen.');
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
      DSToast.show(context,
          variant: DSToastVariant.info,
          title: 'Tak for din feedback',
          description: 'Jobbet er nu skjult fra din oversigt.');
      context.pop();
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Kunne ikke registrere. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final createState = ref.watch(createDjQuoteProvider);
    final isLoading = createState is AsyncLoading;

    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;
    final adjustedBudget = _adjustedBudgetEnd(djTier);
    final priceOverBudget = adjustedBudget != null && _price > 0 && _price > adjustedBudget * 1.1;
    final withinFourHours = isWithinFirstFourHours(job.createdAt);
    final isBlocked = priceOverBudget && withinFourHours;

    return Scaffold(
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
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _JobAction.busy,
                child: Row(
                  children: [
                    Icon(LucideIcons.calendarX,
                        size: 18, color: _c.text.secondary),
                    const SizedBox(width: DSSpacing.s3),
                    Text('Jeg er optaget den dag',
                        style: DSTextStyle.bodyMd
                            .copyWith(color: _c.text.primary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _JobAction.notInterested,
                child: Row(
                  children: [
                    Icon(LucideIcons.thumbsDown,
                        size: 18, color: _c.text.secondary),
                    const SizedBox(width: DSSpacing.s3),
                    Text('Ikke interesseret',
                        style: DSTextStyle.bodyMd
                            .copyWith(color: _c.text.primary)),
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
            _JobSummary(job: job, dateStr: dateStr),
            const SizedBox(height: DSSpacing.s6),

            DSInput(
              label: 'Din pris',
              hint: 'F.eks. 5000',
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
                    horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
                decoration: BoxDecoration(
                  color: _c.brand.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: _c.text.secondary),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        'Du bliver betalt: $_payout kr.  (25% servicegebyr)',
                        style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
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
              onChanged: (selected, top, bund) => setState(() {
                _selectedEquipment = selected;
                _topSpeakerCount = top;
                _bottomSpeakerCount = bund;
                if (selected.isNotEmpty) {
                  _noEquipmentSelected = false;
                  _equipmentError = false;
                }
              }),
              onNoEquipmentChanged: (value) => setState(() {
                _noEquipmentSelected = value;
                if (value) {
                  _selectedEquipment = [];
                  _equipmentError = false;
                }
              }),
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
                    _StandardMessagePickerButton(
                      onSelected: (text) => setState(() {
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
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s2),
            DSInput(
              hint: 'Fortæl kunden hvorfor du er det rette valg til deres event...',
              controller: _salesPitchController,
              maxLines: 5,
              maxLength: 450,
              showCounter: true,
              helperText: '$_pitchLength / 450',
              textInputAction: TextInputAction.newline,
              validator: (v) {
                if (v == null || v.trim().length < 100) {
                  return 'Salgstalen skal være mindst 100 tegn';
                }
                return null;
              },
            ),
            const SizedBox(height: DSSpacing.s6),

            _EarlySetupSection(
              offersEarlySetup: _offersEarlySetup,
              earlySetupHasPrice: _earlySetupHasPrice,
              earlySetupPriceController: _earlySetupPriceController,
              onOffersChanged: (v) => setState(() {
                _offersEarlySetup = v;
                if (!v) _earlySetupHasPrice = false;
              }),
              onHasPriceChanged: (v) => setState(() => _earlySetupHasPrice = v),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
                      style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DSSpacing.s3),
              DSSwitch(
                value: offersEarlySetup,
                onChanged: onOffersChanged,
              ),
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
  const _JobSummary({required this.job, required this.dateStr});

  final Job job;
  final String dateStr;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
          _SummaryRow(LucideIcons.mapPin, '${job.city}, ${job.region}'),
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.users, '${job.guestsAmount} gæster'),
          const SizedBox(height: DSSpacing.s1),
          _SummaryRow(LucideIcons.banknote, job.budgetDisplay),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
                  'Dit bud er $overPercent% over kundens maksimale budget på ${adjustedBudget.toInt()} kr.',
                  style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
                ),
                if (isBlocked) ...[
                  const SizedBox(height: DSSpacing.s1),
                  Text(
                    'Du kan ikke byde over budget de første 4 timer. Prøv igen om ${hh}t ${mm}m, eller reducer prisen.',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.secondary),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

// ─── Standard Message Picker ──────────────────────────────────────────────────

class _StandardMessagePickerButton extends ConsumerWidget {
  const _StandardMessagePickerButton({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(standardMessagesProvider);
    final messages = messagesAsync.valueOrNull ?? [];
    if (messages.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showPicker(context, messages),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.listChecks, size: 14, color: _c.brand.primaryActive),
          const SizedBox(width: 4),
          Text(
            'Skabeloner',
            style: DSTextStyle.labelSm.copyWith(
              fontWeight: FontWeight.w600,
              color: _c.brand.primaryActive,
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, List<StandardMessage> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StandardMessagePickerSheet(
        messages: messages,
        onSelected: onSelected,
      ),
    );
  }
}

class _StandardMessagePickerSheet extends StatelessWidget {
  const _StandardMessagePickerSheet({
    required this.messages,
    required this.onSelected,
  });

  final List<StandardMessage> messages;
  final ValueChanged<String> onSelected;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Vælg standardbesked',
                    style: DSTextStyle.headingSm
                        .copyWith(color: _c.text.primary),
                  ),
                ),
                DSIconButton(
                  icon: LucideIcons.x,
                  variant: DSIconButtonVariant.ghost,
                  size: DSButtonSize.sm,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _c.border.subtle),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: DSSpacing.s2),
              itemCount: messages.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _c.border.subtle),
              itemBuilder: (context, i) {
                final msg = messages[i];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(msg.messageText);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _c.brand.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            msg.eventType,
                            style: DSTextStyle.labelSm.copyWith(
                              color: _c.brand.primaryActive,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg.messageText,
                          style: DSTextStyle.bodyMd
                              .copyWith(color: _c.text.secondary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
  static const _c = lightColors;

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
    if (_selected.contains('Andet') && _otherController.text.trim().isNotEmpty) {
      list.add(_otherController.text.trim());
    } else if (_selected.contains('Andet')) {
      list.add('Andet');
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
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
          Text('Ikke interesseret?',
              style: DSTextStyle.headingSm.copyWith(color: _c.text.primary)),
          const SizedBox(height: DSSpacing.s1),
          Text(
            'Fortæl os hvorfor — vi bruger din feedback til at forbedre vores jobudbud.',
            style:
                DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.4),
          ),
          const SizedBox(height: DSSpacing.s4),
          ..._predefined.map((reason) => _ReasonRow(
                label: reason,
                selected: _selected.contains(reason),
                onChanged: (v) => setState(() {
                  if (v) {
                    _selected.add(reason);
                  } else {
                    _selected.remove(reason);
                    if (reason == 'Andet') _otherController.clear();
                  }
                }),
              )),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
