import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/sick_disclaimer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/chat_bubble_fab.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/contact_customer_sheet.dart';

String _fmt(num n) =>
    NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

class ServiceOfferDetailScreen extends ConsumerStatefulWidget {
  const ServiceOfferDetailScreen({super.key, required this.offer});

  final ServiceOffer offer;

  @override
  ConsumerState<ServiceOfferDetailScreen> createState() =>
      _ServiceOfferDetailScreenState();
}

class _ServiceOfferDetailScreenState
    extends ConsumerState<ServiceOfferDetailScreen> {
  DSColors get _c => DSTheme.of(context);
  late ServiceOffer _offer;
  late bool _customerContacted;
  late DateTime? _customerContactPlannedFor;
  late DateTime? _musicianReadyConfirmedAt;

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
    _customerContacted = widget.offer.customerContacted;
    _customerContactPlannedFor = widget.offer.customerContactPlannedFor;
    _musicianReadyConfirmedAt = widget.offer.musicianReadyConfirmedAt;
  }

  bool _isWithin5Days(DateTime eventDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final eventMidnight =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventMidnight.difference(todayMidnight).inDays <= 5;
  }

  Future<void> _handleConfirmReady() async {
    final success = await ref
        .read(confirmMusicianReadyProvider.notifier)
        .confirm(widget.offer.id);
    if (!mounted) return;
    if (success) {
      setState(() => _musicianReadyConfirmedAt = DateTime.now());
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Bekræftet! God fornøjelse med jobbet 🎵');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  Future<void> _openContactSheet() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ContactCustomerSheet(
          existingPlannedDate: _customerContactPlannedFor,
          onContacted: () async {
            final success = await ref
                .read(markServiceOfferContactedProvider.notifier)
                .markContacted(widget.offer.id);
            if (mounted && success) {
              setState(() {
                _customerContacted = true;
                _customerContactPlannedFor = null;
              });
              DSToast.show(context,
                  variant: DSToastVariant.success,
                  title: 'Kunden er markeret som kontaktet');
            } else if (mounted) {
              DSToast.show(context,
                  variant: DSToastVariant.error,
                  title: 'Noget gik galt. Prøv igen.');
            }
            return success;
          },
          onPlanned: (date) async {
            final success = await ref
                .read(setServiceOfferPlannedContactProvider.notifier)
                .setPlanned(widget.offer.id, date);
            if (mounted && success) {
              setState(() =>
                  _customerContactPlannedFor = DateTime.parse(date));
              DSToast.show(context,
                  variant: DSToastVariant.success,
                  title: 'Planlagt kontakt gemt');
            } else if (mounted) {
              DSToast.show(context,
                  variant: DSToastVariant.error,
                  title: 'Noget gik galt. Prøv igen.');
            }
            return success;
          },
        ),
      ),
    );
  }

  // ── Shared: bid summary + sales pitch ──────────────────────────────
  List<Widget> _sharedBidSections() => [
        _BidSummaryCard(offer: _offer),
        if (_offer.salesPitch != null &&
            _offer.salesPitch!.isNotEmpty) ...[
          const SizedBox(height: DSSpacing.s4),
          _Section(
            title: 'Besked til kunden',
            children: [
              Text(
                _offer.salesPitch!,
                style: DSTextStyle.bodyMd
                    .copyWith(color: _c.text.secondary, height: 1.5),
              ),
            ],
          ),
        ],
      ];

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    // Keep the local offer in sync with provider refreshes so a server-side
    // recompute (e.g. saving extra hours, which bumps price_dkk/payout) shows
    // immediately instead of only after reopening the screen.
    ref.listen(serviceOffersProvider, (_, next) {
      final updated =
          next.valueOrNull?.where((o) => o.id == widget.offer.id).firstOrNull;
      if (updated != null && mounted) setState(() => _offer = updated);
    });
    final offer = _offer;

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTypeLabel(offer.job.eventType),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobIdBadge(
                id: offer.jobId ?? offer.extJobId ?? 0,
                isExtJob: offer.isExtJob),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: switch (offer.status) {
        ServiceOfferStatus.sent => _sentBody(offer),
        ServiceOfferStatus.won => Stack(
            children: [
              _wonBody(offer),
              // Floating "Beskeder" bubble (mirrors the web app). Self-hides
              // when no conversation exists yet for this job.
              if (offer.jobId != null || offer.extJobId != null)
                Positioned.fill(
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(DSSpacing.s4),
                        child: ChatBubbleFab(
                          jobId: offer.jobId,
                          extJobId: offer.extJobId,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ServiceOfferStatus.lost => _lostBody(offer),
      },
    );
  }

  // ── Sent / pending ─────────────────────────────────────────────────
  Widget _sentBody(ServiceOffer offer) => ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          _TopStatusRow(offer: offer),
          const SizedBox(height: DSSpacing.s3),
          _JobHeroCard(offer: offer),
          const SizedBox(height: DSSpacing.s3),
          // ExtJobs don't have a customer-send step / response deadline —
          // skip the banner entirely for them.
          if (!offer.isExtJob) ...[
            _CustomerDeadlineBanner(offer: offer),
            const SizedBox(height: DSSpacing.s4),
          ],
          ..._sharedBidSections(),
          const SizedBox(height: DSSpacing.s8),
        ],
      );

  // ── Won ────────────────────────────────────────────────────────────
  Widget _wonBody(ServiceOffer offer) {
    final isConfirmedReady = _musicianReadyConfirmedAt != null;
    final canConfirmReady = _isWithin5Days(offer.job.date);
    final readyLoading = ref.watch(confirmMusicianReadyProvider) is AsyncLoading;

    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        _TopStatusRow(offer: offer),
        const SizedBox(height: DSSpacing.s4),

        // Non-binding call banner — shown until customer is contacted
        if (!_customerContacted) ...[
          _InfoBanner(
            title: 'Opkaldet er uforpligtende for kunden',
            body: offer.job.roleType == 'musician_only'
                ? 'Er alle detaljer på plads, sender du fakturaen med ét klik — jobbet er 100% bekræftet når kunden betaler første rate.'
                : 'Er alle detaljer på plads, sørger DJ\'en for fakturaen — jobbet er 100% bekræftet når kunden betaler første rate.',
          ),
          const SizedBox(height: DSSpacing.s4),
        ],

        // Customer contact
        _Section(
          title: 'Kundekontakt',
          children: [
            if (offer.job.leadName != null)
              _ContactRow(icon: LucideIcons.user, label: offer.job.leadName!),
            if (offer.job.leadEmail != null) ...[
              const SizedBox(height: DSSpacing.s2),
              _ContactRow(
                icon: LucideIcons.mail,
                label: offer.job.leadEmail!,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: offer.job.leadEmail!));
                  DSToast.show(context,
                      variant: DSToastVariant.success, title: 'Email kopieret');
                },
              ),
            ],
            if (offer.job.leadPhoneNumber != null) ...[
              const SizedBox(height: DSSpacing.s2),
              _ContactRow(
                icon: LucideIcons.phone,
                label: offer.job.leadPhoneNumber!,
                onCopy: () {
                  Clipboard.setData(
                      ClipboardData(text: offer.job.leadPhoneNumber!));
                  DSToast.show(context,
                      variant: DSToastVariant.success,
                      title: 'Telefon kopieret');
                },
              ),
            ],
            const SizedBox(height: DSSpacing.s4),
            if (_customerContacted)
              _DoneButton(label: 'Kunden er kontaktet')
            else ...[
              if (_customerContactPlannedFor != null)
                _PlannedContactBanner(date: _customerContactPlannedFor!),
              DSButton(
                label: _customerContactPlannedFor != null
                    ? 'Ændr kontaktdato'
                    : 'Kontakt kunden',
                variant: _customerContactPlannedFor != null
                    ? DSButtonVariant.secondary
                    : DSButtonVariant.primary,
                expand: true,
                onTap: _openContactSheet,
              ),
            ],
            if (_customerContacted) ...[
              const SizedBox(height: DSSpacing.s3),
              DSButton(
                label: isConfirmedReady
                    ? 'Jeg er klar! ✓'
                    : canConfirmReady
                        ? 'Jeg er klar!'
                        : 'Jeg er klar (tilgængelig 5 dage før)',
                variant: isConfirmedReady
                    ? DSButtonVariant.secondary
                    : DSButtonVariant.primary,
                expand: true,
                isLoading: readyLoading,
                enabled: isConfirmedReady || canConfirmReady,
                onTap: (isConfirmedReady || !canConfirmReady || readyLoading)
                    ? null
                    : _handleConfirmReady,
              ),
            ],
          ],
        ),
        const SizedBox(height: DSSpacing.s4),

        _Section(
          title: 'Din proces',
          children: [
            ProcessTracker(
              steps: const [
                'Kontakt kunden',
                'Bekræft klar',
                'Spil jobbet',
              ],
              completedSteps: isConfirmedReady
                  ? 2
                  : _customerContacted
                      ? 1
                      : 0,
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.s4),

        // DJ på jobbet — placed after the process tracker. Compact: name +
        // phone. Chat is reached via the floating bubble (see Scaffold body).
        if (offer.isExtJob && offer.job.assignedDjName != null) ...[
          _Section(
            title: 'DJ på jobbet',
            children: [
              _ContactRow(
                  icon: LucideIcons.user, label: offer.job.assignedDjName!),
            ],
          ),
          const SizedBox(height: DSSpacing.s4),
        ] else if (!offer.isExtJob && offer.jobId != null) ...[
          _WonDjSection(jobId: offer.jobId!),
          const SizedBox(height: DSSpacing.s4),
        ],

        const SickDisclaimer(role: 'musician'),
        const SizedBox(height: DSSpacing.s4),

        _MusicianExtraHoursSection(offer: offer),
        const SizedBox(height: DSSpacing.s4),

        if ((offer.job.musicianSpecialRequest?.isNotEmpty ?? false) ||
            offer.specialRequestExtraFeeDkk > 0) ...[
          _SpecialRequestFeeSection(offer: offer),
          const SizedBox(height: DSSpacing.s4),
        ],

        _MusicianNotesSection(offer: offer),
        const SizedBox(height: DSSpacing.s4),

        ..._sharedBidSections(),
        const SizedBox(height: DSSpacing.s4),

        _JobHeroCard(offer: offer),
        // Extra clearance so the floating chat bubble never covers the last card.
        const SizedBox(height: 96),
      ],
    );
  }

  // ── Lost ───────────────────────────────────────────────────────────
  Widget _lostBody(ServiceOffer offer) => ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          _TopStatusRow(offer: offer),
          const SizedBox(height: DSSpacing.s3),
          _LostBanner(),
          const SizedBox(height: DSSpacing.s4),
          ..._sharedBidSections(),
          const SizedBox(height: DSSpacing.s4),
          _JobHeroCard(offer: offer),
          const SizedBox(height: DSSpacing.s8),
        ],
      );
}

