import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/equipment_description.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/edit_quote_bottom_sheet.dart'
    show kEditWindowMinutes, showEditQuoteBottomSheet;
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({super.key, required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  static const _c = lightColors;

  late DjQuote _quote;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
  }

  Future<void> _openEdit() async {
    final saved = await showEditQuoteBottomSheet(context, quote: _quote);
    if (!saved || !mounted) return;
    // Reflect the refreshed quote from the provider
    final updated = ref.read(djQuotesProvider).valueOrNull
        ?.where((q) => q.id == _quote.id)
        .firstOrNull;
    if (updated != null) setState(() => _quote = updated);
  }

  @override
  Widget build(BuildContext context) {
    final earlyAccepted = _quote.earlySetupStatus == 'accepted';
    final earlyPrice = earlyAccepted ? (_quote.earlySetupPrice ?? 0) : 0;
    final payout = ((_quote.priceDkk + earlyPrice) * 0.75).toInt();

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTypeLabel(_quote.job.eventType),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobIdBadge(id: _quote.job.id),
          ],
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: _quote.status == QuoteStatus.won
          ? _wonBody(payout)
          : _pendingBody(payout),
    );
  }

  Widget _sharedBidSections(int payout) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BidSummaryCard(quote: _quote, payout: payout),
          const SizedBox(height: DSSpacing.s4),
          _Section(
            title: 'Udstyr',
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: getEquipmentDisplayItems(_quote.equipmentDescription)
                    .map((item) => DSChip(label: item))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s4),
          _Section(
            title: 'Besked til kunden',
            children: [
              Text(_quote.salesPitch,
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.5)),
            ],
          ),
        ],
      );

  // ── Pending / lost / overwritten layout ───────────────────────────
  Widget _pendingBody(int payout) => ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          _JobHeroCard(quote: _quote),
          const SizedBox(height: DSSpacing.s3),
          if (_quote.status == QuoteStatus.pending) ...[
            _EditWindowBanner(quote: _quote, onEdit: _openEdit),
            const SizedBox(height: DSSpacing.s4),
          ],
          _sharedBidSections(payout),
          const SizedBox(height: DSSpacing.s4),
          _ServiceOffersSection(jobId: _quote.jobId),
          const SizedBox(height: DSSpacing.s8),
        ],
      );

  // ── Won layout: process first, job info last ───────────────────────
  Widget _wonBody(int payout) => ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          _WonSection(quote: _quote),
          const SizedBox(height: DSSpacing.s4),
          _ExtraHoursSection(quote: _quote),
          const SizedBox(height: DSSpacing.s4),
          _DjNotesSection(quote: _quote),
          const SizedBox(height: DSSpacing.s4),
          _ServiceOffersSection(jobId: _quote.jobId),
          const SizedBox(height: DSSpacing.s4),
          _sharedBidSections(payout),
          const SizedBox(height: DSSpacing.s4),
          _JobHeroCard(quote: _quote),
          const SizedBox(height: DSSpacing.s8),
        ],
      );
}

// ─── Job Hero Card ────────────────────────────────────────────────────────────

class _JobHeroCard extends StatelessWidget {
  const _JobHeroCard({required this.quote});

