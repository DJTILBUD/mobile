import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:dj_tilbud_app/features/profile/presentation/providers/profile_provider.dart';
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
    final chatBadge = ref.watch(totalUnreadChatCountProvider);

    final List<DSNavigationItem> items;

    if (role == MusicianRole.dj) {
      final jobsBadge = ref.watch(djQuoteActionCountProvider);
      final udvalgteBadge = ref.watch(djExtJobActionCountProvider);
      final adminBadge = ref.watch(unreadAdminMessageCountProvider(true));
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
          badgeCount: adminBadge,
        ),
      ];
    } else {
      final actionBadge = ref.watch(musicianWonActionCountProvider);
      final adminBadge = ref.watch(unreadAdminMessageCountProvider(false));
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
          badgeCount: adminBadge,
        ),
      ];
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DSNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        items: items,
      ),
    );
  }
}
