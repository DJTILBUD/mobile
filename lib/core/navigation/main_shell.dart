import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/core/supabase/supabase_client.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.role,
    required this.navigationShell,
  });

  final MusicianRole role;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // During logout/login transitions there is a frame where the router has
    // not yet redirected away from the authed shell, but supabase.auth.currentUser
    // is null. Session-scoped providers (chat, jobs, admin) read `currentUser!.id`
    // in their factories and would crash. Render nothing until the redirect
    // catches up on the next frame.
    if (supabase.auth.currentUser == null) return const SizedBox.shrink();

    // Single source of truth for the unread notification count. Watching it here:
    //  (a) instantiates the notifications provider at app start, so its notifier keeps
    //      the OS app-icon badge in sync (it sets the badge on every emission), and
    //  (b) drives the Profile bottom-nav badge below.
    // The profile app-bar bell reads the SAME provider, so app icon = Profile tab =
    // bell — one number, traceable end to end.
    final notifBadge = ref.watch(unreadNotificationCountProvider);

    final chatBadge = ref.watch(totalUnreadChatCountProvider);

    final List<DSNavigationItem> items;

    if (role == MusicianRole.dj) {
      final jobsBadge = ref.watch(djQuoteActionCountProvider);
      final udvalgteBadge = ref.watch(djExtJobActionCountProvider);
      items = [
        DSNavigationItem(
          label: 'Jobs',
          icon: LucideIcons.listMusic,
          activeIcon: LucideIcons.listMusic,
          badgeCount: jobsBadge,
        ),
        DSNavigationItem(
          label: 'Udvalgte',
          icon: LucideIcons.star,
          activeIcon: LucideIcons.star,
          badgeCount: udvalgteBadge,
        ),
        DSNavigationItem(
          label: 'Chat',
          icon: LucideIcons.messageCircle,
          activeIcon: LucideIcons.messageCircle,
          badgeCount: chatBadge,
        ),
        DSNavigationItem(
          label: 'Profil',
          icon: LucideIcons.user,
          activeIcon: LucideIcons.user,
          badgeCount: notifBadge,
        ),
      ];
    } else {
      final actionBadge = ref.watch(musicianWonActionCountProvider);
      items = [
        DSNavigationItem(
          label: 'Jobs',
          icon: LucideIcons.listMusic,
          activeIcon: LucideIcons.listMusic,
          badgeCount: actionBadge,
        ),
        DSNavigationItem(
          label: 'Chat',
          icon: LucideIcons.messageCircle,
          activeIcon: LucideIcons.messageCircle,
          badgeCount: chatBadge,
        ),
        DSNavigationItem(
          label: 'Profil',
          icon: LucideIcons.user,
          activeIcon: LucideIcons.user,
          badgeCount: notifBadge,
        ),
      ];
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DSNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected:
            (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
        items: items,
      ),
    );
  }
}
