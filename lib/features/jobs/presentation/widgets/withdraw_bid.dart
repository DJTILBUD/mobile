import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/bid_withdrawal.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// Shared "Træk bud tilbage" flow for both roles: confirm, call the web route,
/// toast the server's own Danish message and leave the screen (the bid row is
/// deleted, so there is nothing left to show).
///
/// Server rejections (`withdraw_window_expired`, `bid_not_pending`, 403/404)
/// carry user-facing Danish text, so the toast shows `result.message` directly
/// instead of going through `friendlyErrorMessage`, which would hide it.
Future<bool> confirmAndWithdrawBid(
  BuildContext context, {
  required String title,
  required String message,
  required String fallbackSuccess,
  required String homeRoute,
  required Future<WithdrawBidResult> Function() withdraw,
}) async {
  final confirmed = await showDSConfirm(
    context,
    title: title,
    message: message,
    confirmLabel: 'Træk tilbage',
    cancelLabel: 'Annuller',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;

  final result = await withdraw();
  if (!context.mounted) return result.success;

  if (!result.success) {
    DSToast.show(
      context,
      variant: DSToastVariant.error,
      title:
          result.message.isNotEmpty
              ? result.message
              : 'Noget gik galt. Prøv igen.',
    );
    return false;
  }

  DSToast.show(
    context,
    variant: DSToastVariant.success,
    title: result.message.isNotEmpty ? result.message : fallbackSuccess,
  );
  // A cold-start deep link can land here with nothing underneath.
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(homeRoute);
  }
  return true;
}

/// Sax offer: live "mm:ss" countdown + "Træk tilbud tilbage" button while the
/// 10-minute window is open. Hides itself once the window has passed (the
/// server is the authority; this only decides visibility).
// @uxid lib/features/jobs/presentation/widgets/withdraw_bid.dart::WithdrawOfferCountdownCard
class WithdrawOfferCountdownCard extends StatefulWidget {
  const WithdrawOfferCountdownCard({
    super.key,
    required this.createdAt,
    required this.isLoading,
    required this.onWithdraw,
  });

  final DateTime createdAt;
  final bool isLoading;
  final VoidCallback onWithdraw;

  @override
  State<WithdrawOfferCountdownCard> createState() =>
      _WithdrawOfferCountdownCardState();
}

class _WithdrawOfferCountdownCardState
    extends State<WithdrawOfferCountdownCard> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = bidWithdrawSecondsLeft(widget.createdAt);
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted) return;
    final left = bidWithdrawSecondsLeft(widget.createdAt);
    setState(() => _secondsLeft = left);
    if (left <= 0) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0 || !isWithinBidWithdrawWindow(widget.createdAt)) {
      return const SizedBox.shrink();
    }
    final c = DSTheme.of(context);
    final countdown = formatBidWithdrawCountdown(_secondsLeft);
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: c.state.info.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DSRadius.sm),
          border: Border.all(color: c.state.info.withValues(alpha: 0.40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.timer, size: 16, color: c.fg(c.state.info)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Du kan trække tilbuddet tilbage i $countdown endnu',
                    style: DSTextStyle.labelMd.copyWith(color: c.text.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.s2),
            DSButton(
              label: 'Træk tilbud tilbage',
              variant: DSButtonVariant.danger,
              size: DSButtonSize.sm,
              iconLeft: LucideIcons.undo2,
              isLoading: widget.isLoading,
              onTap: widget.isLoading ? null : widget.onWithdraw,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small chip on the list cards (`QuoteCard`, `ServiceOfferCard`) while an open
/// bid is inside its 10-minute window, so the performer sees it without opening
/// every bid. Ticks every second and removes itself (incl. its bottom gap) when
/// the window ends.
// @uxid lib/features/jobs/presentation/widgets/withdraw_bid.dart::BidWindowChip
class BidWindowChip extends StatefulWidget {
  const BidWindowChip({super.key, required this.createdAt, required this.label});

  final DateTime createdAt;

  /// DJ: "Redigeringsvindue aktivt", sax: "Kan trækkes tilbage".
  final String label;

  @override
  State<BidWindowChip> createState() => _BidWindowChipState();
}

class _BidWindowChipState extends State<BidWindowChip> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = bidWithdrawSecondsLeft(widget.createdAt);
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = bidWithdrawSecondsLeft(widget.createdAt);
        setState(() => _secondsLeft = left);
        if (left <= 0) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) return const SizedBox.shrink();
    final c = DSTheme.of(context);
    final color = c.fg(c.state.info);
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.s2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.state.info.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(color: c.state.info.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.timer, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              '${widget.label} · ${formatBidWithdrawCountdown(_secondsLeft)}',
              style: DSTextStyle.labelSm.copyWith(
                color: c.text.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
