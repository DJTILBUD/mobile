import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/song_request.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SongRequestsScreen extends ConsumerStatefulWidget {
  const SongRequestsScreen({
    super.key,
    this.jobId,
    this.extJobId,
  }) : assert(jobId != null || extJobId != null, 'jobId or extJobId required');

  final int? jobId;
  final int? extJobId;

  @override
  ConsumerState<SongRequestsScreen> createState() => _SongRequestsScreenState();
}

class _SongRequestsScreenState extends ConsumerState<SongRequestsScreen> {
  DSColors get _c => DSTheme.of(context);
  Timer? _pollTimer;

  bool get _isExtJob => widget.extJobId != null;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _invalidate();
    });
  }

  void _invalidate() {
    if (_isExtJob) {
      ref.invalidate(songRequestsForExtJobProvider(widget.extJobId!));
    } else {
      ref.invalidate(songRequestsForJobProvider(widget.jobId!));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = _isExtJob
        ? ref.watch(songRequestsForExtJobProvider(widget.extJobId!))
        : ref.watch(songRequestsForJobProvider(widget.jobId!));

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('Sangønsker'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Opdater',
            onPressed: _invalidate,
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
                onTap: _invalidate,
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
                    'Gæsterne kan sende ønsker ved at scanne din QR-kode '
                    '(find den under Profil).',
                    textAlign: TextAlign.center,
                    style: DSTextStyle.bodyMd
                        .copyWith(color: _c.text.muted, height: 1.4),
                  ),
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