// ─── Job Hero Card ────────────────────────────────────────────────────────────

class _JobHeroCard extends StatelessWidget {
  const _JobHeroCard({required this.offer});

  final ServiceOffer offer;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final job = offer.job;
    final dateStr =
        DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);

    final hasExtra = (job.genres != null && job.genres!.isNotEmpty) ||
        (job.leadRequest != null && job.leadRequest!.isNotEmpty) ||
        (job.additionalInformation != null &&
            job.additionalInformation!.isNotEmpty) ||
        (job.customerNote != null && job.customerNote!.isNotEmpty);

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
                  style:
                      DSTextStyle.headingMd.copyWith(color: _c.text.primary),
                ),
              ),
              const SizedBox(width: 8),
              JobIdBadge(
                  id: offer.jobId ?? offer.extJobId ?? 0,
                  isExtJob: offer.isExtJob),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),

          // Meta rows
          _MetaRow(icon: LucideIcons.calendar, label: dateStr),
          const SizedBox(height: DSSpacing.s2),
          if (job.roleType == 'musician_only') ...[
            if (job.musicianStartTime != null) ...[
              _MetaRow(icon: LucideIcons.clock, label: 'Spillestart: ${job.musicianStartTime}'),
              const SizedBox(height: DSSpacing.s2),
            ],
          ] else ...[
            _MetaRow(
              icon: LucideIcons.clock,
              label: job.requestedSaxophonist || job.roleType == 'dj_and_musician'
                  ? 'DJ: ${job.timeDisplay}'
                  : job.timeDisplay,
            ),
            const SizedBox(height: DSSpacing.s2),
            if (job.musicianStartTime != null) ...[
              _MetaRow(icon: LucideIcons.music, label: 'Saxofonist: ${job.musicianStartTime}'),
              const SizedBox(height: DSSpacing.s2),
            ],
          ],
          _MetaRow(icon: LucideIcons.flag, label: job.region),
          if (job.city.isNotEmpty) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(icon: LucideIcons.mapPin, label: job.city),
          ],
          if (job.guestsAmount > 0) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(
                icon: LucideIcons.users,
                label: '${job.guestsAmount} gæster'),
          ],
          if (job.requestedMusicianHours != null &&
              job.requestedMusicianHours! > 0) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(
                icon: LucideIcons.timer,
                label:
                    '${job.requestedMusicianHours!.toStringAsFixed(0)} timers spilletid ønsket'),
          ],

          if (hasExtra) ...[
            const SizedBox(height: DSSpacing.s3),
            const Divider(height: 1),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Genres
          if (job.genres != null && job.genres!.isNotEmpty) ...[
            Text('Genrer',
                style: DSTextStyle.labelSm
                    .copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.genres!
                  .map((g) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.s2, vertical: 4),
                        decoration: BoxDecoration(
                          color: _c.bg.inputBg,
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                          border: Border.all(color: _c.border.subtle),
                        ),
                        child: Text(g,
                            style: DSTextStyle.bodySm.copyWith(
                                fontSize: 12, color: _c.text.secondary)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Customer request
          if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
            Text('Kundens ønske',
                style: DSTextStyle.labelSm
                    .copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s1),
            Text(job.leadRequest!,
                style: DSTextStyle.bodyMd
                    .copyWith(color: _c.text.secondary, height: 1.5)),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Additional info
          if (job.additionalInformation != null &&
              job.additionalInformation!.isNotEmpty) ...[
            Text('Yderligere information',
                style: DSTextStyle.labelSm
                    .copyWith(color: _c.text.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: DSSpacing.s1),
            Text(job.additionalInformation!,
                style: DSTextStyle.bodyMd
                    .copyWith(color: _c.text.secondary, height: 1.5)),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Customer note — strip B2B billing block before displaying
          if (job.customerNote != null && job.customerNote!.isNotEmpty) ...[
            Builder(builder: (context) {
              final note = job.customerNote!
                  .split('\n\nB2B-oplysninger:')
                  .first
                  .trim();
              if (note.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kundens note',
                      style: DSTextStyle.labelSm.copyWith(
                          color: _c.text.muted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: DSSpacing.s1),
                  Text(note,
                      style: DSTextStyle.bodyMd
                          .copyWith(color: _c.text.secondary, height: 1.5)),
                ],
              );
            }),
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
  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
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
  const _BidSummaryCard({required this.offer});

  final ServiceOffer offer;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final payout = offer.musicianPayoutDkk ?? offer.priceDkk;

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
          // Dark header — always dark regardless of theme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.brand.onPrimary,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DSRadius.lg - 1)),
            ),
            child: Text(
              'Dit tilbud',
              style: DSTextStyle.labelLg.copyWith(
                color: _c.brand.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Price KPIs
          Padding(
            padding: const EdgeInsets.all(DSSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: _PriceKpi(
                    label: 'Din udbetaling',
                    value: '${_fmt(payout)} kr.',
                    icon: LucideIcons.wallet,
                    highlight: true,
                  ),
                ),
                Container(width: 1, height: 48, color: _c.border.subtle),
                Expanded(
                  child: _PriceKpi(
                    label: 'Kundepris',
                    value: '${_fmt(offer.priceDkk)} kr.',
                    icon: LucideIcons.banknote,
                    highlight: false,
                  ),
                ),
              ],
            ),
          ),

          // Instrument row
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4, DSSpacing.s3, DSSpacing.s4, DSSpacing.s3),
            child: Row(
              children: [
                Icon(LucideIcons.music2, size: 14, color: _c.text.muted),
                const SizedBox(width: 6),
                Text(
                  offer.instrument,
                  style: DSTextStyle.labelMd
                      .copyWith(color: _c.text.secondary),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final valueColor =
        highlight ? _c.brand.primaryActive : _c.text.primary;
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

// ─── Customer Deadline Banner ─────────────────────────────────────────────────

class _CustomerDeadlineBanner extends StatelessWidget {
  const _CustomerDeadlineBanner({required this.offer});

  final ServiceOffer offer;

  DateTime? get _deadline => offer.job.customerDeadline;

  bool get _isExpired {
    final d = _deadline;
    return d != null && d.isBefore(DateTime.now());
  }

  bool get _isUrgent {
    final d = _deadline;
    return d != null &&
        !_isExpired &&
        d.difference(DateTime.now()).inHours < 24;
  }

  String _label() {
    final deadline = _deadline;
    if (deadline == null) return 'Tilbuddet er endnu ikke sendt til kunden';
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Fristen for kundens valg er udløbet';
    if (diff.inDays >= 2) return 'Kunden skal svare inden ${diff.inDays} dage';
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return 'Kunden skal svare inden ${h}t ${m}m';
    }
    return 'Kunden skal svare inden ${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final hasDeadline = _deadline != null;
    final color = _isExpired
        ? _c.state.danger
        : _isUrgent
            ? _c.state.warning
            : _c.text.secondary;
    final bg = _isExpired
        ? _c.state.danger.withValues(alpha: 0.15)
        : _isUrgent
            ? _c.state.warning.withValues(alpha: 0.18)
            : _c.bg.inputBg;
    final icon = !hasDeadline
        ? LucideIcons.send
        : _isExpired
            ? LucideIcons.timerOff
            : LucideIcons.hourglass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label(),
              style: DSTextStyle.labelMd.copyWith(
                  color: _c.text.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Status Row (primary status pill + invoice pill if won) ──────────────

class _TopStatusRow extends StatelessWidget {
  const _TopStatusRow({required this.offer});

  final ServiceOffer offer;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final (label, color) = switch (offer.status) {
      ServiceOfferStatus.sent => ('Sendt', c.state.warning),
      ServiceOfferStatus.won => ('Vundet', c.state.success),
      ServiceOfferStatus.lost => ('Udgået', c.text.muted),
    };
    return Wrap(
      spacing: DSSpacing.s2,
      runSpacing: DSSpacing.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DSStatusBadge(label: label, color: color),
        if (offer.status == ServiceOfferStatus.won)
          InvoiceStatusBadge(
            jobId: offer.isExtJob ? null : offer.jobId,
            extJobId: offer.isExtJob ? offer.extJobId : null,
            expand: false,
          ),
      ],
    );
  }
}

// ─── Lost Banner ──────────────────────────────────────────────────────────────

class _LostBanner extends StatelessWidget {
  const _LostBanner();

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.text.muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Udgået',
            style: DSTextStyle.headingSm
                .copyWith(color: _c.text.secondary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Kunden har valgt en anden musiker eller jobbet er blevet aflyst.',
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Row ─────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
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
          DSIconButton(
              icon: LucideIcons.copy,
              variant: DSIconButtonVariant.ghost,
              size: DSButtonSize.sm,
              onTap: onCopy),
      ],
    );
  }
}

// ─── Section ─────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
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

// ─── Won DJ Section (internal jobs, musician view) ───────────────────────────

class _WonDjSection extends ConsumerWidget {
  const _WonDjSection({required this.jobId});
  final int jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final _c = DSTheme.of(context);
    final djAsync = ref.watch(wonDjInfoForJobProvider(jobId));

    return djAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dj) {
        if (dj == null) return const SizedBox.shrink();
        final imageUrl =
            ref.watch(userProfileImageProvider(dj.djId)).valueOrNull;
        return _Section(
          title: 'DJ på jobbet',
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color:
                                  _c.brand.primary.withValues(alpha: 0.12),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color:
                                  _c.brand.primary.withValues(alpha: 0.12),
                              child: Icon(LucideIcons.user,
                                  size: 16,
                                  color: _c.brand.primaryActive),
                            ),
                          )
                        : Container(
                            color: _c.brand.primary.withValues(alpha: 0.12),
                            child: Icon(LucideIcons.user,
                                size: 16, color: _c.brand.primaryActive),
                          ),
                  ),
                ),
                const SizedBox(width: DSSpacing.s3),
                Expanded(
                  child: Text(
                    dj.fullName,
                    style: DSTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _c.text.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (dj.phone != null) ...[
              const SizedBox(height: DSSpacing.s3),
              _ContactRow(
                icon: LucideIcons.phone,
                label: dj.phone!,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: dj.phone!));
                  DSToast.show(context,
                      variant: DSToastVariant.success,
                      title: 'Telefon kopieret');
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Musician Extra Hours Section ─────────────────────────────────────────────

class _MusicianExtraHoursSection extends ConsumerStatefulWidget {
  const _MusicianExtraHoursSection({required this.offer});
  final ServiceOffer offer;

  @override
  ConsumerState<_MusicianExtraHoursSection> createState() =>
      _MusicianExtraHoursSectionState();
}

class _MusicianExtraHoursSectionState
    extends ConsumerState<_MusicianExtraHoursSection> {
  DSColors get _c => DSTheme.of(context);
  late final TextEditingController _hoursController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.offer.extraHours;
    _hoursController = TextEditingController(
      text: existing != null ? existing.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  bool _isWithinExtraHoursWindow(DateTime eventDate) {
    final todayMidnight = DateTime.now();
    final eventMidnight =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    // Show on event day and any day after — never before the event
    return !eventMidnight.isAfter(DateTime(todayMidnight.year, todayMidnight.month, todayMidnight.day));
  }

  Future<void> _save() async {
    final hours =
        double.tryParse(_hoursController.text.replaceAll(',', '.'));
    if (hours == null || hours <= 0) {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Indtast et gyldigt timeantal');
      return;
    }
    final ok = await ref
        .read(addMusicianExtraHoursProvider.notifier)
        .add(widget.offer.id, extraHours: hours);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      DSToast.show(context,
          variant: DSToastVariant.success, title: 'Ekstra timer gemt');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Kunne ikke gemme ekstra timer. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final job = widget.offer.job;
    final inWindow = _isWithinExtraHoursWindow(job.date);
    if (!inWindow) return const SizedBox.shrink();

    final isSaving =
        ref.watch(addMusicianExtraHoursProvider) is AsyncLoading;
    final hasHours = widget.offer.extraHours != null;

    return _Section(
      title: 'Ekstra timer',
      children: [
        Text(
          hasHours
              ? 'Du registrerede ${widget.offer.extraHours!.toStringAsFixed(1)} ekstra timer.'
              : 'Spillede du flere timer end aftalt? Registrér dem her.',
          style:
              DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
        ),
        if (inWindow) ...[
          if (_editing || !hasHours) ...[
            const SizedBox(height: DSSpacing.s3),
            DSInput(
              label: 'Ekstra timer',
              hint: 'F.eks. 1.5',
              controller: _hoursController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: DSSpacing.s3),
            DSButton(
              label: isSaving ? 'Gemmer...' : 'Gem ekstra timer',
              variant: DSButtonVariant.primary,
              expand: true,
              onTap: isSaving ? null : _save,
            ),
          ] else ...[
            const SizedBox(height: DSSpacing.s2),
            DSButton(
              label: 'Redigér',
              variant: DSButtonVariant.secondary,
              size: DSButtonSize.sm,
              onTap: () => setState(() => _editing = true),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Special Request Fee Section ─────────────────────────────────────────────

class _SpecialRequestFeeSection extends ConsumerStatefulWidget {
  const _SpecialRequestFeeSection({required this.offer});
  final ServiceOffer offer;

  @override
  ConsumerState<_SpecialRequestFeeSection> createState() =>
      _SpecialRequestFeeSectionState();
}

class _SpecialRequestFeeSectionState
    extends ConsumerState<_SpecialRequestFeeSection> {
  DSColors get _c => DSTheme.of(context);
  late final TextEditingController _feeController;
  late int _currentFee;
  late bool _isConfirmed;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _currentFee = widget.offer.specialRequestExtraFeeDkk;
    _isConfirmed = widget.offer.specialRequestExtraFeeConfirmed;
    _feeController = TextEditingController(
      text: _currentFee > 0 ? _currentFee.toString() : '',
    );
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fee = int.tryParse(_feeController.text.trim());
    if (fee == null || fee <= 0) {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Angiv et gyldigt beløb');
      return;
    }
    final ok = await ref
        .read(setSpecialRequestFeeProvider.notifier)
        .set(widget.offer.id, feeDkk: fee);
    if (ok && mounted) {
      setState(() {
        _currentFee = fee;
        _editing = false;
      });
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Tillæg registreret – vi bekræfter snart');
    }
  }

  Future<void> _remove() async {
    final ok = await ref
        .read(removeSpecialRequestFeeProvider.notifier)
        .remove(widget.offer.id);
    if (ok && mounted) {
      setState(() {
        _currentFee = 0;
        _editing = false;
        _feeController.clear();
      });
      DSToast.show(context,
          variant: DSToastVariant.success, title: 'Tillæg fjernet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(setSpecialRequestFeeProvider) is AsyncLoading;
    final isRemoving = ref.watch(removeSpecialRequestFeeProvider) is AsyncLoading;
    final musicianCut = (_currentFee * 0.8).round();

    // Confirmed
    if (_isConfirmed && _currentFee > 0) {
      return _Section(
        title: 'Særligt ønske – ekstra tillæg',
        children: [
          Container(
            padding: const EdgeInsets.all(DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.state.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.state.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 16, color: _c.state.success),
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tillæg bekræftet og lagt til prisen',
                          style: DSTextStyle.labelMd.copyWith(
                              color: _c.state.success,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '+${_fmt(_currentFee)} kr. (kunde) · +${_fmt(musicianCut)} kr. (dig)',
                          style: DSTextStyle.bodySm
                              .copyWith(color: _c.state.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Pending
    if (!_editing && _currentFee > 0) {
      return _Section(
        title: 'Særligt ønske – ekstra tillæg',
        children: [
          Container(
            padding: const EdgeInsets.all(DSSpacing.s3),
            decoration: BoxDecoration(
              color: _c.state.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border:
                  Border.all(color: _c.state.warning.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 15, color: _c.state.warning),
                    const SizedBox(width: DSSpacing.s2),
                    Text('Registreret – vi bekræfter snart',
                        style: DSTextStyle.labelMd.copyWith(
                            color: _c.text.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: DSSpacing.s1),
                Text(
                    '+${_fmt(_currentFee)} kr. ekstra til kunden · +${_fmt(musicianCut)} kr. til dig',
                    style:
                        DSTextStyle.bodySm.copyWith(color: _c.text.secondary)),
                Text('Beløbet lægges til prisen, når vi har set det.',
                    style: DSTextStyle.bodySm.copyWith(color: _c.text.muted)),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          Row(
            children: [
              Expanded(
                child: DSButton(
                  label: 'Rediger',
                  variant: DSButtonVariant.secondary,
                  size: DSButtonSize.sm,
                  onTap: () => setState(() => _editing = true),
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              DSButton(
                label: isRemoving ? '...' : 'Fjern',
                variant: DSButtonVariant.secondary,
                size: DSButtonSize.sm,
                onTap: isRemoving ? null : _remove,
              ),
            ],
          ),
        ],
      );
    }

    // Input
    return _Section(
      title: 'Særligt ønske – ekstra tillæg',
      children: [
        Text(
          'Har du og kunden aftalt et ekstra beløb? Registrer det her — vi ser det og lægger det til prisen. Du får 80%, vi tager 20%.',
          style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s3),
        DSInput(
          label: 'Aftalt ekstra beløb (kunden betaler)',
          hint: 'F.eks. 1500',
          controller: _feeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: DSSpacing.s3),
        Row(
          children: [
            Expanded(
              child: DSButton(
                label: isSaving ? 'Gemmer...' : 'Registrer ekstra tillæg',
                variant: DSButtonVariant.primary,
                expand: true,
                onTap: isSaving ? null : _save,
              ),
            ),
            if (_currentFee > 0) ...[
              const SizedBox(width: DSSpacing.s2),
              DSButton(
                label: 'Annuller',
                variant: DSButtonVariant.secondary,
                onTap: () => setState(() => _editing = false),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Musician Notes Section ───────────────────────────────────────────────────

class _MusicianNotesSection extends ConsumerStatefulWidget {
  const _MusicianNotesSection({required this.offer});
  final ServiceOffer offer;

  @override
  ConsumerState<_MusicianNotesSection> createState() =>
      _MusicianNotesSectionState();
}

class _MusicianNotesSectionState
    extends ConsumerState<_MusicianNotesSection> {
  DSColors get _c => DSTheme.of(context);
  late final TextEditingController _controller;
  bool _editing = false;
  bool _dirty = false;
  late String? _savedNotes;

  @override
  void initState() {
    super.initState();
    _savedNotes = widget.offer.musicianNotes;
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
        .read(saveMusicianNotesProvider.notifier)
        .save(widget.offer.id, text);
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
      final _c = DSTheme.of(context);
    final isSaving = ref.watch(saveMusicianNotesProvider) is AsyncLoading;
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
            'Ingen noter endnu. Tryk "Tilføj" for at skrive private noter.',
            style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
          ),
        ] else if (!_editing && hasNotes) ...[
          const SizedBox(height: DSSpacing.s3),
          Text(
            _savedNotes ?? '',
            style: DSTextStyle.bodyMd
                .copyWith(color: _c.text.primary, height: 1.5),
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
                    setState(() {
                      _editing = false;
                      _dirty = false;
                    });
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

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: DSSpacing.s3, horizontal: DSSpacing.s4),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.state.success.withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 18, color: _c.state.success),
          const SizedBox(width: DSSpacing.s2),
          Text(label,
              style: DSTextStyle.labelMd.copyWith(
                  color: _c.state.success,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PlannedContactBanner extends StatelessWidget {
  const _PlannedContactBanner({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final dateStr = DateFormat('d. MMMM yyyy', 'da_DK').format(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: DSSpacing.s2, horizontal: DSSpacing.s3),
        decoration: BoxDecoration(
          color: _c.state.warning.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border:
              Border.all(color: _c.state.warning.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: _c.state.warning),
            const SizedBox(width: DSSpacing.s2),
            Text('Husk at kontakte d. $dateStr',
                style: DSTextStyle.bodySm.copyWith(
                    color: _c.text.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Info Banner ─────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.state.info.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _c.state.info.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: _c.state.info),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: DSTextStyle.labelSm.copyWith(
                        color: _c.text.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: DSSpacing.s1),
                Text(body,
                    style: DSTextStyle.bodySm
                        .copyWith(color: _c.text.secondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
