import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dj_tilbud_app/app.dart' show routerProvider;
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/notifications/notifications_service.dart';
import 'package:dj_tilbud_app/features/notifications/domain/entities/app_notification.dart';
import 'package:dj_tilbud_app/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final async = ref.watch(notificationsProvider);
    final hasUnread = (async.valueOrNull ?? const []).any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: c.bg.canvas,
      appBar: AppBar(
        title: const Text('Notifikationer'),
        backgroundColor: c.bg.surface,
        surfaceTintColor: c.bg.surface,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed:
                  () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(
                'Marker alle læst',
                style: DSTextStyle.labelMd.copyWith(
                  color: c.brand.primaryActive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            unreadOnly: _unreadOnly,
            onChanged: (v) => setState(() => _unreadOnly = v),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  () => ref.read(notificationsProvider.notifier).refresh(),
              child: async.when(
                loading:
                    () => const _CenteredScrollable(
                      child: CircularProgressIndicator(),
                    ),
                error:
                    (e, _) => _CenteredScrollable(
                      child: _EmptyOrError(
                        icon: LucideIcons.wifiOff,
                        title: 'Kunne ikke hente notifikationer',
                        subtitle: 'Træk ned for at prøve igen.',
                      ),
                    ),
                data: (items) {
                  final list =
                      _unreadOnly
                          ? items.where((n) => !n.isRead).toList()
                          : items;
                  if (list.isEmpty) {
                    return _CenteredScrollable(
                      child: _EmptyOrError(
                        icon: LucideIcons.bellOff,
                        title:
                            _unreadOnly
                                ? 'Ingen ulæste notifikationer'
                                : 'Ingen notifikationer endnu',
                        subtitle:
                            _unreadOnly
                                ? 'Du er helt oppe at date.'
                                : 'Når du modtager en notifikation, dukker den op her.',
                      ),
                    );
                  }
                  return _NotificationList(items: list);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.unreadOnly, required this.onChanged});

  final bool unreadOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      color: c.bg.surface,
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s2,
        DSSpacing.s4,
        DSSpacing.s3,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'Alle',
            selected: !unreadOnly,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: DSSpacing.s2),
          _Chip(
            label: 'Ulæste',
            selected: unreadOnly,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s3,
          vertical: DSSpacing.s1 + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? c.brand.primary : c.bg.canvas,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          border: Border.all(
            color: selected ? c.brand.primary : c.border.subtle,
          ),
        ),
        child: Text(
          label,
          style: DSTextStyle.labelMd.copyWith(
            color: selected ? c.brand.onPrimary : c.text.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = items.where((n) => !n.isRead).toList();
    final read = items.where((n) => n.isRead).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: DSSpacing.s6),
      children: [
        if (unread.isNotEmpty) const _SectionHeader('Nye'),
        ...unread.map((n) => _NotificationTile(notification: n)),
        if (read.isNotEmpty) const _SectionHeader('Tidligere'),
        ...read.map((n) => _NotificationTile(notification: n)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.s4,
        DSSpacing.s4,
        DSSpacing.s4,
        DSSpacing.s2,
      ),
      child: Text(
        label,
        style: DSTextStyle.headingSm.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: c.text.primary,
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  void _onTap(WidgetRef ref) {
    ref.read(notificationsProvider.notifier).markRead(notification.id);
    final router = ref.read(routerProvider);
    // keepCurrentStack: push the detail on top of this notifications screen so Back
    // returns here (not the home tab).
    NotificationsService.navigateTo(
      notification.data,
      router,
      keepCurrentStack: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = DSTheme.of(context);
    final n = notification;
    final visual = _visualForType(n.type);

    final tile = InkWell(
      onTap: () => _onTap(ref),
      child: Container(
        color: n.isRead ? c.bg.canvas : c.brand.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.s4,
          vertical: DSSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(visual.icon, size: 20, color: visual.color),
            ),
            const SizedBox(width: DSSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: DSTextStyle.bodyMd.copyWith(
                      color: c.text.primary,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  if (n.body != null && n.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      n.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DSTextStyle.bodySm.copyWith(
                        color: c.text.secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(n.createdAt),
                    style: DSTextStyle.labelSm.copyWith(color: c.text.muted),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6, left: DSSpacing.s2),
                decoration: BoxDecoration(
                  color: c.brand.primaryActive,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );

    // Read rows aren't swipeable; unread ones swipe either way to mark read WITHOUT
    // opening — in the "Ulæste" filter they then vanish. (Chat uses swipe too, so
    // the gesture is familiar.) confirmDismiss returns false so the row stays put.
    return Dismissible(
      key: ValueKey('notif-${n.id}'),
      direction: n.isRead ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (_) async {
        ref.read(notificationsProvider.notifier).markRead(n.id);
        return false;
      },
      background: const _SwipeReadHint(alignment: Alignment.centerLeft),
      secondaryBackground: const _SwipeReadHint(
        alignment: Alignment.centerRight,
      ),
      child: tile,
    );
  }
}

class _SwipeReadHint extends StatelessWidget {
  const _SwipeReadHint({required this.alignment});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      color: c.brand.primary.withValues(alpha: 0.18),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.check, size: 18, color: c.brand.primaryActive),
          const SizedBox(width: DSSpacing.s2),
          Text(
            'Læst',
            style: DSTextStyle.labelMd.copyWith(
              color: c.brand.primaryActive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(DSSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: c.text.muted),
          const SizedBox(height: DSSpacing.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DSTextStyle.headingSm.copyWith(color: c.text.primary),
          ),
          const SizedBox(height: DSSpacing.s1),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DSTextStyle.labelMd.copyWith(color: c.text.muted),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final local = dt.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return 'nu';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}t';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('d. MMM', 'da_DK').format(local);
}

class _TypeVisual {
  const _TypeVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

_TypeVisual _visualForType(String type) {
  const green = Color(0xFF2E7D32);
  const blue = Color(0xFF1565C0);
  const amber = Color(0xFFEF6C00);
  const purple = Color(0xFF6A1B9A);
  const red = Color(0xFFC62828);
  const teal = Color(0xFF00838F);

  switch (type) {
    case 'offer_won':
    case 'quote_won':
    case 'ext_job_assigned':
      return const _TypeVisual(LucideIcons.partyPopper, green);
    case 'offer_lost':
    case 'quote_lost':
      return const _TypeVisual(LucideIcons.xCircle, red);
    case 'new_job':
    case 'another_round':
    case 'new_ext_job':
      return const _TypeVisual(LucideIcons.listMusic, blue);
    case 'chat_message':
    case 'chat_reaction':
    case 'chat_unused_reminder':
    case 'support_admin':
      return const _TypeVisual(LucideIcons.messageCircle, teal);
    case 'ready_reminder':
    case 'extra_hours_reminder':
    case 'contact_customer_reminder':
    case 'send_invoice_reminder':
    case 'content_record_reminder':
    case 'content_upload_reminder':
      return const _TypeVisual(LucideIcons.clock, amber);
    case 'content_accepted':
    case 'content_rejected':
      return const _TypeVisual(LucideIcons.video, purple);
    case 'song_request':
      return const _TypeVisual(LucideIcons.music, purple);
    case 'admin_message':
      return const _TypeVisual(LucideIcons.megaphone, blue);
    default:
      return const _TypeVisual(LucideIcons.bell, blue);
  }
}
