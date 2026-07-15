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
import 'package:dj_tilbud_app/features/jobs/presentation/utils/extra_hours_options.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/hours_picker_field.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/song_requests_screen.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/edit_quote_bottom_sheet.dart'
    show kEditWindowMinutes, showEditQuoteBottomSheet;
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_content_section.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/sick_disclaimer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/copy_intro_message_card.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/core/utils/budget_utils.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/conversation_card.dart';
import 'package:dj_tilbud_app/shared/widgets/chat_bubble_fab.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/contact_customer_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/event_address_section.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({super.key, required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  DSColors get _c => DSTheme.of(context);
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
    final updated =
        ref
            .read(djQuotesProvider)
            .valueOrNull
            ?.where((q) => q.id == _quote.id)
            .firstOrNull;
    if (updated != null) setState(() => _quote = updated);
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    // Keep the local quote in sync with provider refreshes. Sections render from
    // `_quote`, so without this a server-side recompute (e.g. saving extra hours,
    // which bumps price_dkk/payout) wouldn't show until the screen was reopened.
    ref.listen(djQuotesProvider, (_, next) {
      final updated =
          next.valueOrNull?.where((q) => q.id == widget.quote.id).firstOrNull;
      if (updated != null && mounted) setState(() => _quote = updated);
    });
    // Mirrors web app QuoteInfo exactly: dj_payout_override ?? round(price_dkk * (1 - fee)).
    // Never derive a different number — the DJ must see what the web app shows.
    final payout = _quote.djPayout;

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
      body:
          _quote.status == QuoteStatus.won
              ? Stack(
                children: [
                  _wonBody(payout),
                  // Floating "Beskeder" bubble (mirrors the web app + the
                  // musician won-offer view). Self-hides when no conversation
                  // exists yet for this job.
                  Positioned.fill(
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(DSSpacing.s4),
                          child: ChatBubbleFab(jobId: _quote.jobId),
                        ),
                      ),
                    ),
                  ),
                ],
              )
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
            children:
                getEquipmentDisplayItems(
                  _quote.equipmentDescription,
                ).map((item) => DSChip(label: item)).toList(),
          ),
        ],
      ),
      const SizedBox(height: DSSpacing.s4),
      _Section(
        title: 'Besked til kunden',
        children: [
          Text(
            _quote.salesPitch,
            style: DSTextStyle.bodyMd.copyWith(
              color: _c.text.secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ],
  );

  // ── Pending / lost / overwritten layout ───────────────────────────
  Widget _pendingBody(int payout) => ListView(
    padding: const EdgeInsets.all(DSSpacing.s4),
    children: [
      _TopStatusRow(quote: _quote),
      const SizedBox(height: DSSpacing.s3),
      _JobHeroCard(quote: _quote),
      const SizedBox(height: DSSpacing.s3),
      if (_quote.status == QuoteStatus.pending) ...[
        _EditWindowBanner(quote: _quote, onEdit: _openEdit),
        const SizedBox(height: DSSpacing.s2),
        _CustomerDeadlineBanner(quote: _quote),
        const SizedBox(height: DSSpacing.s4),
      ],
      _sharedBidSections(payout),
      const SizedBox(height: DSSpacing.s8),
    ],
  );

  // ── Won layout: process first, job info last ───────────────────────
  Widget _wonBody(int payout) => ListView(
    padding: const EdgeInsets.all(DSSpacing.s4),
    children: [
      _TopStatusRow(quote: _quote),
      const SizedBox(height: DSSpacing.s3),
      _WonSection(quote: _quote),
      EventAddressSection(jobId: _quote.jobId),
      const SizedBox(height: DSSpacing.s4),
      _SongRequestsRow(quote: _quote),
      const SizedBox(height: DSSpacing.s4),
      _ExtraHoursSection(quote: _quote),
      const SizedBox(height: DSSpacing.s4),
      if (_quote.earlySetupStatus != null) ...[
        _EarlySetupRow(
          status: _quote.earlySetupStatus!,
          price: _quote.earlySetupPrice,
        ),
        const SizedBox(height: DSSpacing.s4),
      ],
      _DjNotesSection(quote: _quote),
      const SizedBox(height: DSSpacing.s4),
      _ServiceOffersSection(jobId: _quote.jobId),
      const SizedBox(height: DSSpacing.s4),
      _sharedBidSections(payout),
      const SizedBox(height: DSSpacing.s4),
      _JobHeroCard(quote: _quote),
      // Extra clearance so the floating chat bubble never covers the last card.
      const SizedBox(height: 96),
    ],
  );
}

// ─── Top Status Row (primary status pill + invoice pill if won) ──────────────

class _TopStatusRow extends StatelessWidget {
  const _TopStatusRow({required this.quote});

  final DjQuote quote;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final (label, color) = switch (quote.status) {
      QuoteStatus.pending => ('Bud givet', c.state.warning),
      QuoteStatus.won => ('Vundet', c.state.success),
      QuoteStatus.overwritten => ('Overskrevet', c.text.muted),
      QuoteStatus.lost => ('Udgået', c.state.danger),
    };
    return Wrap(
      spacing: DSSpacing.s2,
      runSpacing: DSSpacing.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DSStatusBadge(label: label, color: color),
        if (quote.status == QuoteStatus.won)
          InvoiceStatusBadge(jobId: quote.jobId, expand: false),
      ],
    );
  }
}