  final DjQuote quote;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final job = quote.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);

    final hasExtra = (job.genres != null && job.genres!.isNotEmpty)
        || (job.leadRequest != null && job.leadRequest!.isNotEmpty)
        || (job.additionalInformation != null && job.additionalInformation!.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: _c.border.subtle, width: 1),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + ID
          Row(
            children: [
              Expanded(
                child: Text(
                  eventTypeLabel(job.eventType),
                  style: DSTextStyle.headingMd.copyWith(color: _c.text.primary),
                ),
              ),
              const SizedBox(width: 8),
              JobIdBadge(id: job.id),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),

          // Meta rows
          _MetaRow(icon: LucideIcons.calendar, label: dateStr),
          const SizedBox(height: DSSpacing.s2),
          _MetaRow(icon: LucideIcons.clock, label: job.timeDisplay),
          const SizedBox(height: DSSpacing.s2),
          _MetaRow(icon: LucideIcons.mapPin, label: '${job.city}, ${job.region}'),
          if (job.guestsAmount > 0) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(icon: LucideIcons.users, label: '${job.guestsAmount} gæster'),
          ],
          if (job.budgetDisplay != 'Ikke angivet') ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(icon: LucideIcons.banknote, label: job.budgetDisplay),
          ],

          if (hasExtra) ...[
            const SizedBox(height: DSSpacing.s3),
            const Divider(height: 1),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Genres
          if (job.genres != null && job.genres!.isNotEmpty) ...[
            Text('Genrer', style: DSTextStyle.labelSm.copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.genres!.map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s2, vertical: 4),
                decoration: BoxDecoration(
                  color: _c.bg.inputBg,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                  border: Border.all(color: _c.border.subtle),
                ),
                child: Text(g, style: DSTextStyle.bodySm.copyWith(fontSize: 12, color: _c.text.secondary)),
              )).toList(),
            ),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Customer request
          if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
            Text('Kundens ønske', style: DSTextStyle.labelSm.copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s1),
            Text(job.leadRequest!, style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.5)),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Additional info
          if (job.additionalInformation != null && job.additionalInformation!.isNotEmpty) ...[
            Text('Yderligere information', style: DSTextStyle.labelSm.copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s1),
            Text(job.additionalInformation!, style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _c.text.muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label,
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary)),
        ),
      ],
    );
  }
}

// ─── Bid Summary Card ─────────────────────────────────────────────────────────

class _BidSummaryCard extends StatelessWidget {
  const _BidSummaryCard({required this.quote, required this.payout});

  final DjQuote quote;
  final int payout;

  static const _c = lightColors;

