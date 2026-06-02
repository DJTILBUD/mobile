import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/shared/widgets/conversation_card.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_content_section.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/sick_disclaimer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/contact_customer_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/song_requests_screen.dart';

class ExtJobDetailScreen extends ConsumerStatefulWidget {
  const ExtJobDetailScreen({super.key, required this.extJob});

  final ExtJob extJob;

  @override
  ConsumerState<ExtJobDetailScreen> createState() =>
      _ExtJobDetailScreenState();
}

class _ExtJobDetailScreenState extends ConsumerState<ExtJobDetailScreen> {
  DSColors get _c => DSTheme.of(context);

  String _toastError(AppException? err) {
    if (err == null) return 'Noget gik galt. Prøv igen.';
    final msg = err.message.toLowerCase();
    if (msg.contains('musician') && msg.contains('contact')) {
      return 'Din instrumentalist skal også kontakte kunden, inden du kan lukke aftalen. Koordinér med dem og prøv igen.';
    }
    if (msg.contains('customer_contacted') || msg.contains('customer-contacted')) {
      return 'Du skal markere kunden som kontaktet, inden du kan lukke aftalen.';
    }
    return friendlyErrorMessage(err, fallback: 'Noget gik galt. Prøv igen.');
  }

  bool _isWithin5Days(DateTime eventDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final eventMidnight =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventMidnight.difference(todayMidnight).inDays <= 5;
  }