// ─── Job Hero Card ────────────────────────────────────────────────────────────

class _JobHeroCard extends ConsumerWidget {
  const _JobHeroCard({required this.quote});

  final DjQuote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final job = quote.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    // The DJ-facing budget is tier- and sax-adjusted. The web-app renders this
    // card's equivalent (dj/jobs/[id]/_components/JobInfo) on the won-quote page
    // too, so the won view must show the SAME adjusted figure as the bidding
    // view — never the raw customer budget.
    final djTier = ref.watch(djProfileProvider).valueOrNull?.tier;
    final budgetLabel = djAdjustedBudgetLabel(job, djTier);

    final hasExtra =
        (job.genres != null && job.genres!.isNotEmpty) ||
        (job.leadRequest != null && job.leadRequest!.isNotEmpty) ||
        (job.additionalInformation != null &&
            job.additionalInformation!.isNotEmpty);

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
          _MetaRow(icon: LucideIcons.flag, label: job.region),
          if (job.placeLabel.isNotEmpty) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(icon: LucideIcons.mapPin, label: job.placeLabel),
          ],
          if (job.guestsAmount > 0) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(
              icon: LucideIcons.users,
              label: '${job.guestsAmount} gæster',
            ),
          ],
          if (budgetLabel != null) ...[
            const SizedBox(height: DSSpacing.s2),
            _MetaRow(icon: LucideIcons.banknote, label: budgetLabel),
          ],

          if (hasExtra) ...[
            const SizedBox(height: DSSpacing.s3),
            const Divider(height: 1),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Genres
          if (job.genres != null && job.genres!.isNotEmpty) ...[
            Text(
              'Genrer',
              style: DSTextStyle.labelSm.copyWith(
                color: _c.text.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DSSpacing.s2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  job.genres!
                      .map(
                        (g) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DSSpacing.s2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _c.bg.inputBg,
                            borderRadius: BorderRadius.circular(DSRadius.pill),
                            border: Border.all(color: _c.border.subtle),
                          ),
                          child: Text(
                            g,
                            style: DSTextStyle.bodySm.copyWith(
                              fontSize: 12,
                              color: _c.text.secondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Customer request
          if (job.leadRequest != null && job.leadRequest!.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Kundens ønske',
                  style: DSTextStyle.labelSm.copyWith(
                    color: _c.text.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: job.leadRequest!));
                    DSToast.show(
                      context,
                      variant: DSToastVariant.success,
                      title: 'Kundens ønske kopieret',
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.copy, size: 13, color: _c.text.muted),
                      const SizedBox(width: DSSpacing.s1),
                      Text(
                        'Kopier',
                        style: DSTextStyle.labelSm.copyWith(
                          color: _c.text.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s1),
            Text(
              job.leadRequest!,
              style: DSTextStyle.bodyMd.copyWith(
                color: _c.text.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: DSSpacing.s3),
          ],

          // Additional info
          if (job.additionalInformation != null &&
              job.additionalInformation!.isNotEmpty) ...[
            Text(
              'Yderligere information',
              style: DSTextStyle.labelSm.copyWith(
                color: _c.text.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DSSpacing.s1),
            Text(
              job.additionalInformation!,
              style: DSTextStyle.bodyMd.copyWith(
                color: _c.text.secondary,
                height: 1.5,
              ),
            ),
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
          child: Text(
            label,
            style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
          ),
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

  static String _fmt(int n) =>
      NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

  // 2-decimal Danish format ("1.687,50"). Formatted in en_US (always available)
  // then separators swapped, so it's correct regardless of locale-data loading.
  static String _fmt2(num n) => NumberFormat(
    '#,##0.00',
    'en_US',
  ).format(n).replaceAll(',', '#').replaceAll('.', ',').replaceAll('#', '.');

  // Extra-hours count à la da-DK: whole → "1", fractional → "0,5" / "1,5".
  static String _fmtHours(double h) =>
      h == h.truncateToDouble()
          ? h.toInt().toString()
          : h.toString().replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    Widget label(String t) => Text(
      t,
      style: DSTextStyle.labelSm.copyWith(
        color: _c.text.muted,
        fontWeight: FontWeight.w600,
      ),
    );
    Widget bigValue(String t, {required bool highlight}) => Text(
      t,
      style: DSTextStyle.headingMd.copyWith(
        color: highlight ? _c.brand.primaryActive : _c.text.primary,
        fontWeight: FontWeight.w800,
      ),
    );
    Widget muted(String t) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        t,
        style: DSTextStyle.labelSm.copyWith(color: _c.text.secondary),
      ),
    );
    // "label .......... 1.234 kr." breakdown row. dim = de-emphasised secondary
    // color; indent = sub-item nudged right (composes the total above it).
    Widget row(String l, num v, {bool dim = false, bool indent = false}) =>
        Padding(
          padding: EdgeInsets.only(bottom: 4, left: indent ? DSSpacing.s4 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l,
                  style: DSTextStyle.labelSm.copyWith(
                    color: dim ? _c.text.secondary : _c.text.primary,
                  ),
                ),
              ),
              const SizedBox(width: DSSpacing.s3),
              Text(
                '${_fmt2(v)} kr.',
                style: DSTextStyle.labelSm.copyWith(
                  color: dim ? _c.text.secondary : _c.text.primary,
                ),
              ),
            ],
          ),
        );

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
              horizontal: DSSpacing.s4,
              vertical: DSSpacing.s3,
            ),
            decoration: BoxDecoration(
              color: _c.text.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DSRadius.lg - 1),
              ),
            ),
            child: Text(
              'Dit bud',
              style: DSTextStyle.labelLg.copyWith(
                color: _c.brand.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(DSSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRIVACY: when an admin has overridden the payout, the DJ must
                // never see the customer price or the commission — only the final
                // payout. The full "customer total - kommission = lønudbetaling"
                // breakdown is rendered ONLY when there is no override.
                if (quote.hasPayoutOverride) ...[
                  // Explain HOW the payout is built up, but only from the DJ's
                  // own numbers — base honorar + the DJ's share of each add-on.
                  // Never the customer price or the commission.
                  if (quote.overrideHasAddons) ...[
                    label('Din lønberegning'),
                    const SizedBox(height: DSSpacing.s2),
                    row('Grundhonorar', quote.overrideBasePayout, dim: true),
                    if (quote.overrideExtraHoursAddon > 0)
                      row(
                        '+ Ekstra timer',
                        quote.overrideExtraHoursAddon,
                        dim: true,
                      ),
                    if (quote.overrideEarlySetupAddon > 0)
                      row(
                        '+ Tidlig opsætning',
                        quote.overrideEarlySetupAddon,
                        dim: true,
                      ),
                    const SizedBox(height: 2),
                    Divider(height: 1, color: _c.border.subtle),
                    const SizedBox(height: DSSpacing.s3),
                  ],
                  label('Din lønudbetaling'),
                  const SizedBox(height: 2),
                  bigValue('${_fmt2(payout)} kr.', highlight: true),
                  const SizedBox(height: 2),
                  muted('Dit honorar er aftalt direkte med DJTILBUD.'),
                ] else ...[
                  // Order: customer total first, then what it's made of, then the
                  // commission, then the DJ payout as the single emphasised focal
                  // point. Customer total is normal weight, NOT bold.
                  label('Samlet pris til kunde'),
                  const SizedBox(height: DSSpacing.s2),
                  row('Total pris til kunde', quote.priceDkk),
                  row(
                    'Basispris',
                    quote.originalOffer,
                    dim: true,
                    indent: true,
                  ),
                  if (quote.hasExtraHours)
                    row(
                      '+ Ekstra timer (${_fmtHours(quote.extraHours!)} '
                      '${quote.extraHours == 1 ? 'time' : 'timer'} á '
                      '${_fmt(quote.extraHoursPricePerHour!.round())} kr)',
                      quote.extraHoursTotal,
                      dim: true,
                      indent: true,
                    ),
                  if (quote.isEarlySetupAccepted &&
                      (quote.earlySetupPrice ?? 0) > 0)
                    row(
                      '+ Tidlig opsætning',
                      quote.earlySetupPrice!,
                      dim: true,
                      indent: true,
                    ),
                  const SizedBox(height: 2),
                  Divider(height: 1, color: _c.border.subtle),
                  const SizedBox(height: DSSpacing.s2),
                  row(
                    '- DJTILBUD kommission (${quote.feePercent}%)',
                    quote.commissionExact,
                    dim: true,
                  ),
                  const SizedBox(height: 2),
                  Divider(height: 1, color: _c.border.subtle),
                  const SizedBox(height: DSSpacing.s3),
                  // The DJ payout — the focal point.
                  label('Din lønudbetaling'),
                  const SizedBox(height: 2),
                  bigValue(
                    '${_fmt2(quote.djPayoutExact)} kr.',
                    highlight: true,
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

// ─── Customer deadline banner ─────────────────────────────────────────────────

class _CustomerDeadlineBanner extends StatelessWidget {
  const _CustomerDeadlineBanner({required this.quote});

  final DjQuote quote;

  DateTime? get _deadline => quote.job.customerDeadline;

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
    final color =
        _isExpired
            ? _c.state.danger
            : _isUrgent
            ? _c.state.warning
            : _c.text.secondary;
    final bg =
        _isExpired
            ? _c.state.danger.withValues(alpha: 0.15)
            : _isUrgent
            ? _c.state.warning.withValues(alpha: 0.20)
            : _c.bg.inputBg;
    final icon =
        !hasDeadline
            ? LucideIcons.send
            : _isExpired
            ? LucideIcons.timerOff
            : LucideIcons.hourglass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s2,
      ),
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
                color: _c.text.primary,
                fontWeight: FontWeight.w600,
              ),
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
  DSColors get _c => DSTheme.of(context);
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
    final deadline = widget.quote.createdAt.add(
      const Duration(minutes: kEditWindowMinutes),
    );
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
    final _c = DSTheme.of(context);
    final isExpired = _secondsLeft <= 0;
    final mLeft = (_secondsLeft / 60).ceil();

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
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: bannerColor.withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.timer, size: 16, color: bannerColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUrgent
                  ? 'Skynd dig! Du kan redigere dit tilbud i $mLeft min'
                  : 'Du kan redigere dit tilbud i $mLeft min',
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
  DSColors get _c => DSTheme.of(context);
  bool _contactedOptimistically = false;

  bool _isWithin5Days(DateTime eventDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final eventMidnight = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );
    return eventMidnight.difference(todayMidnight).inDays <= 5;
  }

  Future<void> _openContactSheet(int jobId, DateTime? plannedDate) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ContactCustomerSheet(
              existingPlannedDate: plannedDate,
              onContacted: () async {
                final success = await ref
                    .read(markJobContactedProvider.notifier)
                    .markContacted(jobId);
                if (mounted && success) {
                  AnalyticsService.logCustomerContacted(jobId, role: 'dj');
                  DSToast.show(
                    context,
                    variant: DSToastVariant.success,
                    title: 'Kunden er markeret som kontaktet',
                  );
                } else if (mounted) {
                  DSToast.show(
                    context,
                    variant: DSToastVariant.error,
                    title: 'Noget gik galt. Prøv igen.',
                  );
                }
                return success;
              },
              onPlanned: (date) async {
                final success = await ref
                    .read(setJobPlannedContactProvider.notifier)
                    .setPlanned(jobId, date);
                if (mounted && success) {
                  AnalyticsService.logCustomerContacted(
                    jobId,
                    role: 'dj',
                    planned: true,
                  );
                  DSToast.show(
                    context,
                    variant: DSToastVariant.success,
                    title: 'Planlagt kontakt gemt',
                  );
                } else if (mounted) {
                  DSToast.show(
                    context,
                    variant: DSToastVariant.error,
                    title: 'Noget gik galt. Prøv igen.',
                  );
                }
                return success;
              },
            ),
          ),
    );
    if (result == true && mounted) {
      setState(() => _contactedOptimistically = true);
    }
  }

  /// Body for the "Valgte kunden tidlig opsætning?" dialog: a clean summary of
  /// the offered fee and the resulting price to the customer, so the DJ sees
  /// exactly what tapping "Ja" does (the fee is added server-side).
  Widget _earlySetupChoiceContent(DjQuote quote) {
    final price = quote.earlySetupPrice ?? 0;
    final hasPrice = price > 0;
    String fmt(int n) =>
        NumberFormat('#,###', 'da_DK').format(n).replaceAll(',', '.');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bekræft kundens valg, så fakturaen bliver korrekt.',
          style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s4),
        Container(
          padding: const EdgeInsets.all(DSSpacing.s3),
          decoration: BoxDecoration(
            color: _c.bg.surface,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: _c.border.subtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _c.brand.accentSoft,
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                    ),
                    child: Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: _c.brand.accent,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tidlig opsætning',
                          style: DSTextStyle.labelMd.copyWith(
                            color: _c.text.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPrice
                              ? 'Du tilbød dette for ${fmt(price)} kr.'
                              : 'Du tilbød dette gratis.',
                          style: DSTextStyle.bodySm.copyWith(
                            color: _c.text.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasPrice) ...[
                const SizedBox(height: DSSpacing.s3),
                Divider(height: 1, color: _c.border.subtle),
                const SizedBox(height: DSSpacing.s3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ny pris til kunde hvis "Ja"',
                      style: DSTextStyle.bodySm.copyWith(
                        color: _c.text.secondary,
                      ),
                    ),
                    Text(
                      '${fmt(quote.priceDkk + price)} kr.',
                      style: DSTextStyle.labelMd.copyWith(
                        color: _c.text.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleReadyForBilling(int jobId, DjQuote quote) async {
    // If early setup was offered, ask about it first.
    if (quote.earlySetupStatus == 'offered' && mounted) {
      final result = await showDSDialog<bool?>(
        context,
        title: 'Valgte kunden tidlig opsætning?',
        content: _earlySetupChoiceContent(quote),
        actions:
            (ctx) => [
              DSButton(
                label: 'Nej',
                variant: DSButtonVariant.ghost,
                size: DSButtonSize.sm,
                onTap: () => Navigator.pop(ctx, false),
              ),
              DSButton(
                label: 'Ja',
                variant: DSButtonVariant.primary,
                size: DSButtonSize.sm,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
      );
      if (result == null || !mounted) return;
      await ref
          .read(resolveEarlySetupProvider.notifier)
          .resolve(quote.id, accepted: result);
    } else if (mounted) {
      // Confirm before marking ready for billing.
      final confirmed = await showDSConfirm(
        context,
        title: 'Luk aftale og send faktura',
        message:
            'Er kunden klar til at modtage en faktura? Kunden vil modtage en bekræftelse og en faktura på 50% af det aftalte beløb.',
        confirmLabel: 'Luk aftale',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }

    final success = await ref
        .read(markJobReadyForBillingProvider.notifier)
        .markReady(jobId);
    if (!mounted) return;
    if (success) {
      AnalyticsService.logReadyForBilling(jobId, role: 'dj');
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Aftale lukket — faktura sendt til kunden',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Noget gik galt. Prøv igen.',
      );
    }
  }

  Future<void> _handleConfirmReady(DjQuote quote) async {
    final success = await ref
        .read(confirmDjReadyProvider.notifier)
        .confirm(quote.id);
    if (!mounted) return;
    if (success) {
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Bekræftet! God fornøjelse med jobbet 🎵',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Noget gik galt. Prøv igen.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final jobAsync = ref.watch(jobDetailProvider(widget.quote.jobId));
    // Source of truth for ready-confirmed state lives in the Quotes row.
    // Watching djQuotesProvider keeps the UI correct across rebuilds (e.g.
    // when this widget is re-elemented after scrolling) — local state would
    // reset to the stale `widget.quote` value in initState.
    final latestQuote =
        ref
            .watch(djQuotesProvider)
            .valueOrNull
            ?.firstWhere(
              (q) => q.id == widget.quote.id,
              orElse: () => widget.quote,
            ) ??
        widget.quote;
    final billingLoading =
        ref.watch(markJobReadyForBillingProvider) is AsyncLoading;
    final readyLoading = ref.watch(confirmDjReadyProvider) is AsyncLoading;
    // The DJ's own name for the copyable intro message (falls back to full name).
    final djProfile = ref.watch(djProfileProvider).valueOrNull;
    final djName = djProfile?.companyOrDjName ?? djProfile?.fullName ?? '';

    return jobAsync.when(
      loading:
          () => const _Section(
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
      error:
          (_, __) => _Section(
            title: 'Kundekontakt',
            children: [
              Text(
                'Kunne ikke hente kontaktinfo',
                style: DSTextStyle.bodyMd.copyWith(color: _c.state.danger),
              ),
            ],
          ),
      data: (job) {
        final isContacted =
            _contactedOptimistically ||
            job.status == JobStatus.customerContacted ||
            job.status == JobStatus.readyForBilling;
        final isReadyForBilling = job.status == JobStatus.readyForBilling;
        final isConfirmedReady = latestQuote.djReadyConfirmedAt != null;
        final canConfirmReady = _isWithin5Days(job.date);

        int completedSteps = 0;
        if (isContacted) completedSteps = 1;
        if (isReadyForBilling) completedSteps = 2;
        if (isConfirmedReady) completedSteps = 3;

        return Column(
          children: [
            // ── Contact info ───────────────────────────────────────
            _Section(
              title: 'Kundekontakt',
              children: [
                if (job.customerNote != null &&
                    job.customerNote!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _c.state.info.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, size: 16, color: _c.state.info),
                        const SizedBox(width: DSSpacing.s2),
                        Expanded(
                          child: Text(
                            job.customerNote!,
                            style: DSTextStyle.labelMd.copyWith(
                              color: _c.text.secondary,
                            ),
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
                      Clipboard.setData(ClipboardData(text: job.leadEmail!));
                      DSToast.show(
                        context,
                        variant: DSToastVariant.success,
                        title: 'Email kopieret',
                      );
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
                        ClipboardData(text: job.leadPhoneNumber!),
                      );
                      DSToast.show(
                        context,
                        variant: DSToastVariant.success,
                        title: 'Telefon kopieret',
                      );
                    },
                  ),
                ],
                const SizedBox(height: DSSpacing.s4),

                // Step 1: Mark contacted (or set planned date)
                if (isContacted)
                  _DoneButton(label: 'Kunden er kontaktet')
                else ...[
                  if (job.leadName != null) ...[
                    CopyIntroMessageCard(
                      leadName: job.leadName!,
                      role: 'DJ',
                      performerName: djName,
                      phoneNumber: job.leadPhoneNumber,
                    ),
                    const SizedBox(height: DSSpacing.s3),
                  ],
                  if (job.customerContactPlannedFor != null)
                    _PlannedContactBanner(date: job.customerContactPlannedFor!),
                  DSButton(
                    label:
                        job.customerContactPlannedFor != null
                            ? 'Ændr kontaktdato'
                            : 'Kunde kontaktet',
                    variant:
                        job.customerContactPlannedFor != null
                            ? DSButtonVariant.secondary
                            : DSButtonVariant.primary,
                    expand: true,
                    onTap:
                        () => _openContactSheet(
                          widget.quote.jobId,
                          job.customerContactPlannedFor,
                        ),
                  ),
                ],

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
                      onTap:
                          billingLoading
                              ? null
                              : () => _handleReadyForBilling(
                                widget.quote.jobId,
                                widget.quote,
                              ),
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
                            Icon(
                              LucideIcons.alarmClock,
                              size: 16,
                              color: _c.text.muted,
                            ),
                            const SizedBox(width: DSSpacing.s2),
                            Expanded(
                              child: Text(
                                'Du kan bekræfte din deltagelse 5 dage før arrangementet',
                                style: DSTextStyle.labelMd.copyWith(
                                  color: _c.text.muted,
                                ),
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
                        onTap:
                            readyLoading
                                ? null
                                : () => _handleConfirmReady(widget.quote),
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
                    'Optag content',
                  ],
                  completedSteps: completedSteps,
                ),
              ],
            ),

            // ── Step 5: content capture (unlocked once ready confirmed) ──
            if (isConfirmedReady) ...[
              const SizedBox(height: DSSpacing.s4),
              JobContentSection(quoteId: widget.quote.id),
            ],

            const SizedBox(height: DSSpacing.s4),
            const SickDisclaimer(role: 'dj'),
          ],
        );
      },
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: DSSpacing.s3,
        horizontal: DSSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.state.success.withValues(alpha: 0.55)),
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
  const _ContactRow({required this.icon, required this.label, this.onCopy});

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
            onTap: onCopy,
          ),
      ],
    );
  }
}

class _EarlySetupRow extends StatelessWidget {
  const _EarlySetupRow({required this.status, this.price});

  final String status;
  final int? price;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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

    final priceLabel =
        (isAccepted || isOffered)
            ? (price != null && price! > 0
                ? ' · $price kr.${isOffered ? " ekstra" : ""}'
                : ' · gratis')
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.s3,
        vertical: DSSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.50)),
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

// ─── Extra Hours Section ──────────────────────────────────────────────────────

class _ExtraHoursSection extends ConsumerStatefulWidget {
  const _ExtraHoursSection({required this.quote});

  final DjQuote quote;

  @override
  ConsumerState<_ExtraHoursSection> createState() => _ExtraHoursSectionState();
}

class _ExtraHoursSectionState extends ConsumerState<_ExtraHoursSection> {
  DSColors get _c => DSTheme.of(context);
  final _priceController = TextEditingController();
  // "Samlet pris" mode: the DJ types the agreed TOTAL instead of a per-hour rate.
  final _totalController = TextEditingController();
  String _priceMode = 'perHour'; // 'perHour' | 'total'
  double? _selectedHours;
  bool _editing = false;

  // Window: event date (00:00) through end of event date + 2 days (23:59:59)
  bool get _windowOpen {
    final eventDate = widget.quote.job.date;
    final windowStart = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );
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
    final rate = widget.quote.extraHoursPricePerHour;
    if (rate != null) {
      _priceController.text = rate.round().toString();
    } else {
      final djProfile = ref.read(djProfileProvider).valueOrNull;
      if (djProfile != null && djProfile.pricePerExtraHour > 0) {
        _priceController.text = djProfile.pricePerExtraHour.toString();
      }
    }
    final eh = widget.quote.extraHours;
    if (eh != null && rate != null) {
      _totalController.text = (eh * rate).round().toString();
      // A non-whole stored rate means it was entered as a total → default to that mode.
      if (rate != rate.roundToDouble()) _priceMode = 'total';
    }
    _selectedHours = extraHoursSelectedValue(widget.quote.extraHours);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hours = _selectedHours;
    if (hours == null || hours <= 0) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Vælg antal timer',
      );
      return;
    }

    // Either the DJ typed the agreed TOTAL (rate derived) or a per-hour rate.
    num effectiveRate;
    num extraCost;
    if (_priceMode == 'total') {
      final total = int.tryParse(_totalController.text);
      if (total == null || total <= 0) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: 'Angiv en gyldig samlet pris',
        );
        return;
      }
      extraCost = total;
      // Full precision so the server's (total == hours × rate) check passes within tolerance.
      effectiveRate = total / hours;
    } else {
      final price = int.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: 'Angiv en gyldig pris pr. time',
        );
        return;
      }
      extraCost = hours * price;
      effectiveRate = price;
    }

    // Compute the expected new total the same way the web API does: strip any
    // existing extra-hours from price_dkk to get the base, then add the new
    // extra-hours. The server re-validates this (rejects on mismatch).
    final existingExtra =
        (widget.quote.extraHours ?? 0) *
        (widget.quote.extraHoursPricePerHour ?? 0);
    final basePrice = widget.quote.priceDkk - existingExtra;
    final newTotalPrice = (basePrice + extraCost).round();

    final ok = await ref
        .read(addExtraHoursProvider.notifier)
        .add(
          widget.quote.id,
          extraHours: hours,
          pricePerHour: effectiveRate,
          newTotalPrice: newTotalPrice,
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Ekstra timer gemt',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke gemme ekstra timer. Prøv igen.',
      );
    }
  }

  Future<void> _delete() async {
    final ok = await ref
        .read(deleteExtraHoursProvider.notifier)
        .delete(widget.quote.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _editing = false;
        _selectedHours = null;
      });
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Ekstra timer fjernet',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke fjerne ekstra timer. Prøv igen.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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
              Icon(
                LucideIcons.alarmPlus,
                size: 18,
                color: _c.brand.primaryActive,
              ),
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
                Expanded(child: _DeleteButton(onTap: _delete)),
              ],
            ),
          ] else if (_windowOpen && (!hasHours || _editing)) ...[
            // Input form
            HoursPickerField(
              value: _selectedHours,
              onChanged: (v) => setState(() => _selectedHours = v),
            ),
            const SizedBox(height: DSSpacing.s3),
            // Choose how to price the extra hours: a per-hour rate, or the agreed total.
            Row(
              children: [
                Expanded(
                  child: DSButton(
                    label: 'Pris pr. time',
                    variant:
                        _priceMode == 'perHour'
                            ? DSButtonVariant.primary
                            : DSButtonVariant.secondary,
                    onTap: () => setState(() => _priceMode = 'perHour'),
                  ),
                ),
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: DSButton(
                    label: 'Samlet pris',
                    variant:
                        _priceMode == 'total'
                            ? DSButtonVariant.primary
                            : DSButtonVariant.secondary,
                    onTap: () => setState(() => _priceMode = 'total'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s3),
            if (_priceMode == 'perHour')
              DSInput(
                label: 'Pris pr. time (DKK)',
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )
            else
              DSInput(
                label: 'Samlet pris for de ekstra timer (DKK)',
                controller: _totalController,
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
  const _ExtraHoursSummary({required this.hours, required this.pricePerHour});

  final double hours;
  final num pricePerHour;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final hoursLabel =
        hours == hours.truncateToDouble()
            ? '${hours.toInt()} timer'
            : '$hours timer';
    final total = (hours * pricePerHour).round();
    return Column(
      children: [
        _SummaryRow(label: 'Timer', value: hoursLabel),
        _SummaryRow(
          label: 'Pris pr. time',
          value: '${pricePerHour.round()} kr.',
        ),
        Divider(height: 16, color: _c.border.subtle),
        _SummaryRow(label: 'Tillæg i alt', value: '$total kr.', bold: true),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final deleteState = ref.watch(deleteExtraHoursProvider);
    final isLoading = deleteState is AsyncLoading;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _c.state.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.state.danger.withValues(alpha: 0.50)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    if (jobId == null) return const SizedBox.shrink();
    final offersAsync = ref.watch(serviceOffersForJobProvider(jobId!));

    return offersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (offers) {
        // Only show the confirmed (won) instrumentalist, so the DJ and sax see
        // each other only once both are locked in (matches the ext-job view).
        final won =
            offers.where((o) => o.status == ServiceOfferStatus.won).toList();
        if (won.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: 0),
            _Section(
              title: 'Instrumentalist på dette job',
              children: [
                for (final offer in won) ...[
                  _MusicianOfferRow(offer: offer),
                  if (offer != won.last)
                    Divider(height: DSSpacing.s4, color: _c.border.subtle),
                ],
                const SizedBox(height: DSSpacing.s3),
                ConversationCard(jobId: jobId),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _c = DSTheme.of(context);
    final imageUrl =
        ref.watch(userProfileImageProvider(offer.musicianId)).valueOrNull;
    final (statusLabel, statusColor) = switch (offer.status) {
      ServiceOfferStatus.sent => ('Tilbud afgivet', _c.state.warning),
      ServiceOfferStatus.won => ('Valgt instrumentalist', _c.state.success),
      ServiceOfferStatus.lost => ('Tilbud afvist', _c.text.muted),
    };

    final instrumentLabel =
        offer.instrument.isNotEmpty
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
              fallbackIcon: LucideIcons.music2,
              tintColor: isWon ? _c.state.success : _c.text.muted,
              bgColor:
                  isWon
                      ? _c.state.success.withValues(alpha: 0.20)
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
                    style: DSTextStyle.labelSm.copyWith(
                      color: _c.text.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.20),
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
              color: _c.state.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(
                color: _c.state.success.withValues(alpha: 0.45),
              ),
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
                      Clipboard.setData(
                        ClipboardData(text: offer.musicianPhone!),
                      );
                      DSToast.show(
                        context,
                        variant: DSToastVariant.success,
                        title: 'Telefon kopieret',
                      );
                    },
                  ),
                if (offer.musicianPhone != null && offer.musicianEmail != null)
                  const SizedBox(height: DSSpacing.s2),
                if (offer.musicianEmail != null)
                  _ContactLine(
                    icon: LucideIcons.mail,
                    value: offer.musicianEmail!,
                    onCopy: () {
                      Clipboard.setData(
                        ClipboardData(text: offer.musicianEmail!),
                      );
                      DSToast.show(
                        context,
                        variant: DSToastVariant.success,
                        title: 'Email kopieret',
                      );
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
  const _ContactLine({
    required this.icon,
    required this.value,
    required this.onCopy,
  });
  final IconData icon;
  final String value;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
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
  DSColors get _c => DSTheme.of(context);
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
    final _c = DSTheme.of(context);
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
              style: DSTextStyle.bodyMd.copyWith(
                color: _c.text.primary,
                height: 1.5,
              ),
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
    final _c = DSTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(DSRadius.md),
      child: SizedBox(
        width: 36,
        height: 36,
        child:
            imageUrl != null
                ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: bgColor),
                  errorWidget:
                      (_, __, ___) => Container(
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
          vertical: DSSpacing.s2,
          horizontal: DSSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: _c.state.warning.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.state.warning.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: _c.state.warning,
            ),
            const SizedBox(width: DSSpacing.s2),
            Text(
              'Husk at kontakte d. $dateStr',
              style: DSTextStyle.bodySm.copyWith(
                color: _c.text.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Song Requests Row (compact nav entry in won body) ───────────────────────

class _SongRequestsRow extends ConsumerWidget {
  const _SongRequestsRow({required this.quote});
  final DjQuote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final requestsAsync = ref.watch(songRequestsForJobProvider(quote.jobId));

    final countLabel = requestsAsync.when(
      loading: () => '…',
      error: (_, __) => '—',
      data: (list) => '${list.length}',
    );

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SongRequestsScreen(jobId: quote.jobId),
            ),
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.border.subtle),
          boxShadow: DSShadow.sm,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.music, size: 18, color: c.brand.primaryActive),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Text(
                'Sangønsker',
                style: DSTextStyle.labelLg.copyWith(
                  color: c.text.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              countLabel,
              style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
            ),
            const SizedBox(width: DSSpacing.s2),
            Icon(LucideIcons.chevronRight, size: 16, color: c.text.muted),
          ],
        ),
      ),
    );
  }
}
