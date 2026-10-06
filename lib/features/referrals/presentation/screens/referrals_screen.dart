import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/referrals/domain/entities/referral.dart';
import 'package:dj_tilbud_app/features/referrals/domain/referral_labels.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/providers/referrals_provider.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/widgets/referral_card.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/widgets/referral_form.dart';
import 'package:dj_tilbud_app/features/referrals/presentation/widgets/referral_success_overlay.dart';

/// "Henvis en kunde" ("Henvis en kunde til os"). Two tabs, mirroring web `ReferralsPage.tsx`'s
/// two sections: "Ny henvisning" (the form) and "Mine henvisninger" (the performer's own
/// referrals with the job's state). Same screen for both roles (the role is resolved
/// server-side from the token; it only shapes copy here).
///
/// A plain [ConsumerStatefulWidget] (not [DefaultTabController]) on purpose: submitting the form
/// needs to programmatically switch to the "Mine henvisninger" tab afterwards, which requires
/// holding the [TabController] ourselves rather than reaching for an implicit one.
class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _submit(ReferralInput input) async {
    final ok = await ref.read(createReferralProvider.notifier).submit(input);
    if (!mounted) return ok;
    if (ok) {
      // A toast alone disappears too fast, and the tab is about to switch under the user's
      // feet — the overlay is the one beat that confirms "that worked" before the view changes.
      // The referrals list was already invalidated inside submit(), so by the time the user
      // lands on "Mine henvisninger" it refetches with the new referral included.
      await showReferralSuccessOverlay(context);
      if (!mounted) return ok;
      _tabController.animateTo(1);
    } else {
      final err = ref.read(createReferralProvider).error;
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Henvisningen blev ikke sendt',
        description:
            _serverMessage(err) ??
            friendlyErrorMessage(err, fallback: 'Prøv igen om lidt.'),
      );
    }
    return ok;
  }

  // The route's rejections are Danish and user-facing (a validation reason, "Kun DJs og
  // musikere kan henvise jobs."), so show them verbatim. `friendlyErrorMessage` deliberately
  // suppresses DatabaseException text (see mobile CLAUDE.md), so read `.message` directly.
  static String? _serverMessage(Object? err) {
    if (err is! DatabaseException) return null;
    final m = err.message.trim();
    return m.isEmpty ? null : m;
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    // The referral terms must be accepted before the form and the list show (web does the same;
    // POST /api/referrals enforces it server-side too).
    final termsAsync = ref.watch(referralTermsProvider);
    final accepted = termsAsync.valueOrNull?.accepted ?? false;

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        title: Text(
          'Henvis en kunde',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        bottom:
            accepted
                ? DSTabBar(
                  controller: _tabController,
                  tabs: const [
                    DSTabItem(label: 'Ny henvisning', icon: LucideIcons.plus),
                    DSTabItem(
                      label: 'Mine henvisninger',
                      icon: LucideIcons.list,
                    ),
                  ],
                )
                : null,
      ),
      body: termsAsync.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(color: c.brand.primary),
            ),
        error:
            (e, _) => _TermsLoadError(
              onRetry: () => ref.invalidate(referralTermsProvider),
            ),
        data:
            (terms) =>
                terms.accepted
                    ? TabBarView(
                      controller: _tabController,
                      children: [
                        _NewReferralTab(role: widget.role, onSubmit: _submit),
                        const _MyReferralsTab(),
                      ],
                    )
                    : _ReferralTermsGate(termsUrl: terms.termsUrl),
      ),
    );
  }
}

class _NewReferralTab extends ConsumerWidget {
  const _NewReferralTab({required this.role, required this.onSubmit});

  final MusicianRole role;
  final Future<bool> Function(ReferralInput input) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final isSubmitting = ref.watch(createReferralProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        Text(
          'Henvis en kunde til os',
          style: DSTextStyle.headingLg.copyWith(
            fontWeight: FontWeight.w700,
            color: c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s2),
        // Bold and up front on purpose — a performer opening this tab should see the reward in
        // one glance, not buried in a paragraph.
        Text(
          'Tjen $referralRewardDkk kr., når jobbet er gennemført.',
          style: DSTextStyle.bodyLg.copyWith(
            fontWeight: FontWeight.w700,
            color: c.brand.primaryActive,
          ),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          'Har du fået en forespørgsel, du ikke selv kan tage? Giv jobbet videre her. Vi kontakter '
          'kunden og finder en performer. Når arrangementet er afholdt, sender du en faktura på '
          'beløbet til regnskab@djtilbud.dk, så udbetaler vi det.',
          style: DSTextStyle.bodyMd.copyWith(
            color: c.text.secondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: DSSpacing.s6),
        ReferralForm(isSubmitting: isSubmitting, onSubmit: onSubmit),
        const SizedBox(height: DSSpacing.s8),
      ],
    );
  }
}

