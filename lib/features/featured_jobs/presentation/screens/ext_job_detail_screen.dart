import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/utils/event_type_labels.dart';
import 'package:dj_tilbud_app/shared/widgets/conversation_card.dart';
import 'package:dj_tilbud_app/shared/widgets/copy_hint_row.dart';
import 'package:dj_tilbud_app/shared/widgets/chat_bubble_fab.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';
import 'package:dj_tilbud_app/features/jobs/domain/ready_for_billing_gate.dart';
import 'package:dj_tilbud_app/shared/widgets/locked_info_banner.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/utils/extra_hours_options.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/hours_picker_field.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/invoice_status_badge.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/process_tracker.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/customer_deadline_banner.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/job_content_section.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/sick_disclaimer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/shared/widgets/job_id_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/recurring_customer_badge.dart';
import 'package:dj_tilbud_app/shared/widgets/partner_event_wishes_card.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/contact_customer_sheet.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/event_address_section.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/screens/song_requests_screen.dart';
import 'package:dj_tilbud_app/core/analytics/analytics_service.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/widgets/decline_extra_hours.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/venue_photo.dart';
import 'package:dj_tilbud_app/shared/widgets/venue_photos_card.dart';
import 'package:dj_tilbud_app/core/utils/planned_contact.dart';

class ExtJobDetailScreen extends ConsumerStatefulWidget {
  const ExtJobDetailScreen({super.key, required this.extJob});

  final ExtJob extJob;

  @override
  ConsumerState<ExtJobDetailScreen> createState() => _ExtJobDetailScreenState();
}

class _ExtJobDetailScreenState extends ConsumerState<ExtJobDetailScreen> {
  DSColors get _c => DSTheme.of(context);

  // One copy of the mapping, shared with the internal-job DJ screen
  // (quote_detail_screen) so the two can never tell the DJ different things.
  String _toastError(AppException? err) => readyForBillingErrorMessage(err);

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