  Future<void> _openContactSheet(DateTime? plannedDate) async {
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
          existingPlannedDate: plannedDate,
          onContacted: () async {
            final success = await ref
                .read(markExtJobContactedProvider.notifier)
                .markContacted(widget.extJob.id);
            if (mounted && success) {
              DSToast.show(context,
                  variant: DSToastVariant.success,
                  title: 'Kunden er markeret som kontaktet');
            } else if (mounted) {
              final err = ref.read(markExtJobContactedProvider).error;
              DSToast.show(context,
                  variant: DSToastVariant.error,
                  title: _toastError(err is AppException ? err : null));
            }
            return success;
          },
          onPlanned: (date) async {
            final success = await ref
                .read(setExtJobPlannedContactProvider.notifier)
                .setPlanned(widget.extJob.id, date);
            if (mounted && success) {
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

  Future<void> _handleReadyForBilling() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Luk aftale og send faktura'),
        content: const Text(
            'Er kunden klar til at modtage en faktura? Kunden vil modtage en bekræftelse og en faktura.'),
        actions: [
          DSButton(
              label: 'Annuller',
              variant: DSButtonVariant.ghost,
              size: DSButtonSize.sm,
              onTap: () => Navigator.pop(ctx, false)),
          DSButton(
              label: 'Luk aftale',
              variant: DSButtonVariant.tertiary,
              size: DSButtonSize.sm,
              onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(markExtJobReadyForBillingProvider.notifier)
        .markReady(widget.extJob.id);
    if (!mounted) return;
    if (success) {
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Aftale lukket — faktura sendt til kunden');
    } else {
      final err = ref.read(markExtJobReadyForBillingProvider).error;
      DSToast.show(context, variant: DSToastVariant.error,
          title: _toastError(err is AppException ? err : null));
    }
  }

  Future<void> _handleConfirmReady() async {
    final success = await ref
        .read(confirmExtJobDjReadyProvider.notifier)
        .confirm(widget.extJob.id);
    if (!mounted) return;
    if (success) {
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Bekræftet! God fornøjelse med jobbet 🎵');
    } else {
      final err = ref.read(confirmExtJobDjReadyProvider).error;
      DSToast.show(context, variant: DSToastVariant.error,
          title: _toastError(err is AppException ? err : null));
    }
  }

  /// Card showing the saxophonist/instrumentalist assigned to this job, so the
  /// DJ can see their counterpart (mirrors the internal-job view + the web).
  Widget _instrumentalistCard(ExtJob extJob) {
    final c = DSTheme.of(context);
    final imageUrl = ref.watch(userProfileImageProvider(extJob.assignedMusicianId!)).valueOrNull;
    return _SectionCard(
      title: 'Instrumentalist på dette job',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.state.success.withValues(alpha: 0.20),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Icon(LucideIcons.music2, color: c.state.success, size: 20)
                  : null,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Text(
                extJob.assignedMusicianName ?? 'Instrumentalist',
                style: DSTextStyle.labelMd.copyWith(fontWeight: FontWeight.w600, color: c.text.primary),
              ),
            ),
            DSStatusBadge(label: 'Valgt instrumentalist', color: c.state.success),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    // Source of truth: latest ExtJob row from the provider. Falling back to
    // widget.extJob handles the brief window before djExtJobsProvider has
    // loaded, plus non-DJ callers (musicians) where the row isn't in this list.
    final extJob = ref.watch(djExtJobsProvider).valueOrNull?.firstWhere(
              (e) => e.id == widget.extJob.id,
              orElse: () => widget.extJob,
            ) ??
        widget.extJob;
    final billingLoading =
        ref.watch(markExtJobReadyForBillingProvider) is AsyncLoading;
    final readyLoading = ref.watch(confirmExtJobDjReadyProvider) is AsyncLoading;
    final isContacted = extJob.status == ExtJobStatus.customerContacted ||
        extJob.status == ExtJobStatus.readyForBilling;
    final isReadyForBilling = extJob.status == ExtJobStatus.readyForBilling;
    final isConfirmedReady = extJob.djReadyConfirmedAt != null;
    final canConfirmReady = _isWithin5Days(extJob.date);

    int completedSteps = 0;
    if (isContacted) completedSteps = 1;
    if (isReadyForBilling) completedSteps = 2;
    if (isConfirmedReady) completedSteps = 3;

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventTypeLabel(extJob.displayEventType),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            JobIdBadge(id: extJob.id, isExtJob: true),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DSSpacing.s4),
        children: [
          // ── Process tracker ──────────────────────────────────────────────
          _SectionCard(
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
          const SizedBox(height: DSSpacing.s4),

          // ── Step 5: content capture (unlocked once ready confirmed) ──
          if (isConfirmedReady) ...[
            JobContentSection(extJobId: extJob.id),
            const SizedBox(height: DSSpacing.s4),
          ],

          // ── Sygdom / sick-leave disclaimer ───────────────────────────────
          const SickDisclaimer(role: 'dj'),
          const SizedBox(height: DSSpacing.s4),

          // ── Customer contact ─────────────────────────────────────────────
          _SectionCard(
            title: 'Kundekontakt',
            children: [
              _ContactRow(icon: LucideIcons.user, label: extJob.leadName),
              if (extJob.email != null) ...[
                const SizedBox(height: DSSpacing.s2),
                _ContactRow(
                  icon: LucideIcons.mail,
                  label: extJob.email!,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: extJob.email!));
                    DSToast.show(context,
                        variant: DSToastVariant.success,
                        title: 'Email kopieret');
                  },
                ),
              ],
              if (extJob.phoneNumber != null) ...[
                const SizedBox(height: DSSpacing.s2),
                _ContactRow(
                  icon: LucideIcons.phone,
                  label: extJob.phoneNumber!,
                  onCopy: () {
                    Clipboard.setData(
                        ClipboardData(text: extJob.phoneNumber!));
                    DSToast.show(context,
                        variant: DSToastVariant.success,
                        title: 'Telefon kopieret');
                  },
                ),
              ],

              const SizedBox(height: DSSpacing.s4),
              const Divider(height: 1),
              const SizedBox(height: DSSpacing.s4),

              // Step 1: Mark contacted (or set planned date)
              if (isContacted)
                _DoneButton(label: 'Kunden er kontaktet')
              else ...[
                if (extJob.customerContactPlannedFor != null)
                  _PlannedContactBanner(date: extJob.customerContactPlannedFor!),
                DSButton(
                  label: extJob.customerContactPlannedFor != null
                      ? 'Ændr kontaktdato'
                      : 'Kontakt kunden',
                  variant: extJob.customerContactPlannedFor != null
                      ? DSButtonVariant.secondary
                      : DSButtonVariant.primary,
                  expand: true,
                  onTap: () => _openContactSheet(extJob.customerContactPlannedFor),
                ),
              ],

              // Step 2: Mark ready for billing
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
                    onTap: billingLoading ? null : _handleReadyForBilling,
                  ),
              ],

              // Step 3: Jeg er klar
              if (isReadyForBilling) ...[
                const SizedBox(height: DSSpacing.s3),
                if (isConfirmedReady)
                  _DoneButton(label: 'Jeg er klar!')
                else if (!canConfirmReady)
                  _LockedInfo(
                    label:
                        'Du kan bekræfte "Jeg er klar" 5 dage før jobbet.',
                  )
                else
                  DSButton(
                    label: 'Jeg er klar!',
                    variant: DSButtonVariant.primary,
                    expand: true,
                    isLoading: readyLoading,
                    onTap: readyLoading ? null : _handleConfirmReady,
                  ),
              ],
            ],
          ),
          const SizedBox(height: DSSpacing.s4),

          // ── Instrumentalist on this job (only once both are confirmed) ────
          if (extJob.assignedMusicianId != null &&
              const {
                ExtJobStatus.closed,
                ExtJobStatus.customerContacted,
                ExtJobStatus.readyForBilling,
              }.contains(extJob.status)) ...[
            _instrumentalistCard(extJob),
            const SizedBox(height: DSSpacing.s4),
          ],

          // ── Chat with instrumentalist ────────────────────────────────────
          ConversationCard(extJobId: extJob.id),
          const SizedBox(height: DSSpacing.s4),

          // ── Song requests ─────────────────────────────────────────────────
          _ExtJobSongRequestsRow(extJob: extJob),
          const SizedBox(height: DSSpacing.s4),

          // ── Invoice badge ────────────────────────────────────────────────
          InvoiceStatusBadge(extJobId: extJob.id),
          const SizedBox(height: DSSpacing.s4),

          // ── Job info card ────────────────────────────────────────────────
          _JobInfoCard(extJob: extJob),

          const SizedBox(height: DSSpacing.s8),
        ],
      ),
    );
  }
}

