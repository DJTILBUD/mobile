import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/error/app_exception.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// "Jeg spillede ikke ekstra timer" — lets the performer close the extra-hours
/// question with a NO instead of leaving it open on every job.
///
/// Reported by a DJ: *"når man skal vælge ekstra timer, skal der være en
/// mulighed for at sige 'Jeg spillede ikke ekstra timer' på en CTA, så man ikke
/// får notifikationer om det."* Most nights have no extra hours, and the only
/// ways out were to log hours or ignore both the card and the day-after
/// "Spillede du ekstra i går?" push forever.
///
/// The answer is stored SERVER-side (`extra_hours_declined_at` on the payee row,
/// via `PUT .../extra-hours/declined`), which is what makes it stop the push and
/// carry over to the web app — a local dismissal could do neither. Web renders
/// the same two states in `src/components/DeclineExtraHours.tsx`; keep them in
/// step.
///
/// Two states: the CTA, and (once declined) a confirmed row with **Fortryd**.
/// Callers decide *whether* to show it — only offer it while no hours are
/// logged, since the server rejects that contradiction.
class DeclineExtraHours extends ConsumerWidget {
  const DeclineExtraHours({
    super.key,
    required this.id,
    required this.target,
    required this.declinedAt,
  });

  /// Quote id / ext job id / service offer id, matching [target].
  final int id;
  final ExtraHoursDeclineTarget target;
  final DateTime? declinedAt;

  bool get _declined => declinedAt != null;

  Future<void> _set(BuildContext context, WidgetRef ref, bool declined) async {
    final ok = await ref
        .read(declineExtraHoursProvider.notifier)
        .setDeclined(id, declined: declined, target: target);
    if (!context.mounted) return;
    if (ok) {
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title:
            declined
                ? 'Noteret — ingen ekstra timer'
                : 'Du kan tilføje ekstra timer igen',
      );
      return;
    }
    // The route authors its rejections as user-facing Danish (e.g. "Du har
    // allerede registreret ekstra timer"), so show it rather than a generic
    // toast — the DJ otherwise cannot tell why the button did nothing.
    final err = ref.read(declineExtraHoursProvider).error;
    DSToast.show(
      context,
      variant: DSToastVariant.error,
      title:
          err is AppException && err.message.isNotEmpty
              ? err.message
              : 'Noget gik galt. Prøv igen.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final isLoading = ref.watch(declineExtraHoursProvider) is AsyncLoading;

    if (_declined) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DSSpacing.s3),
        decoration: BoxDecoration(
          color: c.bg.inputBg,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: c.border.subtle),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.check, size: 16, color: c.text.muted),
            const SizedBox(width: DSSpacing.s2),
            Expanded(
              child: Text(
                'Ingen ekstra timer. Vi minder dig ikke om det igen.',
                style: DSTextStyle.labelMd.copyWith(color: c.text.secondary),
              ),
            ),
            const SizedBox(width: DSSpacing.s2),
            DSButton(
              label: 'Fortryd',
              variant: DSButtonVariant.ghost,
              size: DSButtonSize.sm,
              isLoading: isLoading,
              onTap: isLoading ? null : () => _set(context, ref, false),
            ),
          ],
        ),
      );
    }

    return DSButton(
      label: 'Jeg spillede ikke ekstra timer',
      variant: DSButtonVariant.secondary,
      expand: true,
      isLoading: isLoading,
      onTap: isLoading ? null : () => _set(context, ref, true),
    );
  }
}
