import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

/// Wraps the authed shell and shows the mandatory "Accepter vilkår for selvfakturering" popup
/// when [needsSelfBillingTermsProvider] says so: the `self_billing_live` flag is on, the saved
/// payment type is Faktura and the terms are not accepted yet.
///
/// Mirrors web `SelfBillingTermsModal` (same copy; change both together): no close button, no
/// barrier tap, no back gesture. Accepting goes through the web-app endpoint
/// `POST /api/self-billing/accept-terms`, the only writer of `self_billing_terms_accepted_at`.
class SelfBillingTermsGate extends ConsumerStatefulWidget {
  const SelfBillingTermsGate({
    super.key,
    required this.isDj,
    required this.child,
  });

  final bool isDj;
  final Widget child;

  @override
  ConsumerState<SelfBillingTermsGate> createState() =>
      _SelfBillingTermsGateState();
}

class _SelfBillingTermsGateState extends ConsumerState<SelfBillingTermsGate> {
  bool _showing = false;

  void _maybeShow(bool needs) {
    if (!needs || _showing) return;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TermsDialog(isDj: widget.isDj),
      );
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final needs = ref.watch(needsSelfBillingTermsProvider(widget.isDj));
    _maybeShow(needs);
    return widget.child;
  }
}

class _TermsDialog extends ConsumerStatefulWidget {
  const _TermsDialog({required this.isDj});

  final bool isDj;

  @override
  ConsumerState<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends ConsumerState<_TermsDialog> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(profileRepositoryProvider).acceptSelfBillingTerms();
      ref.invalidate(
        widget.isDj ? djPaymentInfoProvider : musicianPaymentInfoProvider,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _accepting = false);
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Vilkårene kunne ikke accepteres. Prøv igen.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final body = DSTextStyle.bodyMd.copyWith(color: c.text.secondary);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: c.bg.surface,
        title: Text(
          'Accepter vilkår for selvfakturering',
          style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Da du fakturerer, udsteder DJTILBUD en afregning (selvfakturering) på dine vegne '
                'jf. handelsbetingelserne, i stedet for at du selv sender en faktura.',
                style: body,
              ),
              const SizedBox(height: DSSpacing.s3),
              Text(
                'Beløbet beregnes automatisk og overføres til din bankkonto. Du modtager altid en '
                'kopi af bilaget og har mulighed for at gøre indsigelse, inden det anses for godkendt.',
                style: body,
              ),
              const SizedBox(height: DSSpacing.s3),
              Text(
                'Du skal acceptere vilkårene for at kunne fortsætte med fakturering. '
                'Se uddybende besked under "Beskeder".',
                style: body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          DSButton(
            label: 'Jeg accepterer vilkårene',
            expand: true,
            isLoading: _accepting,
            onTap: _accepting ? null : _accept,
          ),
        ],
      ),
    );
  }
}
