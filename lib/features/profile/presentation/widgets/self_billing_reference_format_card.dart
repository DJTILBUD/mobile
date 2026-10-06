import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/profile/domain/self_billing_reference_format.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

/// "Din egen reference på afregningen" on the payment screen. Mirrors the web-app
/// `SelfBillingReferenceFormatCard`: rendered outside the locked form with its
/// own save, because the setting is deliberately not billing-locked
/// (web-app/documentation/self-billing-supplier-reference-plan.md).
class SelfBillingReferenceFormatCard extends ConsumerStatefulWidget {
  const SelfBillingReferenceFormatCard({
    super.key,
    required this.isDj,
    required this.savedFormat,
  });

  final bool isDj;
  final SelfBillingReferenceFormat savedFormat;

  @override
  ConsumerState<SelfBillingReferenceFormatCard> createState() =>
      _SelfBillingReferenceFormatCardState();
}

class _SelfBillingReferenceFormatCardState
    extends ConsumerState<SelfBillingReferenceFormatCard> {
  late SelfBillingReferenceFormat _format = widget.savedFormat;
  bool _saving = false;

  @override
  void didUpdateWidget(SelfBillingReferenceFormatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow a freshly loaded saved value.
    if (oldWidget.savedFormat != widget.savedFormat) {
      _format = widget.savedFormat;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveSelfBillingReferenceFormat(
            userId: supabase.auth.currentUser!.id,
            isDj: widget.isDj,
            format: _format,
          );
      ref.invalidate(
        widget.isDj ? djPaymentInfoProvider : musicianPaymentInfoProvider,
      );
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.success,
          title: 'Nummerformat gemt',
        );
      }
    } catch (e) {
      if (mounted) {
        DSToast.show(
          context,
          variant: DSToastVariant.error,
          title: friendlyErrorMessage(
            e,
            fallback: 'Kunne ikke gemme nummerformatet. Prøv igen.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Din egen reference på afregningen',
          style: DSTextStyle.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: c.text.primary,
          ),
        ),
        const SizedBox(height: DSSpacing.s1),
        Text(
          'Bruger du din egen nummerering i dit regnskab, kan den stå som din reference på hver afregning, '
          'ved siden af vores afregningsnr. Det gælder for afregninger, der udstedes '
          'efter du har gemt.',
          style: DSTextStyle.bodySm.copyWith(color: c.text.muted),
        ),
        const SizedBox(height: DSSpacing.s3),
        for (final option in SelfBillingReferenceFormat.values)
          DSRadio(
            label: option.label,
            hint: option.description,
            value: option.dbValue,
            groupValue: _format.dbValue,
            onChanged:
                _saving
                    ? null
                    : (v) => setState(
                      () => _format = SelfBillingReferenceFormat.fromDb(v),
                    ),
          ),
        if (_format != widget.savedFormat) ...[
          const SizedBox(height: DSSpacing.s4),
          DSButton(
            label: 'Gem nummerformat',
            expand: true,
            isLoading: _saving,
            onTap: _saving ? null : _save,
          ),
        ],
      ],
    );
  }
}
