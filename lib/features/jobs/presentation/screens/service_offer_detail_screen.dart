import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class ServiceOfferDetailScreen extends ConsumerStatefulWidget {
  const ServiceOfferDetailScreen({super.key, required this.offer});

  final ServiceOffer offer;

  @override
  ConsumerState<ServiceOfferDetailScreen> createState() =>
      _ServiceOfferDetailScreenState();
}

class _ServiceOfferDetailScreenState
    extends ConsumerState<ServiceOfferDetailScreen> {
  late bool _customerContacted;
  late DateTime? _musicianReadyConfirmedAt;

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    _customerContacted = widget.offer.customerContacted;
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

  Future<void> _handleMarkContacted() async {
    final success = await ref
        .read(markServiceOfferContactedProvider.notifier)
        .markContacted(widget.offer.id);

    if (!mounted) return;

    if (success) {
      setState(() => _customerContacted = true);
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Kunden er markeret som kontaktet');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Noget gik galt. Prøv igen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final job = offer.job;
    final dateStr = DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(job.date);
    final contactLoading =
        ref.watch(markServiceOfferContactedProvider) is AsyncLoading;
    final readyLoading =
        ref.watch(confirmMusicianReadyProvider) is AsyncLoading;
    final isConfirmedReady = _musicianReadyConfirmedAt != null;
    final canConfirmReady = _isWithin5Days(job.date);

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTypeLabel(job.eventType),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobIdBadge(id: offer.jobId ?? offer.extJobId ?? 0, isExtJob: offer.isExtJob),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          // Status header
          _StatusHeader(status: offer.status),
          const SizedBox(height: DSSpacing.s4),

          // Job details
          _Section(
            title: 'Job detaljer',
            children: [
              _DetailRow(LucideIcons.calendar, 'Dato', dateStr),
              _DetailRow(LucideIcons.clock, 'Tidspunkt', job.timeDisplay),
              _DetailRow(LucideIcons.mapPin, 'Lokation',
                  _locationDisplay(job.city, job.region)),
              if (job.guestsAmount > 0)
                _DetailRow(LucideIcons.users, 'Gæster',
                    '${job.guestsAmount}'),
              if (job.requestedMusicianHours != null)
                _DetailRow(LucideIcons.timer, 'Ønsket spilletid',
                    '${job.requestedMusicianHours!.toStringAsFixed(0)} timer'),
            ],
          ),
          const SizedBox(height: DSSpacing.s4),

          // Offer info
          _Section(
            title: 'Dit tilbud',
            children: [
              _DetailRow(LucideIcons.banknote, 'Pris',
                  '${offer.priceDkk} kr.'),
              if (offer.musicianPayoutDkk != null)
                _DetailRow(LucideIcons.wallet,
                    'Din betaling', '${offer.musicianPayoutDkk} kr.'),
              _DetailRow(LucideIcons.mic, 'Instrument', offer.instrument),
              if (offer.salesPitch != null &&
                  offer.salesPitch!.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.s2),
                Text('Salgstale',
                    style: DSTextStyle.labelSm.copyWith(
                        color: _c.text.muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  offer.salesPitch!,
                  style: DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: DSSpacing.s4),

          // Extra hours (won offers only)
          if (offer.status == ServiceOfferStatus.won) ...[
            const SizedBox(height: DSSpacing.s4),
            _MusicianExtraHoursSection(offer: offer),
          ],

          // Private musician notes (won offers only)
          if (offer.status == ServiceOfferStatus.won) ...[
            const SizedBox(height: DSSpacing.s4),
            _MusicianNotesSection(offer: offer),
          ],

          // Won state: customer contact + process tracker
          if (offer.status == ServiceOfferStatus.won) ...[
            InvoiceStatusBadge(
              jobId: offer.isExtJob ? null : offer.jobId,
              extJobId: offer.isExtJob ? offer.extJobId : null,
            ),
            const SizedBox(height: DSSpacing.s4),
            // DJ contact — ext job with assigned DJ name (basic, name only)
            if (offer.isExtJob && job.assignedDjName != null) ...[
              _Section(
                title: 'DJ på jobbet',
                children: [
                  _ContactRow(icon: LucideIcons.user, label: job.assignedDjName!),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    'Koordiner logistik og sceneopsætning med DJ\'en inden arrangementet.',
                    style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.s4),
            ],
            // DJ contact — internal job with a won DJ quote
            if (!offer.isExtJob && offer.jobId != null) ...[
              _WonDjSection(jobId: offer.jobId!),
              const SizedBox(height: DSSpacing.s4),
            ],
            _Section(
              title: 'Kundekontakt',
              children: [
                if (job.leadName != null)
                  _ContactRow(
                    icon: LucideIcons.user,
                    label: job.leadName!,
                  ),
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
                DSButton(
                  label: _customerContacted
                      ? 'Kunden er kontaktet ✓'
                      : 'Jeg har kontaktet kunden',
                  variant: _customerContacted
                      ? DSButtonVariant.secondary
                      : DSButtonVariant.primary,
                  expand: true,
                  isLoading: contactLoading,
                  onTap: (_customerContacted || contactLoading)
                      ? null
                      : _handleMarkContacted,
                ),

                // Step 2: Jeg er klar (after contacted, within 5 days)
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
                    onTap:
                        (isConfirmedReady || !canConfirmReady || readyLoading)
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
          ],

          const SizedBox(height: DSSpacing.s8),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status});

  final ServiceOfferStatus status;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ServiceOfferStatus.sent => ('Afventer kundens svar', _c.state.warning),
      ServiceOfferStatus.won => (
          'Kunden har accepteret dit tilbud!',
          _c.state.success
        ),
      ServiceOfferStatus.lost => ('Kunden valgte en anden', _c.state.danger),
    };

    final textColor =
        status == ServiceOfferStatus.won ? _c.text.primary : color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: DSTextStyle.headingSm.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        textAlign: TextAlign.center,
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

String _locationDisplay(String city, String region) {
  final parts = [city, region].where((s) => s.isNotEmpty).toList();
  return parts.isEmpty ? 'Ikke angivet' : parts.join(', ');
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _c.text.secondary),
          const SizedBox(width: DSSpacing.s2),
          Text(
            '$label: ',
            style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
          ),
          Expanded(
            child: Text(
              value,
              style: DSTextStyle.labelMd.copyWith(color: _c.text.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Won DJ Section (internal jobs, musician view) ───────────────────────────

class _WonDjSection extends ConsumerWidget {
  const _WonDjSection({required this.jobId});
  final int jobId;
  static const _c = lightColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final djAsync = ref.watch(wonDjInfoForJobProvider(jobId));

    return djAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dj) {
        if (dj == null) return const SizedBox.shrink();
        final imageUrl = ref.watch(userProfileImageProvider(dj.djId)).valueOrNull;
        return _Section(
          title: 'DJ på jobbet',
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: _c.brand.primary.withValues(alpha: 0.12),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: _c.brand.primary.withValues(alpha: 0.12),
                              child: Icon(LucideIcons.user, size: 18, color: _c.brand.primaryActive),
                            ),
                          )
                        : Container(
                            color: _c.brand.primary.withValues(alpha: 0.12),
                            child: Icon(LucideIcons.user, size: 18, color: _c.brand.primaryActive),
                          ),
                  ),
                ),
                const SizedBox(width: DSSpacing.s3),
                Text(
                  dj.fullName,
                  style: DSTextStyle.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _c.text.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s3),
            Container(
              padding: const EdgeInsets.all(DSSpacing.s3),
              decoration: BoxDecoration(
                color: _c.brand.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(DSRadius.md),
                border: Border.all(color: _c.brand.primary.withValues(alpha: 0.2)),
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
                  if (dj.phone != null)
                    _ContactRow(
                      icon: LucideIcons.phone,
                      label: dj.phone!,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: dj.phone!));
                        DSToast.show(context,
                            variant: DSToastVariant.success,
                            title: 'Telefon kopieret');
                      },
                    )
                  else
                    Text(
                      'Ingen kontaktinfo tilgængelig',
                      style: DSTextStyle.labelMd.copyWith(color: _c.text.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DSSpacing.s3),
            Text(
              'Koordiner logistik og sceneopsætning med DJ\'en inden arrangementet.',
              style: DSTextStyle.labelMd.copyWith(color: _c.text.muted, height: 1.4),
            ),
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
  static const _c = lightColors;

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
    final today = DateTime.now();
    final diff = today.difference(
        DateTime(eventDate.year, eventDate.month, eventDate.day));
    return diff.inDays >= -1 && diff.inDays <= 2;
  }

  Future<void> _save() async {
    final hours = double.tryParse(_hoursController.text.replaceAll(',', '.'));
    if (hours == null || hours <= 0) {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Indtast et gyldigt timeantal');
      return;
    }
    final ok = await ref
        .read(addMusicianExtraHoursProvider.notifier)
        .add(widget.offer.id, extraHours: hours);
    if (ok && mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.offer.job;
    final inWindow = _isWithinExtraHoursWindow(job.date);
    if (!inWindow && widget.offer.extraHours == null) {
      return const SizedBox.shrink();
    }

    final isSaving = ref.watch(addMusicianExtraHoursProvider) is AsyncLoading;
    final hasHours = widget.offer.extraHours != null;

    return _Section(
      title: 'Ekstra timer',
      children: [
        Text(
          hasHours
              ? 'Du registrerede ${widget.offer.extraHours!.toStringAsFixed(1)} ekstra timer.'
              : 'Spillede du flere timer end aftalt? Registrér dem her.',
          style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
        ),
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
  static const _c = lightColors;

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
    final isSaving = ref.watch(saveMusicianNotesProvider) is AsyncLoading;
    final hasNotes = (_savedNotes ?? '').isNotEmpty;

    return _Section(
      title: 'Private noter',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kun synlige for dig',
              style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
            ),
            if (!_editing)
              DSButton(
                label: hasNotes ? 'Redigér' : 'Tilføj',
                variant: DSButtonVariant.ghost,
                size: DSButtonSize.sm,
                onTap: () => setState(() => _editing = true),
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
    );
  }
}
