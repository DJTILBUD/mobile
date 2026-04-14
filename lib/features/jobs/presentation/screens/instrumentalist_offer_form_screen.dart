import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/core/utils/musician_price.dart';
import 'package:dj_tilbud_app/features/agent/presentation/widgets/agent_ai_button.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

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
  final _priceController = TextEditingController();
  final _salesPitchController = TextEditingController();
  int _pitchLength = 0;

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the time-based musician payout price
    final autoPrice = calculateMusicianOfferPrice(
      widget.job.requestedMusicianHours,
      widget.job.createdAt,
    );
    _priceController.text = autoPrice.toString();
    _salesPitchController.addListener(() {
      setState(() => _pitchLength = _salesPitchController.text.length);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _salesPitchController.dispose();
    super.dispose();
  }

  int get _price => int.tryParse(_priceController.text) ?? 0;

  String _locationDisplay(String city, String region) {
    final parts = [city, region].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Ikke angivet' : parts.join(', ');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final job = widget.job;
    final customerPrice = calculateCustomerMusicianPrice(job.requestedMusicianHours);
    final success = await ref.read(createServiceOfferProvider.notifier).submit(
          jobId: job.isExtJob ? null : job.id,
          extJobId: job.isExtJob ? job.extJobId : null,
          priceDkk: customerPrice,       // what the customer pays
          musicianPayoutDkk: _price,     // what the musician earns
          salesPitch: _salesPitchController.text.trim(),
          instrument: 'saxophone',
        );

    if (!mounted) return;

    if (success) {
      DSToast.show(context, variant: DSToastVariant.success, title: 'Dit tilbud er sendt!');
      context.pop();
    } else {
      DSToast.show(context, variant: DSToastVariant.error, title: 'Kunne ikke sende tilbud. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final createState = ref.watch(createServiceOfferProvider);
    final isLoading = createState is AsyncLoading;
    final conflictAsync = ref.watch(dateConflictProvider(job.date));
    final hasConflict = conflictAsync.valueOrNull == true;

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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DSSpacing.s4),
          children: [
            // Date conflict warning
            if (hasConflict) ...[
              Container(
                padding: const EdgeInsets.all(DSSpacing.s3),
                decoration: BoxDecoration(
                  color: _c.state.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  border: Border.all(color: _c.state.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: _c.state.danger),
                    const SizedBox(width: DSSpacing.s2),
                    Expanded(
                      child: Text(
                        'Du har allerede et aktivt tilbud på denne dato. Du kan kun afgive ét tilbud pr. dag.',
                        style: DSTextStyle.labelMd.copyWith(color: _c.state.danger),
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
                      JobIdBadge(id: job.id),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  _InfoRow(LucideIcons.calendar, dateStr),
                  const SizedBox(height: DSSpacing.s1),
                  _InfoRow(LucideIcons.clock, job.timeDisplay),
                  const SizedBox(height: DSSpacing.s1),
                  _InfoRow(LucideIcons.mapPin, _locationDisplay(job.city, job.region)),
                  if (job.guestsAmount > 0) ...[
                    const SizedBox(height: DSSpacing.s1),
                    _InfoRow(LucideIcons.users, '${job.guestsAmount} gæster'),
                  ],
                  if (job.requestedMusicianHours != null) ...[
                    const SizedBox(height: DSSpacing.s1),
                    _InfoRow(LucideIcons.timer,
                        '${job.requestedMusicianHours!.toStringAsFixed(0)} timers musik ønsket'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.s6),

            DSInput(
              label: 'Din pris',
              hint: 'F.eks. 2500',
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffixText: 'kr.',
              validator: (v) {
                final price = int.tryParse(v ?? '') ?? 0;
                if (price <= 0) return 'Indtast en gyldig pris';
                return null;
              },
            ),
            const SizedBox(height: DSSpacing.s4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salgstale',
                  style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
                ),
                AgentAiButton(
                  job: widget.job,
                  isDj: false,
                  onDraftAccepted: (draft) {
                    setState(() {
                      _salesPitchController.text = draft;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s2),
            DSInput(
              hint: 'Fortæl kunden om din erfaring, hvorfor du er den rette til jobbet...',
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

            DSButton(
              label: 'Send tilbud',
              variant: DSButtonVariant.primary,
              expand: true,
              isLoading: isLoading,
              onTap: (isLoading || hasConflict) ? null : _handleSubmit,
            ),
            const SizedBox(height: DSSpacing.s8),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

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
