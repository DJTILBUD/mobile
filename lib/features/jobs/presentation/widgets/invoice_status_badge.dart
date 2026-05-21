import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// Shows whether the customer has confirmed the deal (paid first invoice).
/// Mirrors the web app's InvoiceStatusBadge component.
/// Pass exactly one of [jobId] or [extJobId]. [expand] controls whether the
/// badge renders as a full-width banner (default) or an inline pill.
class InvoiceStatusBadge extends ConsumerWidget {
  const InvoiceStatusBadge({
    super.key,
    this.jobId,
    this.extJobId,
    this.expand = true,
  }) : assert(jobId != null || extJobId != null);

  final int? jobId;
  final int? extJobId;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);

    final statusAsync = jobId != null
        ? ref.watch(invoiceStatusByJobIdProvider(jobId!))
        : ref.watch(invoiceStatusByExtJobIdProvider(extJobId!));

    return statusAsync.when(
      loading: () => Container(
        height: expand ? 32 : 22,
        width: expand ? null : 160,
        decoration: BoxDecoration(
          color: c.border.subtle,
          borderRadius: BorderRadius.circular(DSRadius.pill),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (firstInvoicePaid) {
        final paid = firstInvoicePaid == true;
        return DSStatusBadge(
          label: paid ? 'Aftale bekræftet' : 'Afventer kundens bekræftelse',
          color: paid ? c.state.success : c.state.warning,
          expand: expand,
        );
      },
    );
  }
}
