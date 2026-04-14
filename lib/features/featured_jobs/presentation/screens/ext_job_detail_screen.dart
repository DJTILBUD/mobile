import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';

class ExtJobDetailScreen extends ConsumerStatefulWidget {
  const ExtJobDetailScreen({super.key, required this.extJob});

  final ExtJob extJob;

  @override
  ConsumerState<ExtJobDetailScreen> createState() =>
      _ExtJobDetailScreenState();
}

class _ExtJobDetailScreenState extends ConsumerState<ExtJobDetailScreen> {
  late ExtJobStatus _status;
  late DateTime? _djReadyConfirmedAt;

  static const _c = lightColors;

  @override
  void initState() {
    super.initState();
    _status = widget.extJob.status;
    _djReadyConfirmedAt = widget.extJob.djReadyConfirmedAt;
  }

  bool _isWithin5Days(DateTime eventDate) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final eventMidnight =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventMidnight.difference(todayMidnight).inDays <= 5;
  }

  Future<void> _handleMarkContacted() async {
    final success = await ref
        .read(markExtJobContactedProvider.notifier)
        .markContacted(widget.extJob.id);

    if (!mounted) return;

    if (success) {
      setState(() => _status = ExtJobStatus.customerContacted);
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Kunden er markeret som kontaktet');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error,
          title: 'Noget gik galt. Prøv igen.');
    }
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
      setState(() => _status = ExtJobStatus.readyForBilling);
      DSToast.show(context,
          variant: DSToastVariant.success,
          title: 'Aftale lukket — faktura sendt til kunden');
    } else {
      DSToast.show(context,
          variant: DSToastVariant.error, title: 'Noget gik galt. Prøv igen.');
    }
  }

  Future<void> _handleConfirmReady() async {
    final success = await ref
        .read(confirmExtJobDjReadyProvider.notifier)
        .confirm(widget.extJob.id);
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
    final extJob = widget.extJob;
    final contactLoading =
        ref.watch(markExtJobContactedProvider) is AsyncLoading;
    final billingLoading =
        ref.watch(markExtJobReadyForBillingProvider) is AsyncLoading;
    final readyLoading = ref.watch(confirmExtJobDjReadyProvider) is AsyncLoading;
    final isContacted = _status == ExtJobStatus.customerContacted ||
        _status == ExtJobStatus.readyForBilling;
    final isReadyForBilling = _status == ExtJobStatus.readyForBilling;
    final isConfirmedReady = _djReadyConfirmedAt != null;
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
                ],
                completedSteps: completedSteps,
              ),
            ],
          ),
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

              // Step 1: Mark contacted
              if (isContacted)
                _DoneButton(label: 'Kunden er kontaktet')
              else
                DSButton(
                  label: 'Jeg har kontaktet kunden',
                  variant: DSButtonVariant.primary,
                  expand: true,
                  isLoading: contactLoading,
                  onTap: contactLoading ? null : _handleMarkContacted,
                ),

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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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

// ─── Done Button ──────────────────────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label});

  final String label;

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4, vertical: DSSpacing.s3),
      decoration: BoxDecoration(
        color: _c.state.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border:
            Border.all(color: _c.state.success.withValues(alpha: 0.4)),
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

  static const _c = lightColors;

  @override
  Widget build(BuildContext context) {
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
          DSIconButton(
              icon: LucideIcons.copy,
              variant: DSIconButtonVariant.ghost,
              size: DSButtonSize.sm,
              onTap: onCopy),
      ],
    );
  }
}
