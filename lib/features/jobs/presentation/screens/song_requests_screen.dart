import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/song_request.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SongRequestsScreen extends ConsumerStatefulWidget {
  const SongRequestsScreen({
    super.key,
    required this.jobId,
    required this.songRequestToken,
  });

  final int jobId;
  final String? songRequestToken;

  @override
  ConsumerState<SongRequestsScreen> createState() => _SongRequestsScreenState();
}

class _SongRequestsScreenState extends ConsumerState<SongRequestsScreen> {
  DSColors get _c => DSTheme.of(context);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 30 s so new requests appear without manual refresh.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(songRequestsForJobProvider(widget.jobId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _showQrDialog() {
    final token = widget.songRequestToken;
    if (token == null) return;
    const publicBaseUrl = 'https://app.djtilbud.dk';
    final url = '$publicBaseUrl/song-request/$token';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _c.bg.surface,
        title: Text(
          'QR-kode til sangønsker',
          style: DSTextStyle.headingSm.copyWith(color: _c.text.primary),
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(DSSpacing.s3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DSRadius.md),
                ),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: DSSpacing.s3),
              Text(
                'Gæsterne scanner koden og sender deres ønsker direkte til dig.',
                textAlign: TextAlign.center,
                style: DSTextStyle.bodyMd
                    .copyWith(color: _c.text.secondary, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          DSButton(
            label: 'Luk',
            variant: DSButtonVariant.ghost,
            size: DSButtonSize.sm,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(songRequestsForJobProvider(widget.jobId));

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Sangønsker'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        actions: [
          if (widget.songRequestToken != null)
            IconButton(
              icon: const Icon(LucideIcons.qrCode),
              tooltip: 'Vis QR-kode',
              onPressed: _showQrDialog,
            ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Opdater',
            onPressed: () =>
                ref.invalidate(songRequestsForJobProvider(widget.jobId)),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 32, color: DSTheme.of(context).state.danger),
              const SizedBox(height: DSSpacing.s3),
              Text(
                'Kunne ikke hente sangønsker',
                style: DSTextStyle.bodyMd
                    .copyWith(color: DSTheme.of(context).text.secondary),
              ),
              const SizedBox(height: DSSpacing.s3),
              DSButton(
                label: 'Prøv igen',
                variant: DSButtonVariant.secondary,
                onTap: () =>
                    ref.invalidate(songRequestsForJobProvider(widget.jobId)),
              ),
            ],
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.music, size: 40, color: _c.text.muted),
                  const SizedBox(height: DSSpacing.s3),
                  Text(
                    'Ingen sangønsker endnu',
                    style: DSTextStyle.headingSm.copyWith(color: _c.text.muted),
                  ),
                  const SizedBox(height: DSSpacing.s2),
                  Text(
                    'Gæsterne kan sende ønsker ved at scanne QR-koden.',
                    textAlign: TextAlign.center,
                    style: DSTextStyle.bodyMd
                        .copyWith(color: _c.text.muted, height: 1.4),
                  ),
                  if (widget.songRequestToken != null) ...[
                    const SizedBox(height: DSSpacing.s4),
                    DSButton(
                      label: 'Vis QR-kode',
                      variant: DSButtonVariant.secondary,
                      iconLeft: LucideIcons.qrCode,
                      onTap: _showQrDialog,
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(DSSpacing.s4),
            itemCount: requests.length,
            separatorBuilder: (_, __) => Divider(
              height: DSSpacing.s4,
              color: _c.border.subtle,
            ),
            itemBuilder: (_, i) => _SongRequestTile(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _SongRequestTile extends StatelessWidget {
  const _SongRequestTile({required this.request});
  final SongRequest request;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final dateStr = DateFormat('d. MMM HH:mm', 'da_DK')
        .format(request.createdAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.mail, size: 13, color: c.text.muted),
            const SizedBox(width: DSSpacing.s1),
            Expanded(
              child: Text(
                request.guestEmail,
                style: DSTextStyle.labelMd.copyWith(
                  color: c.text.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              dateStr,
              style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.s2),
        for (final song in request.songs)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(LucideIcons.music2, size: 13, color: c.brand.primaryActive),
                const SizedBox(width: DSSpacing.s2),
                Expanded(
                  child: Text(
                    song,
                    style: DSTextStyle.bodyMd.copyWith(color: c.text.primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
