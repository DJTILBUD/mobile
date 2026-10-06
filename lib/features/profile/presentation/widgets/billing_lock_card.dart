import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/error_messages.dart';
import 'package:dj_tilbud_app/features/profile/domain/entities/billing_change_request.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';

/// Billing lock status on the payment screen (web-app/documentation/billing-lock-plan.md).
///
/// Locked: explains the lock and lets the performer ask support for a change.
/// Unlocked after an approval: tells them they can edit, and that the next save
/// locks it again. Renders nothing when unlocked with no approved request.
class BillingLockCard extends ConsumerWidget {
  const BillingLockCard({super.key, required this.lockedAt});

  final DateTime? lockedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    // A failed fetch still lets the performer send a request (the server
    // rejects a duplicate with a Danish message).
    final request = ref.watch(billingChangeRequestProvider).valueOrNull;

    if (lockedAt == null) {
      if (request?.status != BillingChangeRequestStatus.approved) {
        return const SizedBox.shrink();
      }
      return _Panel(
        color: c.state.success,
        icon: LucideIcons.unlock,
        title: 'Du kan nu rette dine betalingsoplysninger',
        children: [
          _body(
            context,
            'Support har godkendt din anmodning. Når du gemmer komplette oplysninger, bliver de låst igen.',
          ),
          if (_hasNote(request))
            _body(context, 'Besked fra support: ${request!.adminNote}'),
        ],
      );
    }

    final pending = request?.status == BillingChangeRequestStatus.pending;
    final rejected = request?.status == BillingChangeRequestStatus.rejected;
    return _Panel(
      color: c.state.info,
      icon: LucideIcons.lock,
      title: 'Dine betalingsoplysninger er låst',
      children: [
        _body(
          context,
          'Låst siden ${DateFormat('dd.MM.yyyy').format(lockedAt!)}. '
          'Skal noget ændres, sender du en anmodning til support.',
        ),
        if (pending) ...[
          DSStatusBadge(label: 'Afventer support', color: c.state.warning),
          _body(context, 'Din anmodning: ${request!.reason}'),
        ],
        if (rejected) ...[
          _body(context, 'Support har afvist din seneste anmodning.'),
          if (_hasNote(request))
            _body(context, 'Besked fra support: ${request!.adminNote}'),
        ],
        if (!pending)
          DSButton(
            label: 'Anmod om ændring',
            variant: DSButtonVariant.secondary,
            size: DSButtonSize.md,
            iconLeft: LucideIcons.send,
            onTap: () => _openRequestDialog(context, ref),
          ),
      ],
    );
  }

  bool _hasNote(BillingChangeRequest? r) =>
      r?.adminNote != null && r!.adminNote!.trim().isNotEmpty;

  Widget _body(BuildContext context, String text) {
    final c = DSTheme.of(context);
    return Text(
      text,
      style: DSTextStyle.bodySm.copyWith(color: c.text.secondary),
    );
  }

  Future<void> _openRequestDialog(BuildContext context, WidgetRef ref) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => const _RequestChangeDialog(),
    );
    if (sent == true) ref.invalidate(billingChangeRequestProvider);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.icon,
    required this.title,
    required this.children,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.s6),
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: DSSpacing.s2),
              Expanded(
                child: Text(
                  title,
                  style: DSTextStyle.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.text.primary,
                  ),
                ),
              ),
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: DSSpacing.s3),
            child,
          ],
        ],
      ),
    );
  }
}

/// Reason form for a change request. Pops `true` once the request is sent.
class _RequestChangeDialog extends ConsumerStatefulWidget {
  const _RequestChangeDialog();

  @override
  ConsumerState<_RequestChangeDialog> createState() =>
      _RequestChangeDialogState();
}

class _RequestChangeDialogState extends ConsumerState<_RequestChangeDialog> {
  final _reasonCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Skriv kort, hvad der skal ændres og hvorfor.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .createBillingChangeRequest(reason);
      if (!mounted) return;
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Anmodningen er sendt til support',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = friendlyErrorMessage(
          e,
          fallback: 'Anmodningen kunne ikke sendes. Prøv igen.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DSDialog(
      title: 'Anmod om ændring',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fortæl support, hvad der skal ændres, fx nyt kontonummer eller nyt CVR. '
            'Når support har godkendt, kan du rette oplysningerne her.',
            style: DSTextStyle.bodySm.copyWith(
              color: DSTheme.of(context).text.secondary,
            ),
          ),
          const SizedBox(height: DSSpacing.s3),
          DSInput(
            controller: _reasonCtrl,
            label: 'Hvad skal ændres?',
            maxLines: 4,
            minLines: 3,
            errorText: _error,
            enabled: !_sending,
          ),
        ],
      ),
      actions: [
        DSButton(
          label: 'Annuller',
          variant: DSButtonVariant.ghost,
          size: DSButtonSize.sm,
          onTap: _sending ? null : () => Navigator.of(context).pop(false),
        ),
        DSButton(
          label: 'Send anmodning',
          size: DSButtonSize.sm,
          isLoading: _sending,
          onTap: _sending ? null : _send,
        ),
      ],
    );
  }
}
