import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';

/// Shows the customer's precise event address (provided after booking) with
/// copy-to-clipboard and open-in-maps actions. Renders nothing until the
/// address is available — only the winning DJ/musician can read it, so for any
/// other state (loading, missing, unauthorized) this collapses to an empty box.
///
/// Pass exactly one of [jobId] / [extJobId].
class EventAddressSection extends ConsumerWidget {
  const EventAddressSection({super.key, this.jobId, this.extJobId})
    : assert(
        (jobId == null) != (extJobId == null),
        'Provide exactly one of jobId / extJobId',
      );

  final int? jobId;
  final int? extJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        jobId != null
            ? ref.watch(eventAddressByJobIdProvider(jobId!))
            : ref.watch(eventAddressByExtJobIdProvider(extJobId!));
    final address = async.valueOrNull;
    if (address == null || address.isEmpty) return const SizedBox.shrink();
    return _AddressCard(address: address);
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final String address;

  Future<void> _openInMaps() async {
    final q = Uri.encodeComponent(address);
    // Apple Maps on iOS, Google Maps everywhere else (both accept a free-text
    // query and resolve the address).
    final url =
        Platform.isIOS
            ? 'https://maps.apple.com/?q=$q'
            : 'https://www.google.com/maps/search/?api=1&query=$q';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (context.mounted) {
      DSToast.show(
        context,
        variant: DSToastVariant.success,
        title: 'Adresse kopieret',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: DSSpacing.s4),
      padding: const EdgeInsets.all(DSSpacing.s4),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: c.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: c.brand.primaryActive),
              const SizedBox(width: DSSpacing.s2),
              Text(
                'Spillestedets adresse',
                style: DSTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.s2),
          Text(
            address,
            style: DSTextStyle.bodyMd.copyWith(color: c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s3),
          Row(
            children: [
              Expanded(
                child: DSButton(
                  label: 'Åbn i kort',
                  size: DSButtonSize.sm,
                  iconLeft: LucideIcons.mapPin,
                  expand: true,
                  onTap: _openInMaps,
                ),
              ),
              const SizedBox(width: DSSpacing.s3),
              Expanded(
                child: DSButton(
                  label: 'Kopiér',
                  variant: DSButtonVariant.secondary,
                  size: DSButtonSize.sm,
                  iconLeft: LucideIcons.copy,
                  expand: true,
                  onTap: () => _copy(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