  static String _fmt(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.text.primary,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DSRadius.lg - 1)),
            ),
            child: Text(
              'Dit bud',
              style: DSTextStyle.labelLg.copyWith(
                color: _c.brand.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Price + payout row
          Padding(
            padding: const EdgeInsets.all(DSSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: _PriceKpi(
                    label: 'Samlet pris',
                    value: '${_fmt(quote.priceDkk)} kr.',
                    icon: LucideIcons.banknote,
                    highlight: false,
                  ),
                ),
                Container(width: 1, height: 48, color: _c.border.subtle),
                Expanded(
                  child: _PriceKpi(
                    label: 'Din udbetaling',
                    value: '${_fmt(payout)} kr.',
                    icon: LucideIcons.wallet,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),

          // Early setup row
          if (quote.earlySetupStatus != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, DSSpacing.s3),
              child: _EarlySetupRow(
                status: quote.earlySetupStatus!,
                price: quote.earlySetupPrice,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceKpi extends StatelessWidget {
  const _PriceKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.highlight,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight ? _c.brand.primaryActive : _c.text.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _c.text.muted),
              const SizedBox(width: 4),
              Text(label,
                  style: DSTextStyle.labelSm.copyWith(color: _c.text.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DSTextStyle.headingMd.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit window banner ───────────────────────────────────────────────────────

class _EditWindowBanner extends StatefulWidget {
  const _EditWindowBanner({required this.quote, required this.onEdit});

  final DjQuote quote;
  final VoidCallback onEdit;

  @override
  State<_EditWindowBanner> createState() => _EditWindowBannerState();
}

class _EditWindowBannerState extends State<_EditWindowBanner> {
  static const _c = lightColors;

  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _computeSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _computeSecondsLeft();
    });
  }

  void _computeSecondsLeft() {
    final deadline = widget.quote.createdAt
        .add(const Duration(minutes: kEditWindowMinutes));
    final diff = deadline.difference(DateTime.now()).inSeconds;
    setState(() => _secondsLeft = diff < 0 ? 0 : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _secondsLeft <= 0;
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');

    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: _c.text.muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(color: _c.border.subtle),
        ),
        child: Text(
          'Redigeringsvinduet på 10 minutter er udløbet',
          style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
        ),
      );
    }

    final isUrgent = _secondsLeft < 120;
    final bannerColor = isUrgent ? _c.state.warning : _c.state.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.timer, size: 16, color: bannerColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUrgent
                  ? 'Skynd dig! Du kan redigere dit tilbud i $m:$s'
                  : 'Du kan redigere dit tilbud i $m:$s',
              style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
            ),
          ),
          GestureDetector(
            onTap: widget.onEdit,
            child: Text(
              'Redigér',
              style: DSTextStyle.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                color: _c.brand.primaryActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Combined section shown when a DJ wins a quote: contact info and full
/// step-by-step process (contact → invoice → confirm ready → play event).
class _WonSection extends ConsumerStatefulWidget {
  const _WonSection({required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<_WonSection> createState() => _WonSectionState();
}

class _WonSectionState extends ConsumerState<_WonSection> {
  late DateTime? _djReadyConfirmedAt;

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    _djReadyConfirmedAt = widget.quote.djReadyConfirmedAt;
  }

  bool _isWithin5Days(DateTime eventDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final eventMidnight =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventMidnight.difference(todayMidnight).inDays <= 5;
  }

  Future<void> _handleMarkContacted(int jobId) async {
    final success = await ref
        .read(markJobContactedProvider.notifier)
        .markContacted(jobId);
    if (!mounted) return;
    if (success) {
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Kunden er markeret som kontaktet');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  Future<void> _handleReadyForBilling(int jobId, DjQuote quote) async {
    // If early setup was offered, ask about it first.
    if (quote.earlySetupStatus == 'offered' && mounted) {
      final result = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidlig opsætning'),
          content: const Text(
              'Valgte kunden tidlig opsætning?'),
          actions: [
            DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.pop(ctx)),
            DSButton(label: 'Nej', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.pop(ctx, false)),
            DSButton(label: 'Ja', variant: DSButtonVariant.tertiary, size: DSButtonSize.sm, onTap: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (result == null || !mounted) return;
      await ref
          .read(resolveEarlySetupProvider.notifier)
          .resolve(quote.id, accepted: result);
    } else if (mounted) {
      // Confirm before marking ready for billing.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Luk aftale og send faktura'),
          content: const Text(
              'Er kunden klar til at modtage en faktura? Kunden vil modtage en bekræftelse og en faktura på 50% af det aftalte beløb.'),
          actions: [
            DSButton(label: 'Annuller', variant: DSButtonVariant.ghost, size: DSButtonSize.sm, onTap: () => Navigator.pop(ctx, false)),
            DSButton(label: 'Luk aftale', variant: DSButtonVariant.tertiary, size: DSButtonSize.sm, onTap: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final success = await ref
        .read(markJobReadyForBillingProvider.notifier)
        .markReady(jobId);
    if (!mounted) return;
    if (success) {
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Aftale lukket — faktura sendt til kunden');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  Future<void> _handleConfirmReady(DjQuote quote) async {
    final success =
        await ref.read(confirmDjReadyProvider.notifier).confirm(quote.id);
    if (!mounted) return;
    if (success) {
      setState(() => _djReadyConfirmedAt = DateTime.now());
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Bekræftet! God fornøjelse med jobbet 🎵');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.quote.jobId));
    final contactLoading = ref.watch(markJobContactedProvider) is AsyncLoading;
    final billingLoading =
        ref.watch(markJobReadyForBillingProvider) is AsyncLoading;
    final readyLoading = ref.watch(confirmDjReadyProvider) is AsyncLoading;

    return jobAsync.when(
      loading: () => const _Section(
        title: 'Kundekontakt',
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(DSSpacing.s4),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
      error: (_, __) => _Section(
        title: 'Kundekontakt',
        children: [
          Text('Kunne ikke hente kontaktinfo',
              style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger)),
        ],
      ),
      data: (job) {
        final isContacted = job.status == JobStatus.customerContacted ||
            job.status == JobStatus.readyForBilling;
        final isReadyForBilling = job.status == JobStatus.readyForBilling;
        final isConfirmedReady = _djReadyConfirmedAt != null;
        final canConfirmReady = _isWithin5Days(job.date);

        int completedSteps = 0;
        if (isContacted) completedSteps = 1;
        if (isReadyForBilling) completedSteps = 2;
        if (isConfirmedReady) completedSteps = 3;

        return Column(
          children: [
            InvoiceStatusBadge(jobId: widget.quote.jobId),
            const SizedBox(height: DSSpacing.s4),

            // ── Contact info ───────────────────────────────────────
            _Section(
              title: 'Kundekontakt',
              children: [
                if (job.customerNote != null &&
                    job.customerNote!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _c.state.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info,
                            size: 16, color: _c.state.info),
                        const SizedBox(width: DSSpacing.s2),
                        Expanded(
                          child: Text(
                            job.customerNote!,
                            style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s3),
                ],
                if (job.leadName != null)
                  _ContactRow(icon: LucideIcons.user, label: job.leadName!),
                if (job.leadEmail != null) ...[
                  const SizedBox(height: DSSpacing.s2),
                  _ContactRow(
                    icon: LucideIcons.mail,
                    label: job.leadEmail!,
                    onCopy: () {
                      Clipboard.setData(
                          ClipboardData(text: job.leadEmail!));
                      DSToast.show(context,
                          variant: DSToastVariant.success,
                          title: 'Email kopieret');
                    },
                  ),
                ],
                if (job.leadPhoneNumber != null) ...[
                  const SizedBox(height: DSSpacing.s2),
                  _ContactRow(
                    icon: LucideIcons.phone,
                    label: job.leadPhoneNumber!,
                    onCopy: () {
                      Clipboard.setData(
                          ClipboardData(text: job.leadPhoneNumber!));
                      DSToast.show(context,
                          variant: DSToastVariant.success,
                          title: 'Telefon kopieret');
                    },
                  ),
                ],
                const SizedBox(height: DSSpacing.s4),

                // Step 1: Mark contacted
                if (isContacted)
                  _DoneButton(label: 'Kunden er kontaktet')
                else
                  DSButton(
                    label: 'Jeg har kontaktet kunden',
                    variant: DSButtonVariant.primary,
                    expand: true,
                    isLoading: contactLoading,
                    onTap: contactLoading ? null : () => _handleMarkContacted(widget.quote.jobId),
                  ),

                // Step 2: Mark ready for billing (shown after contacted)
                if (isContacted) ...[
                  const SizedBox(height: DSSpacing.s3),
                  if (isReadyForBilling)
                    _DoneButton(label: 'Faktura sendt')
                  else
                    DSButton(
                      label: 'Luk aftale og send faktura',
                      variant: DSButtonVariant.primary,
                      expand: true,
                      isLoading: billingLoading,
                      onTap: billingLoading ? null : () => _handleReadyForBilling(widget.quote.jobId, widget.quote),
                    ),
                ],

                // Step 3: Jeg er klar (shown after ready for billing)
                if (isReadyForBilling) ...[
                  const SizedBox(height: DSSpacing.s3),
                  if (isConfirmedReady)
                    _DoneButton(label: 'Jeg er klar!')
                  else ...[
                    if (!canConfirmReady) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(DSSpacing.s3),
                        decoration: BoxDecoration(
                          color: _c.bg.inputBg,
                          borderRadius: BorderRadius.circular(DSRadius.md),
                          border: Border.all(color: _c.border.subtle),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alarmClock, size: 16, color: _c.text.muted),
                            const SizedBox(width: DSSpacing.s2),
                            Expanded(
                              child: Text(
                                'Du kan bekræfte din deltagelse 5 dage før arrangementet',
                                style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      DSButton(
                        label: 'Jeg er klar!',
                        variant: DSButtonVariant.primary,
                        expand: true,
                        isLoading: readyLoading,
                        onTap: readyLoading ? null : () => _handleConfirmReady(widget.quote),
                      ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: DSSpacing.s4),

            // ── Process tracker ────────────────────────────────────
            _Section(
              title: 'Din proces',
              children: [
                ProcessTracker(
                  steps: const [
                    'Kontakt kunden',
                    'Send faktura',
                    'Bekræft klar',
                    'Spil jobbet',
                  ],
                  completedSteps: completedSteps,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});
  final String label;
  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: DSSpacing.s3, horizontal: DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.state.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle, size: 16, color: _c.state.success),
          const SizedBox(width: DSSpacing.s2),
          Text(
            '$label ✓',
            style: DSTextStyle.labelLg.copyWith(
              color: _c.state.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onCopy;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _c.text.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: DSTextStyle.labelLg.copyWith(color: _c.text.primary),
          ),
        ),
        if (onCopy != null)
          DSIconButton(icon: LucideIcons.copy, variant: DSIconButtonVariant.ghost, size: DSButtonSize.sm, onTap: onCopy),
      ],
    );
  }
}

class _EarlySetupRow extends StatelessWidget {
  const _EarlySetupRow({required this.status, this.price});

  final String status;
  final int? price;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == 'accepted';
    final isOffered = status == 'offered';

    final (icon, color, label) = switch (status) {
      'accepted' => (
          LucideIcons.checkCircle,
          _c.state.success,
          'Tidlig opsætning accepteret',
        ),
      'rejected' => (
          LucideIcons.xCircle,
          _c.state.danger,
          'Tidlig opsætning afvist af kunden',
        ),
      _ => (
          LucideIcons.calendarClock,
          _c.state.warning,
          'Tidlig opsætning tilbudt',
        ),
    };

    final priceLabel = (isAccepted || isOffered)
        ? (price != null && price! > 0 ? ' · $price kr.${isOffered ? " ekstra" : ""}' : ' · gratis')
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Text(
              '$label$priceLabel',
              style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DSTextStyle.headingSm.copyWith(
              fontSize: 15,
              color: _c.text.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          ...children,
        ],
      ),
    );
  }
}


// ─── Extra Hours Section ──────────────────────────────────────────────────────

class _ExtraHoursSection extends ConsumerStatefulWidget {
  const _ExtraHoursSection({required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<_ExtraHoursSection> createState() => _ExtraHoursSectionState();
}

class _ExtraHoursSectionState extends ConsumerState<_ExtraHoursSection> {
  static const _c = lightColors;

  final _hoursController = TextEditingController();
  final _priceController = TextEditingController();
  bool _editing = false;

  // Window: event date (00:00) through end of event date + 2 days (23:59:59)
  bool get _windowOpen {
    final eventDate = widget.quote.job.date;
    final windowStart = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final windowEnd = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day + 2,
      23,
      59,
      59,
    );
    final now = DateTime.now();
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  @override
  void initState() {
    super.initState();
    _prefillPrice();
  }

  void _prefillPrice() {
    if (widget.quote.extraHoursPricePerHour != null) {
      _priceController.text = widget.quote.extraHoursPricePerHour.toString();
    } else {
      final djProfile = ref.read(djProfileProvider).valueOrNull;
      if (djProfile != null && djProfile.pricePerExtraHour > 0) {
        _priceController.text = djProfile.pricePerExtraHour.toString();
      }
    }
    if (widget.quote.extraHours != null) {
      final hours = widget.quote.extraHours!;
      _hoursController.text = hours == hours.truncateToDouble()
          ? hours.toInt().toString()
          : hours.toString();
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hours = double.tryParse(_hoursController.text.replaceAll(',', '.'));
    final price = int.tryParse(_priceController.text);
    if (hours == null || hours <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angiv gyldigt timetal og pris')),
      );
      return;
    }
    final ok = await ref.read(addExtraHoursProvider.notifier).add(
          widget.quote.id,
          extraHours: hours,
          pricePerHour: price,
        );
    if (ok && mounted) setState(() => _editing = false);
  }

  Future<void> _delete() async {
    await ref.read(deleteExtraHoursProvider.notifier).delete(widget.quote.id);
    if (mounted) {
      setState(() {
        _editing = false;
        _hoursController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHours = widget.quote.extraHours != null;

    // Window closed + no hours → nothing to show
    if (!_windowOpen && !hasHours) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alarmPlus, size: 18, color: _c.brand.primaryActive),
              const SizedBox(width: DSSpacing.s2),
              Text(
                'Ekstra timer',
                style: DSTextStyle.headingSm.copyWith(
                  fontSize: 15,
                  color: _c.text.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),
          if (!_windowOpen && hasHours) ...[
            // Read-only summary
            _ExtraHoursSummary(
              hours: widget.quote.extraHours!,
              pricePerHour: widget.quote.extraHoursPricePerHour!,
            ),
          ] else if (_windowOpen && hasHours && !_editing) ...[
            // Summary + edit/delete actions
            _ExtraHoursSummary(
              hours: widget.quote.extraHours!,
              pricePerHour: widget.quote.extraHoursPricePerHour!,
            ),
            const SizedBox(height: DSSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: DSButton(
                    label: 'Rediger',
                    variant: DSButtonVariant.secondary,
                    onTap: () => setState(() => _editing = true),
                  ),
                ),
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: _DeleteButton(onTap: _delete),
                ),
              ],
            ),
          ] else if (_windowOpen && (!hasHours || _editing)) ...[
            // Input form
            DSInput(
              label: 'Antal timer',
              controller: _hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
            ),
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Pris pr. time (DKK)',
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: DSSpacing.s3),
            Consumer(
              builder: (context, ref, _) {
                final addState = ref.watch(addExtraHoursProvider);
                final isLoading = addState is AsyncLoading;
                return Row(
                  children: [
                    if (_editing) ...[
                      Expanded(
                        child: DSButton(
                          label: 'Annuller',
                          variant: DSButtonVariant.secondary,
                          onTap: () => setState(() => _editing = false),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.s2),
                    ],
                    Expanded(
                      child: DSButton(
                        label: isLoading ? 'Gemmer...' : 'Gem ekstra timer',
                        variant: DSButtonVariant.primary,
                        onTap: isLoading ? null : _save,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtraHoursSummary extends StatelessWidget {
  const _ExtraHoursSummary({
    required this.hours,
    required this.pricePerHour,
  });

  final double hours;
  final int pricePerHour;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final hoursLabel = hours == hours.truncateToDouble()
        ? '${hours.toInt()} timer'
        : '$hours timer';
    final total = (hours * pricePerHour).round();
    return Column(
      children: [
        _SummaryRow(
          label: 'Timer',
          value: hoursLabel,
        ),
        _SummaryRow(
          label: 'Pris pr. time',
          value: '$pricePerHour kr.',
        ),
        Divider(height: 16, color: _c.border.subtle),
        _SummaryRow(
          label: 'Tillæg i alt',
          value: '$total kr.',
          bold: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
          ),
          Text(
            value,
            style: DSTextStyle.labelMd.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: _c.text.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(deleteExtraHoursProvider);
    final isLoading = deleteState is AsyncLoading;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _c.state.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.state.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          isLoading ? 'Sletter...' : 'Slet',
          style: DSTextStyle.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: _c.state.danger,
          ),
        ),
      ),
    );
  }
}

// ─── Service Offers Section (musician offers on this job) ────────────────────

class _ServiceOffersSection extends ConsumerWidget {
  const _ServiceOffersSection({required this.jobId});
  final int? jobId;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobId == null) return const SizedBox.shrink();
    final offersAsync = ref.watch(serviceOffersForJobProvider(jobId!));

    return offersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: 0),
            _Section(
              title: 'Musikere på dette job',
              children: [
                for (final offer in offers) ...[
                  _MusicianOfferRow(offer: offer),
                  if (offer != offers.last)
                    Divider(height: DSSpacing.s4, color: _c.border.subtle),
                ],
              ],
            ),
            const SizedBox(height: DSSpacing.s4),
          ],
        );
      },
    );
  }
}

class _MusicianOfferRow extends ConsumerWidget {
  const _MusicianOfferRow({required this.offer});
  final ServiceOffer offer;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = ref.watch(userProfileImageProvider(offer.musicianId)).valueOrNull;
    final (statusLabel, statusColor) = switch (offer.status) {
      ServiceOfferStatus.sent => ('Tilbud afgivet', _c.state.warning),
      ServiceOfferStatus.won => ('Valgt musiker', _c.state.success),
      ServiceOfferStatus.lost => ('Tilbud afvist', _c.text.muted),
    };

    final instrumentLabel = offer.instrument.isNotEmpty
        ? offer.instrument[0].toUpperCase() + offer.instrument.substring(1)
        : 'Musiker';

    final isWon = offer.status == ServiceOfferStatus.won;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ProfileAvatar(
              imageUrl: imageUrl,
              fallbackIcon: LucideIcons.mic,
              tintColor: isWon ? _c.state.success : _c.text.muted,
              bgColor: isWon
                  ? _c.state.success.withValues(alpha: 0.12)
                  : _c.bg.inputBg,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.musicianFullName ?? instrumentLabel,
                    style: DSTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                  Text(
                    instrumentLabel,
                    style: DSTextStyle.labelSm.copyWith(color: _c.text.secondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DSRadius.pill),
              ),
              child: Text(
                statusLabel,
                style: DSTextStyle.labelSm.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Contact info — only shown when won
        if (isWon) ...[
          const SizedBox(height: DSSpacing.s3),
          Container(
            padding: const EdgeInsets.all(DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.state.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.state.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kontaktinformation',
                  style: DSTextStyle.labelSm.copyWith(
                    color: _c.text.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DSSpacing.s2),
                if (offer.musicianPhone != null)
                  _ContactLine(
                    icon: LucideIcons.phone,
                    value: offer.musicianPhone!,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: offer.musicianPhone!));
                      DSToast.show(context,
                          variant: DSToastVariant.success,
                          title: 'Telefon kopieret');
                    },
                  ),
                if (offer.musicianPhone != null && offer.musicianEmail != null)
                  const SizedBox(height: DSSpacing.s2),
                if (offer.musicianEmail != null)
                  _ContactLine(
                    icon: LucideIcons.mail,
                    value: offer.musicianEmail!,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: offer.musicianEmail!));
                      DSToast.show(context,
                          variant: DSToastVariant.success,
                          title: 'Email kopieret');
                    },
                  ),
                if (offer.musicianPhone == null && offer.musicianEmail == null)
                  Text(
                    'Ingen kontaktinfo tilgængelig',
                    style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value, required this.onCopy});
  final IconData icon;
  final String value;
  final VoidCallback onCopy;
  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _c.text.secondary),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            value,
            style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
          ),
        ),
        DSIconButton(
          icon: LucideIcons.copy,
          variant: DSIconButtonVariant.ghost,
          size: DSButtonSize.sm,
          onTap: onCopy,
        ),
      ],
    );
  }
}

// ─── DJ Notes Section ─────────────────────────────────────────────────────────

class _DjNotesSection extends ConsumerStatefulWidget {
  const _DjNotesSection({required this.quote});
  final DjQuote quote;

  @override
  ConsumerState<_DjNotesSection> createState() => _DjNotesSectionState();
}

class _DjNotesSectionState extends ConsumerState<_DjNotesSection> {
  static const _c = lightColors;

  late final TextEditingController _controller;
  bool _editing = false;
  bool _dirty = false;

  /// Tracks the last successfully persisted notes value locally so the UI
  /// stays correct without needing the parent to rebuild with a new quote prop.
  late String? _savedNotes;

  @override
  void initState() {
    super.initState();
    _savedNotes = widget.quote.djNotes;
    _controller = TextEditingController(text: _savedNotes ?? '');
    _controller.addListener(() {
      final changed = _controller.text != (_savedNotes ?? '');
      if (changed != _dirty) setState(() => _dirty = changed);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim();
    final ok = await ref
        .read(saveDjNotesProvider.notifier)
        .save(widget.quote.id, text);
    if (ok && mounted) {
      setState(() {
        _savedNotes = text;
        _editing = false;
        _dirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(saveDjNotesProvider) is AsyncLoading;
    final hasNotes = (_savedNotes ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, size: 18, color: _c.text.secondary),
              const SizedBox(width: DSSpacing.s2),
              Expanded(
                child: Text(
                  'Mine noter',
                  style: DSTextStyle.headingSm.copyWith(
                    fontSize: 15,
                    color: _c.text.primary,
                  ),
                ),
              ),
              if (!_editing)
                GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Text(
                    hasNotes ? 'Rediger' : 'Tilføj',
                    style: DSTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.brand.primaryActive,
                    ),
                  ),
                ),
            ],
          ),
          if (!_editing && !hasNotes) ...[
            const SizedBox(height: DSSpacing.s2),
            Text(
              'Ingen noter endnu. Tryk "Tilføj" for at skrive private noter om dette job.',
              style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
            ),
          ] else if (!_editing && hasNotes) ...[
            const SizedBox(height: DSSpacing.s3),
            Text(
              _savedNotes ?? '',
              style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary, height: 1.5),
            ),
          ] else ...[
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              controller: _controller,
              hint: 'Skriv dine private noter her...',
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: DSSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: DSButton(
                    label: 'Annuller',
                    variant: DSButtonVariant.secondary,
                    onTap: () {
                      _controller.text = _savedNotes ?? '';
                      setState(() { _editing = false; _dirty = false; });
                    },
                  ),
                ),
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: DSButton(
                    label: isSaving ? 'Gemmer...' : 'Gem noter',
                    variant: DSButtonVariant.primary,
                    onTap: (isSaving || !_dirty) ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Profile Avatar ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.tintColor,
    required this.bgColor,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color tintColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DSRadius.md),
      child: SizedBox(
        width: 36,
        height: 36,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: bgColor),
                errorWidget: (_, __, ___) => Container(
                  color: bgColor,
                  child: Icon(fallbackIcon, size: 18, color: tintColor),
                ),
              )
            : Container(
                color: bgColor,
                child: Icon(fallbackIcon, size: 18, color: tintColor),
              ),
      ),
    );
  }
}