// ─── Job Info Card ────────────────────────────────────────────────────────────

class _JobInfoCard extends StatelessWidget {
  const _JobInfoCard({required this.extJob});

  final ExtJob extJob;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    final dateStr =
        DateFormat('EEEE d. MMMM yyyy', 'da_DK').format(extJob.date);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
        boxShadow: DSShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                DSSpacing.s4, DSSpacing.s4, DSSpacing.s4, DSSpacing.s3),
            child: Text(
              eventTypeLabel(extJob.displayEventType),
              style:
                  DSTextStyle.headingMd.copyWith(color: _c.text.primary),
            ),
          ),

          const Divider(height: 1),

          // Meta rows
          Padding(
            padding: const EdgeInsets.all(DSSpacing.s4),
            child: Column(
              children: [
                _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Dato',
                    value: dateStr),
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                    icon: LucideIcons.clock,
                    label: 'Tidspunkt',
                    value: extJob.timeDisplay),
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                    icon: LucideIcons.mapPin,
                    label: 'Lokation',
                    value: extJob.displayLocation),
                if (extJob.guestsAmount != null) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                      icon: LucideIcons.users,
                      label: 'Gæster',
                      value: '${extJob.guestsAmount}'),
                ],
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                    icon: LucideIcons.banknote,
                    label: 'Honorar',
                    value: extJob.budgetDisplay),
                if (extJob.requestedMusicianHours != null) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                      icon: LucideIcons.timer,
                      label: 'Spilletid',
                      value:
                          '${extJob.requestedMusicianHours!.toStringAsFixed(0)} timer'),
                ],
                if (extJob.company != null && extJob.company!.isNotEmpty) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                      icon: LucideIcons.building2,
                      label: 'Virksomhed',
                      value: extJob.company!),
                ],
                if (extJob.birthdayPersonAge != null &&
                    extJob.birthdayPersonAge!.isNotEmpty) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                      icon: LucideIcons.cake,
                      label: 'Alder (fødselar)',
                      value: extJob.birthdayPersonAge!),
                ],
              ],
            ),
          ),

          // Notes
          if (extJob.notes != null && extJob.notes!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(DSSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Noter',
                    style: DSTextStyle.labelMd.copyWith(
                        color: _c.text.muted,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    extJob.notes!,
                    style:
                        DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                  ),
                ],
              ),
            ),
          ],

          // Special request to the musician
          if (extJob.musicianSpecialRequest != null &&
              extJob.musicianSpecialRequest!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(DSSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.star, size: 14, color: _c.state.warning),
                      const SizedBox(width: DSSpacing.s1),
                      Text(
                        'Særligt ønske til musikeren',
                        style: DSTextStyle.labelMd.copyWith(
                            color: _c.state.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    extJob.musicianSpecialRequest!,
                    style:
                        DSTextStyle.bodyMd.copyWith(color: _c.text.secondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _c.text.muted),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    DSTextStyle.labelSm.copyWith(color: _c.text.muted),
              ),
              Text(
                value,
                style:
                    DSTextStyle.bodyMd.copyWith(color: _c.text.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

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

// ─── Done Button ──────────────────────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border:
            Border.all(color: _c.state.success.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle,
              size: 16, color: _c.state.success),
          const SizedBox(width: 6),
          Text(
            '$label ✓',
            style: DSTextStyle.labelMd.copyWith(
              color: _c.state.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Locked Info ──────────────────────────────────────────────────────────────

class _LockedInfo extends StatelessWidget {
  const _LockedInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
      final _c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.bg.canvas,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: _c.border.subtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alarmClock, size: 16, color: _c.text.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Row ──────────────────────────────────────────────────────────────

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

// ─── Song Requests Row ────────────────────────────────────────────────────────

class _ExtJobSongRequestsRow extends ConsumerWidget {
  const _ExtJobSongRequestsRow({required this.extJob});
  final ExtJob extJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final requestsAsync =
        ref.watch(songRequestsForExtJobProvider(extJob.id));

    final countLabel = requestsAsync.when(
      loading: () => '…',
      error: (_, __) => '—',
      data: (list) => '${list.length}',
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SongRequestsScreen(
            extJobId: extJob.id,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
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
          border: Border.all(color: _c.state.warning.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: _c.state.warning),
            const SizedBox(width: DSSpacing.s2),
            Text('Husk at kontakte d. $dateStr',
                style: DSTextStyle.bodySm.copyWith(
                    color: _c.text.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