  Future<void> _openContactSheet(DateTime? plannedDate) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _c.bg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
      ),
      builder:
          // ⚠️ `sheetContext`, NOT the outer screen's `context`. A modal sheet is a separate route:
          // reading viewInsets off the parent captures the value at push time (usually 0) and the
          // sheet never rebuilds as the keyboard animates in, so the padding stays 0 forever.
          (sheetContext) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: ContactCustomerSheet(
              existingPlannedDate: plannedDate,
              onContacted: () async {
                final success = await ref
                    .read(markExtJobContactedProvider.notifier)
                    .markContacted(widget.extJob.id);
                if (mounted && success) {
                  AnalyticsService.logCustomerContacted(
                    widget.extJob.id,
                    role: 'dj',
                    isExtJob: true,
                  );
                  DSToast.show(
                    context,
                    variant: DSToastVariant.success,
                    title: 'Kunden er markeret som kontaktet',
                  );
                } else if (mounted) {
                  final err = ref.read(markExtJobContactedProvider).error;
                  DSToast.show(
                    context,
                    variant: DSToastVariant.error,
                    title: _toastError(err is AppException ? err : null),
                  );
                }
                return success;
              },
              onPlanned: (date) async {
                final success = await ref
                    .read(setExtJobPlannedContactProvider.notifier)
                    .setPlanned(widget.extJob.id, date);
                if (mounted && success) {
                  AnalyticsService.logCustomerContacted(
                    widget.extJob.id,
                    role: 'dj',
                    isExtJob: true,
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
  }

  Future<void> _handleReadyForBilling() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Luk aftale og send faktura'),
            content: const Text(
              'Er kunden klar til at modtage en faktura? Kunden vil modtage en bekræftelse og en faktura.',
            ),
            actions: [
              DSButton(
                label: 'Annuller',
                variant: DSButtonVariant.ghost,
                size: DSButtonSize.sm,
                onTap: () => Navigator.pop(ctx, false),
              ),
              DSButton(
                label: 'Luk aftale',
                variant: DSButtonVariant.tertiary,
                size: DSButtonSize.sm,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(markExtJobReadyForBillingProvider.notifier)
        .markReady(widget.extJob.id);
    if (!mounted) return;
    if (success) {
      AnalyticsService.logReadyForBilling(
        widget.extJob.id,
        role: 'dj',
        isExtJob: true,
      );
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Aftale lukket — faktura sendt til kunden',
      );
    } else {
      final err = ref.read(markExtJobReadyForBillingProvider).error;
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: _toastError(err is AppException ? err : null),
      );
      // Refresh the offer list so a rejection the DJ just hit also disables the button.
      ref.invalidate(serviceOffersForExtJobProvider(widget.extJob.id));
    }
  }

  Future<void> _handleConfirmReady() async {
    final success = await ref
        .read(confirmExtJobDjReadyProvider.notifier)
        .confirm(widget.extJob.id);
    if (!mounted) return;
    if (success) {
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Bekræftet! God fornøjelse med jobbet 🎵',
      );
    } else {
      final err = ref.read(confirmExtJobDjReadyProvider).error;
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: _toastError(err is AppException ? err : null),
      );
    }
  }

  /// Card showing the saxophonist/instrumentalist assigned to this job, so the
  /// DJ can see their counterpart (mirrors the internal-job view + the web).
  Widget _instrumentalistCard(ExtJob extJob) {
    final c = DSTheme.of(context);
    final imageUrl =
        ref
            .watch(userProfileImageProvider(extJob.assignedMusicianId!))
            .valueOrNull;
    return _SectionCard(
      title: 'Instrumentalist på dette job',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.state.success.withValues(alpha: 0.20),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child:
                  imageUrl == null
                      ? Icon(
                        LucideIcons.music2,
                        color: c.state.success,
                        size: 20,
                      )
                      : null,
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Text(
                extJob.assignedMusicianName ?? 'Instrumentalist',
                style: DSTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text.primary,
                ),
              ),
            ),
            DSStatusBadge(
              label: 'Valgt instrumentalist',
              color: c.state.success,
            ),
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
    final extJob =
        ref
            .watch(djExtJobsProvider)
            .valueOrNull
            ?.firstWhere(
              (e) => e.id == widget.extJob.id,
              orElse: () => widget.extJob,
            ) ??
        widget.extJob;
    // True only when the current user is the assigned DJ — djExtJobsProvider
    // queries by assigned_dj_id, so a musician viewing this screen never matches.
    // Gates the (DJ-only) extra-hours section.
    final isAssignedDj =
        ref
            .watch(djExtJobsProvider)
            .valueOrNull
            ?.any((e) => e.id == widget.extJob.id) ??
        false;
    final billingLoading =
        ref.watch(markExtJobReadyForBillingProvider) is AsyncLoading;
    final readyLoading =
        ref.watch(confirmExtJobDjReadyProvider) is AsyncLoading;
    final isContacted =
        extJob.status == ExtJobStatus.customerContacted ||
        extJob.status == ExtJobStatus.readyForBilling;
    final isReadyForBilling = extJob.status == ExtJobStatus.readyForBilling;
    final isConfirmedReady = extJob.djReadyConfirmedAt != null;
    final canConfirmReady = _isWithin5Days(extJob.date);
    // Same server rule as the internal-job screen: the assigned DJ cannot close the
    // deal until every WINNING musician on this ext job has marked the customer
    // contacted (`PUT /api/ext-jobs/[id]/ready-for-billing` → 400
    // `musician_not_contacted`). Only the DJ is gated — a musician on this screen is
    // the one being waited for. Fails open on an unloaded list; the server decides.
    final wonExtOffers =
        isAssignedDj
            ? (ref
                    .watch(serviceOffersForExtJobProvider(widget.extJob.id))
                    .valueOrNull ??
                const <ServiceOffer>[])
            : const <ServiceOffer>[];
    final musicianContactBlocked = isBlockedByMusicianContact(wonExtOffers);
    // Recurring-customer (venue) name, resolved server-side. This screen is shared
    // by DJs and musicians, so coalesce both role-scoped maps — each is empty for
    // the other role. Absent (badge hidden) when it's not a fixed customer.
    final recurringName =
        ref.watch(djExtJobRecurringNamesProvider).valueOrNull?[extJob.id] ??
        ref.watch(musicianExtJobRecurringNamesProvider).valueOrNull?[extJob.id];
    // Venue photos from the team's site visit. DJ-only endpoint; a musician
    // opening this shared screen just gets an empty map (card self-hides).
    final venuePhotos =
        ref.watch(djExtJobVenuePhotosProvider).valueOrNull?[extJob.id] ??
        const <VenuePhoto>[];

    int completedSteps = 0;
    if (isContacted) completedSteps = 1;
    if (isReadyForBilling) completedSteps = 2;
    if (isConfirmedReady) completedSteps = 3;

    final wishesCard = PartnerEventWishesCard(
      addressAs: extJob.addressAs,
      guestAge: extJob.guestAge,
      firstDanceSong: extJob.firstDanceSong,
      spotifyPlaylistUrl: extJob.spotifyPlaylistUrl,
      specialConditions: extJob.specialConditions,
      room: extJob.room,
      earlySetup: extJob.earlySetup,
      wantsIc: extJob.wantsIc,
      saxType: extJob.saxType,
      musicianStartTime: extJob.musicianStartTime,
      requestedMusicianHours: extJob.requestedMusicianHours,
      musicianSpecialRequest: extJob.musicianSpecialRequest,
    );
    // A partner (recurring) booking always gets the "Stedet" tab, even before any
    // photos exist, so the DJ learns where venue info lives. Other ext jobs only
    // get it when there is something to show.
    final showVenueTab =
        extJob.isRecurringCustomer ||
        venuePhotos.isNotEmpty ||
        wishesCard.hasContent;

    final jobTab = ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        // ── Fast kunde (recurring customer) badge — mirrors web udvalgte-jobs ──
        if (recurringName != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: RecurringCustomerBadge(name: recurringName),
          ),
          const SizedBox(height: DSSpacing.s4),
        ],

        // ── Aflyst-banner: a canceled ext job can still be opened via a stale push, so make
        // it unmistakable instead of rendering it as a live, active job. ──
        if (extJob.status == ExtJobStatus.canceled) ...[
          _CanceledBanner(),
          const SizedBox(height: DSSpacing.s4),
        ],

        // ── Kundens svarfrist (same widget as normal jobs) ──
        // Shown while the offer is out to the customer (status 'sent'); decisionDeadline is
        // null until sent_at is stamped, so it also self-hides defensively.
        if (extJob.status == ExtJobStatus.sent &&
            extJob.decisionDeadline != null) ...[
          CustomerDeadlineBanner(deadline: extJob.decisionDeadline),
          const SizedBox(height: DSSpacing.s4),
        ],

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

        // ── Spillestedets adresse (kun synlig for den tildelte DJ/musiker) ──
        if (!showVenueTab) EventAddressSection(extJobId: extJob.id),

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
                  DSToast.show(
                    context,
                    variant: DSToastVariant.success,
                    title: 'Email kopieret',
                  );
                },
              ),
            ],
            if (extJob.phoneNumber != null) ...[
              const SizedBox(height: DSSpacing.s2),
              _ContactRow(
                icon: LucideIcons.phone,
                label: extJob.phoneNumber!,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: extJob.phoneNumber!));
                  DSToast.show(
                    context,
                    variant: DSToastVariant.success,
                    title: 'Telefon kopieret',
                  );
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
                // Once the planned date is today or has passed, the DJ should be calling now, so the
                // button reverts to the primary "Kunde kontaktet" action instead of offering to reschedule.
                label:
                    extJob.customerContactPlannedFor != null &&
                            !isPlannedContactDue(
                              extJob.customerContactPlannedFor,
                            )
                        ? 'Ændr kontaktdato'
                        : 'Kunde kontaktet',
                variant:
                    extJob.customerContactPlannedFor != null &&
                            !isPlannedContactDue(
                              extJob.customerContactPlannedFor,
                            )
                        ? DSButtonVariant.secondary
                        : DSButtonVariant.primary,
                expand: true,
                onTap:
                    () => _openContactSheet(extJob.customerContactPlannedFor),
              ),
            ],

            // Step 2: Mark ready for billing
            if (isContacted) ...[
              const SizedBox(height: DSSpacing.s3),
              if (isReadyForBilling)
                _DoneButton(label: 'Faktura sendt')
              else ...[
                if (musicianContactBlocked) ...[
                  LockedInfoBanner(
                    icon: LucideIcons.users,
                    label: musicianContactBlockedMessage(wonExtOffers),
                  ),
                  const SizedBox(height: DSSpacing.s3),
                ],
                DSButton(
                  label: 'Luk aftale og send faktura',
                  variant: DSButtonVariant.primary,
                  expand: true,
                  isLoading: billingLoading,
                  enabled: !musicianContactBlocked,
                  onTap:
                      billingLoading || musicianContactBlocked
                          ? null
                          : _handleReadyForBilling,
                ),
              ],
            ],

            // Step 3: Jeg er klar
            if (isReadyForBilling) ...[
              const SizedBox(height: DSSpacing.s3),
              if (isConfirmedReady)
                _DoneButton(label: 'Jeg er klar!')
              else if (!canConfirmReady)
                LockedInfoBanner(
                  label: 'Du kan bekræfte "Jeg er klar" 5 dage før jobbet.',
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

        // ── Extra hours (DJ-only, post-event window) ─────────────────────
        if (isAssignedDj) ...[
          _ExtJobExtraHoursSection(extJob: extJob),
          _ExtJobEarlySetupSection(extJob: extJob),
          const SizedBox(height: DSSpacing.s4),
        ],

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
        const SizedBox(height: DSSpacing.s4),

        // ── Til festen: inline only when there is no "Stedet" tab ──────────
        if (!showVenueTab) wishesCard,

        // Extra clearance so the floating chat bubble never covers the last card.
        const SizedBox(height: 96),
      ],
    );

    // "Stedet": everything about the venue in one place (address, the team's
    // photos, and the partner booking's wishes), so a DJ preparing for the night
    // does not have to scroll past the process cards to find it.
    final venueTab = ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        if (recurringName != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: RecurringCustomerBadge(name: recurringName),
          ),
          const SizedBox(height: DSSpacing.s4),
        ],
        EventAddressSection(extJobId: extJob.id),
        VenuePhotosCard(photos: venuePhotos),
        wishesCard,
        if (venuePhotos.isEmpty && !wishesCard.hasContent) _VenueEmptyState(),
        const SizedBox(height: 96),
      ],
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom:
              showVenueTab
                  ? const DSTabBar(
                    tabs: [
                      DSTabItem(label: 'Job', icon: LucideIcons.clipboardList),
                      DSTabItem(label: 'Stedet', icon: LucideIcons.mapPin),
                    ],
                  )
                  : null,
        ),
        body: Stack(
          children: [
            showVenueTab ? TabBarView(children: [jobTab, venueTab]) : jobTab,
            // Floating "Beskeder" bubble (mirrors the web app + the musician
            // won-offer view). Self-hides when no conversation exists for this
            // ext job.
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(DSSpacing.s4),
                    child: ChatBubbleFab(extJobId: extJob.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on the "Stedet" tab of a partner booking before the team has uploaded
/// any photos and the booking carries no wishes, so the tab never looks broken.
class _VenueEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.s6),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.camera, size: 28, color: c.text.muted),
          const SizedBox(height: DSSpacing.s3),
          Text(
            'Ingen oplysninger om stedet endnu',
            style: DSTextStyle.labelLg.copyWith(color: c.text.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            'Billeder og noter fra stedet vises her, når DJTILBUD har tilføjet dem.',
            style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
            textAlign: TextAlign.center,
          ),
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
    final dateStr = DateFormat(
      'EEEE d. MMMM yyyy',
      'da_DK',
    ).format(extJob.date);

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
              DSSpacing.s4,
              DSSpacing.s4,
              DSSpacing.s4,
              DSSpacing.s3,
            ),
            child: Text(
              eventTypeLabel(extJob.displayEventType),
              style: DSTextStyle.headingMd.copyWith(color: _c.text.primary),
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
                  value: dateStr,
                ),
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                  icon: LucideIcons.clock,
                  label: 'Tidspunkt',
                  value: extJob.timeDisplay,
                ),
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                  icon: LucideIcons.mapPin,
                  label: 'Lokation',
                  value: extJob.displayLocation,
                ),
                if (extJob.guestsAmount != null) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                    icon: LucideIcons.users,
                    label: 'Gæster',
                    value: '${extJob.guestsAmount}',
                  ),
                ],
                const SizedBox(height: DSSpacing.s3),
                _InfoRow(
                  icon: LucideIcons.banknote,
                  label: 'Honorar',
                  value: extJob.budgetDisplay,
                ),
                if (extJob.requestedMusicianHours != null) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                    icon: LucideIcons.timer,
                    label: 'Spilletid',
                    value: '${extJob.musicianHoursDisplay} timer',
                  ),
                ],
                if (extJob.company != null && extJob.company!.isNotEmpty) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                    icon: LucideIcons.building2,
                    label: 'Virksomhed',
                    value: extJob.company!,
                  ),
                ],
                if (extJob.birthdayPersonAge != null &&
                    extJob.birthdayPersonAge!.isNotEmpty) ...[
                  const SizedBox(height: DSSpacing.s3),
                  _InfoRow(
                    icon: LucideIcons.cake,
                    label: 'Alder (fødselar)',
                    value: extJob.birthdayPersonAge!,
                  ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    extJob.notes!,
                    style: DSTextStyle.bodyMd.copyWith(
                      color: _c.text.secondary,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  CopyHintRow(
                    text: extJob.notes!,
                    copiedTitle: 'Noter kopieret',
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    extJob.musicianSpecialRequest!,
                    style: DSTextStyle.bodyMd.copyWith(
                      color: _c.text.secondary,
                    ),
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
                style: DSTextStyle.labelSm.copyWith(color: _c.text.muted),
              ),
              Text(
                value,
                style: DSTextStyle.bodyMd.copyWith(color: _c.text.primary),
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
        horizontal: DSSpacing.s4,
        vertical: DSSpacing.s3,
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

// ─── Contact Row ──────────────────────────────────────────────────────────────

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

// ─── Song Requests Row ────────────────────────────────────────────────────────

class _ExtJobSongRequestsRow extends ConsumerWidget {
  const _ExtJobSongRequestsRow({required this.extJob});
  final ExtJob extJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final requestsAsync = ref.watch(songRequestsForExtJobProvider(extJob.id));

    final countLabel = requestsAsync.when(
      loading: () => '…',
      error: (_, __) => '—',
      data: (list) => '${list.length}',
    );

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SongRequestsScreen(extJobId: extJob.id),
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

// ─── Ext Job Extra Hours Section ────────────────────────────────────────────
//
// Mirrors the web ext-dj "Ekstra timer" flow (AddExtExtraHours.tsx): the DJ
// registers post-event extra hours + a customer price-per-hour. Saving is
// routed through /api/ext-jobs/{id}/extra-hours, which recomputes `full_amount`
// AND `honorar` server-side — so without this the ext-job invoice would diverge
// from the DJ's "Dit honorar" exactly like the internal-quote bug. We never
// display `full_amount`; only the extra cost and the DJ's payout adjustment
// (the same two numbers the web shows).

class _ExtJobExtraHoursSection extends ConsumerStatefulWidget {
  const _ExtJobExtraHoursSection({required this.extJob});

  final ExtJob extJob;

  @override
  ConsumerState<_ExtJobExtraHoursSection> createState() =>
      _ExtJobExtraHoursSectionState();
}

class _ExtJobExtraHoursSectionState
    extends ConsumerState<_ExtJobExtraHoursSection> {
  DSColors get _c => DSTheme.of(context);
  final _priceController = TextEditingController();
  final _totalController = TextEditingController();
  String _priceMode = 'perHour'; // 'perHour' | 'total'
  double? _selectedHours;
  bool _editing = false;

  // Window: event date (00:00) through end of event date + 2 days (23:59:59).
  bool get _windowOpen {
    final eventDate = widget.extJob.date;
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

  // DJ payout share, mirroring web getFeeForJob: 20% fee (0.80 share) before
  // 2025-10-15 UTC, 25% fee (0.75 share) until 2026-07-06, 28.5% fee (0.715
  // share) on/after. Display-only estimate — authoritative honorar is server-side.
  double get _djPayoutShare {
    final created = widget.extJob.createdAt.toUtc();
    if (created.isBefore(DateTime.utc(2025, 10, 15))) return 0.80;
    if (created.isBefore(DateTime.utc(2026, 7, 6))) return 0.75;
    return 0.715;
  }

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final rate = widget.extJob.extraHoursPricePerHour;
    if (rate != null) {
      _priceController.text = rate.round().toString();
    } else {
      final djProfile = ref.read(djProfileProvider).valueOrNull;
      if (djProfile != null && djProfile.pricePerExtraHour > 0) {
        _priceController.text = djProfile.pricePerExtraHour.toString();
      }
    }
    final eh = widget.extJob.extraHours;
    if (eh != null && rate != null) {
      _totalController.text = (eh * rate).round().toString();
      // A non-whole stored rate means it was entered as a total → default to that mode.
      if (rate != rate.roundToDouble()) _priceMode = 'total';
    }
    _selectedHours = extraHoursSelectedValue(widget.extJob.extraHours);
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
    final fullAmount = widget.extJob.fullAmount;
    if (fullAmount == null || fullAmount <= 0) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Honorar mangler på jobbet. Kontakt support.',
      );
      return;
    }
    // Match the server: strip any existing extra-hours from full_amount to get
    // the base, then add the new extra-hours. Server re-validates this.
    final existingExtra =
        (widget.extJob.extraHours ?? 0) *
        (widget.extJob.extraHoursPricePerHour ?? 0);
    final newTotalPrice = (fullAmount - existingExtra + extraCost).round();

    final ok = await ref
        .read(addExtJobExtraHoursProvider.notifier)
        .add(
          widget.extJob.id,
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
        .read(deleteExtJobExtraHoursProvider.notifier)
        .delete(widget.extJob.id);
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
    final hasHours = widget.extJob.extraHours != null;
    // Window closed + no hours → nothing to show.
    if (!_windowOpen && !hasHours) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Ekstra timer',
      children: [
        // Answered "nej" — nothing left to ask, so the card collapses to the
        // confirmed row (with an undo) instead of showing the form forever.
        if (widget.extJob.extraHoursDeclinedAt != null) ...[
          DeclineExtraHours(
            id: widget.extJob.id,
            target: ExtraHoursDeclineTarget.extJob,
            declinedAt: widget.extJob.extraHoursDeclinedAt,
          ),
        ] else if (!_windowOpen && hasHours) ...[
          _ExtJobExtraHoursSummary(
            hours: widget.extJob.extraHours!,
            pricePerHour: widget.extJob.extraHoursPricePerHour!,
            payoutShare: _djPayoutShare,
          ),
        ] else if (_windowOpen && hasHours && !_editing) ...[
          _ExtJobExtraHoursSummary(
            hours: widget.extJob.extraHours!,
            pricePerHour: widget.extJob.extraHoursPricePerHour!,
            payoutShare: _djPayoutShare,
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
              Expanded(child: _ExtJobDeleteButton(onTap: _delete)),
            ],
          ),
        ] else if (_windowOpen && (!hasHours || _editing)) ...[
          Text(
            'Spillede du flere timer end aftalt? Registrér dem her — vi '
            'fakturerer kunden, og din betaling justeres tilsvarende.',
            style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s3),
          // Only while nothing is logged: "no extra hours" contradicts a saved
          // amount, and the server rejects that combination too.
          if (!hasHours) ...[
            DeclineExtraHours(
              id: widget.extJob.id,
              target: ExtraHoursDeclineTarget.extJob,
              declinedAt: widget.extJob.extraHoursDeclinedAt,
            ),
            const SizedBox(height: DSSpacing.s3),
          ],
          HoursPickerField(
            value: _selectedHours,
            onChanged: (v) => setState(() => _selectedHours = v),
          ),
          const SizedBox(height: DSSpacing.s3),
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
              final isLoading =
                  ref.watch(addExtJobExtraHoursProvider) is AsyncLoading;
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
    );
  }
}

class _ExtJobExtraHoursSummary extends StatelessWidget {
  const _ExtJobExtraHoursSummary({
    required this.hours,
    required this.pricePerHour,
    required this.payoutShare,
  });

  final double hours;
  final num pricePerHour;
  final double payoutShare;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final hoursLabel =
        hours == hours.truncateToDouble()
            ? '${hours.toInt()} timer'
            : '$hours timer';
    final extraCost = (hours * pricePerHour).round();
    final payoutDelta = (extraCost * payoutShare).round();
    return Column(
      children: [
        _ExtJobSummaryRow(label: 'Timer', value: hoursLabel),
        _ExtJobSummaryRow(
          label: 'Pris pr. time',
          value: '${pricePerHour.round()} kr.',
        ),
        _ExtJobSummaryRow(label: 'Ekstra omkostning', value: '+$extraCost kr.'),
        Divider(height: 16, color: c.border.subtle),
        _ExtJobSummaryRow(
          label: 'Justering af din betaling',
          value: '+$payoutDelta kr.',
          bold: true,
          valueColor: c.state.success,
        ),
      ],
    );
  }
}

class _ExtJobSummaryRow extends StatelessWidget {
  const _ExtJobSummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DSTextStyle.labelMd.copyWith(color: c.text.muted)),
          Text(
            value,
            style: DSTextStyle.labelMd.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? c.text.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtJobDeleteButton extends ConsumerWidget {
  const _ExtJobDeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final isLoading = ref.watch(deleteExtJobExtraHoursProvider) is AsyncLoading;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.state.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.state.danger.withValues(alpha: 0.50)),
        ),
        child: Text(
          isLoading ? 'Sletter...' : 'Slet',
          style: DSTextStyle.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: c.state.danger,
          ),
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

/// Shown when an ext job has been canceled — it can still be reached via a stale notification,
/// so make the canceled state unmistakable rather than rendering it as an active job.
class _CanceledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DSSpacing.s3),
      decoration: BoxDecoration(
        color: c.state.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: c.state.danger.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.ban, size: 16, color: c.state.danger),
          const SizedBox(width: DSSpacing.s2),
          Expanded(
            child: Text(
              'Dette job er blevet aflyst.',
              style: DSTextStyle.bodySm.copyWith(
                color: c.text.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Early setup on an ext job. Mirrors the web `AddExtEarlySetup.tsx` flow: the DJ
// adds an agreed early-setup fee (+ optional start time) and the server folds it
// into full_amount + honorar.
//
// Deliberately NO approval step (unlike internal quotes' early_setup_status):
// ExtJobs has no status column, and the product decision is that the DJ and admin
// both simply add it.
//
// Two differences from the extra-hours section above, both intentional:
//  * The WINDOW is wider. Extra hours can only be logged on/after the event (they
//    record what happened on the night); early setup is agreed IN ADVANCE, so it is
//    editable any time up to 2 days after the event.
//  * The PAYOUT SHARE has only two brackets (0.75 / 0.715), matching the server's
//    `extDjPayoutShare`. The extra-hours section above uses the three-bracket
//    internal `getFeeForJob` ladder, which does not apply to ext jobs.
// ---------------------------------------------------------------------------
class _ExtJobEarlySetupSection extends ConsumerStatefulWidget {
  const _ExtJobEarlySetupSection({required this.extJob});

  final ExtJob extJob;

  @override
  ConsumerState<_ExtJobEarlySetupSection> createState() =>
      _ExtJobEarlySetupSectionState();
}

class _ExtJobEarlySetupSectionState
    extends ConsumerState<_ExtJobEarlySetupSection> {
  DSColors get _c => DSTheme.of(context);
  final _priceController = TextEditingController();
  TimeOfDay? _time;
  bool _editing = false;

  bool get _hasEarlySetup =>
      widget.extJob.earlySetupPrice != null &&
      widget.extJob.earlySetupPrice! > 0;

  /// Open until the end of event date + 2 days. No lower bound: early setup is
  /// agreed before the event. Mirrors `isBeforeBillingCutoff` on the server.
  bool get _windowOpen {
    final d = widget.extJob.date;
    final cutoff = DateTime(d.year, d.month, d.day + 2, 23, 59, 59);
    return DateTime.now().isBefore(cutoff);
  }

  /// Server mirror of `extDjPayoutShare`. Display-only estimate; the authoritative
  /// honorar comes back from the API.
  double get _djPayoutShare =>
      widget.extJob.createdAt.toUtc().isBefore(DateTime.utc(2026, 7, 6))
          ? 0.75
          : 0.715;

  @override
  void initState() {
    super.initState();
    final price = widget.extJob.earlySetupPrice;
    if (price != null) _priceController.text = price.round().toString();
    _time = _parseNoteTime(widget.extJob.notes);
  }

  /// The early-setup TIME lives as a marked line inside `notes`, not a column.
  /// Mirrors `readEarlySetupNoteTime` in the web-app.
  static TimeOfDay? _parseNoteTime(String? notes) {
    if (notes == null) return null;
    for (final line in notes.split('\n')) {
      if (!line.trimLeft().startsWith('Tidlig opsætning:')) continue;
      final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line);
      if (m == null) return null;
      return TimeOfDay(
        hour: int.parse(m.group(1)!),
        minute: int.parse(m.group(2)!),
      );
    }
    return null;
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Angiv en pris for tidlig opsætning.',
      );
      return;
    }

    final ok = await ref
        .read(setExtJobEarlySetupProvider.notifier)
        .set(
          widget.extJob.id,
          price: price,
          time: _time == null ? null : _formatTime(_time!),
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Tidlig opsætning gemt',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke gemme tidlig opsætning. Prøv igen.',
      );
    }
  }

  Future<void> _delete() async {
    final ok = await ref
        .read(deleteExtJobEarlySetupProvider.notifier)
        .delete(widget.extJob.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _editing = false;
        _time = null;
        _priceController.clear();
      });
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Tidlig opsætning fjernet',
      );
    } else {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Kunne ikke fjerne tidlig opsætning. Prøv igen.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_windowOpen && !_hasEarlySetup) return const SizedBox.shrink();

    // ⚠️ A recurring-customer (partner-portal) booking is priced by the venue's
    // agreement, so the DJ may not add or change early setup - the server 403s. Show an
    // already-agreed fee read-only (admin may have added one); otherwise hide the whole
    // section rather than render a control that always fails.
    if (widget.extJob.isRecurringCustomer) {
      if (!_hasEarlySetup) return const SizedBox.shrink();
      return _SectionCard(
        title: 'Tidlig opsætning',
        children: [
          _ExtJobEarlySetupSummary(
            price: widget.extJob.earlySetupPrice!,
            time: _time == null ? null : _formatTime(_time!),
            payoutShare: _djPayoutShare,
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            'Dette er en fast kunde, så tidlig opsætning aftales gennem DJTILBUD.',
            style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
          ),
        ],
      );
    }

    return _SectionCard(
      title: 'Tidlig opsætning',
      children: [
        if (!_editing && _hasEarlySetup) ...[
          _ExtJobEarlySetupSummary(
            price: widget.extJob.earlySetupPrice!,
            time: _time == null ? null : _formatTime(_time!),
            payoutShare: _djPayoutShare,
          ),
          if (_windowOpen) ...[
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
                Expanded(child: _ExtJobDeleteButton(onTap: _delete)),
              ],
            ),
          ],
        ] else ...[
          Text(
            'Har du aftalt tidlig opsætning med kunden? Tilføj prisen her — vi '
            'fakturerer kunden, og din betaling justeres tilsvarende.',
            style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            label: 'Pris for tidlig opsætning (DKK)',
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: DSSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  _time == null
                      ? 'Hvornår sætter du op? (valgfrit)'
                      : 'Opsætning fra kl. ${_formatTime(_time!)}',
                  style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                ),
              ),
              const SizedBox(width: DSSpacing.s2),
              DSButton(
                label: _time == null ? 'Vælg tid' : 'Skift',
                variant: DSButtonVariant.secondary,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time ?? const TimeOfDay(hour: 16, minute: 0),
                  );
                  if (picked != null) setState(() => _time = picked);
                },
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s3),
          Consumer(
            builder: (context, ref, _) {
              final isLoading =
                  ref.watch(setExtJobEarlySetupProvider) is AsyncLoading;
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
                      label: isLoading ? 'Gemmer...' : 'Gem tidlig opsætning',
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
    );
  }
}

class _ExtJobEarlySetupSummary extends StatelessWidget {
  const _ExtJobEarlySetupSummary({
    required this.price,
    required this.time,
    required this.payoutShare,
  });

  final num price;
  final String? time;
  final double payoutShare;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final payoutDelta = (price * payoutShare).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time == null
              ? 'Tidlig opsætning: +${price.round()} kr.'
              : 'Tidlig opsætning fra kl. $time: +${price.round()} kr.',
          style: DSTextStyle.labelMd.copyWith(color: c.text.primary),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          'Din betaling er justeret med +$payoutDelta kr.',
          style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
        ),
      ],
    );
  }
}