class _MyReferralsTab extends ConsumerWidget {
  const _MyReferralsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final referrals = ref.watch(referralsProvider);

    return RefreshIndicator(
      color: c.brand.primary,
      onRefresh: () => ref.refresh(referralsProvider.future),
      child: referrals.when(
        // RefreshIndicator requires a Scrollable descendant, so even the loading state is a
        // (physics-forced-scrollable) ListView, not a bare Center.
        loading:
            () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.all(DSSpacing.s8),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
        error:
            (e, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(DSSpacing.s4),
              children: [
                _Note(
                  icon: LucideIcons.alertCircle,
                  text: friendlyErrorMessage(
                    e,
                    fallback: 'Kunne ikke hente dine henvisninger.',
                  ),
                ),
              ],
            ),
        data:
            (items) =>
                items.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(DSSpacing.s4),
                      children: const [
                        _Note(
                          icon: LucideIcons.inbox,
                          text: 'Du har ikke givet nogen jobs videre endnu.',
                        ),
                      ],
                    )
                    : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(DSSpacing.s4),
                      children: [
                        for (final r in items) ...[
                          ReferralCard(referral: r),
                          const SizedBox(height: DSSpacing.s3),
                        ],
                      ],
                    ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: c.text.muted),
        const SizedBox(width: DSSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
          ),
        ),
      ],
    );
  }
}

/// Shown until the performer has accepted the referral terms: a link to the terms and an accept
/// button. Mirrors the web card in `ReferralsPage.tsx` (same copy).
class _ReferralTermsGate extends ConsumerStatefulWidget {
  const _ReferralTermsGate({required this.termsUrl});

  final String termsUrl;

  @override
  ConsumerState<_ReferralTermsGate> createState() => _ReferralTermsGateState();
}

class _ReferralTermsGateState extends ConsumerState<_ReferralTermsGate> {
  bool _accepting = false;
  bool _ticked = false;

  Future<void> _openTerms() async {
    final ok = await launchUrl(
      Uri.parse(widget.termsUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      DSToast.show(
        context,
        variant: DSToastVariant.error,
        title: 'Vilkårene kunne ikke åbnes',
        description: widget.termsUrl,
      );
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(referralsRepositoryProvider).acceptReferralTerms();
      ref.invalidate(referralTermsProvider);
    } catch (e) {
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Vilkårene kunne ikke gemmes. Prøv igen.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(DSSpacing.s4),
      children: [
        Text(
          'Vilkår for henvisninger',
          style: DSTextStyle.headingLg.copyWith(
            fontWeight: FontWeight.w700,
            color: c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s2),
        Text(
          'Før du kan henvise kunder til os, skal du læse og acceptere vilkårene for '
          'henvisninger. Her kan du se, hvornår du får beløbet, og hvilke momsregler der gælder.',
          style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
        ),
        const SizedBox(height: DSSpacing.s4),
        DSButton(
          label: 'Læs vilkårene for henvisninger',
          variant: DSButtonVariant.secondary,
          expand: true,
          iconLeft: LucideIcons.externalLink,
          onTap: _openTerms,
        ),
        const SizedBox(height: DSSpacing.s3),
        DSCheckbox(
          label: 'Jeg har læst vilkårene for henvisninger',
          value: _ticked,
          onChanged: (v) => setState(() => _ticked = v),
        ),
        const SizedBox(height: DSSpacing.s3),
        DSButton(
          label: 'Jeg har læst og accepterer vilkårene',
          expand: true,
          // Greyed out (not just inert) until the box is ticked.
          enabled: _ticked,
          isLoading: _accepting,
          onTap: _accept,
        ),
      ],
    );
  }
}

class _TermsLoadError extends StatelessWidget {
  const _TermsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vi kunne ikke tjekke, om du har accepteret vilkårene for henvisninger.',
              textAlign: TextAlign.center,
              style: DSTextStyle.bodyMd.copyWith(color: c.text.secondary),
            ),
            const SizedBox(height: DSSpacing.s4),
            DSButton(label: 'Prøv igen', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}
