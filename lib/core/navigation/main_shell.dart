import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:dj_tilbud_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:dj_tilbud_app/features/jobs/presentation/providers/jobs_provider.dart';
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
      final actionBadge = ref.watch(djWonActionCountProvider);
      items = [
        DSNavigationItem(
          label: 'Jobs',
          icon: LucideIcons.listMusic,
          activeIcon: LucideIcons.listMusic,
          badgeCount: actionBadge,
        ),
        const DSNavigationItem(
          label: 'Udvalgte',
          icon: LucideIcons.sparkle,
          activeIcon: LucideIcons.sparkle,
        ),
        DSNavigationItem(
          label: 'Chat',
          icon: LucideIcons.messageCircle,
          activeIcon: LucideIcons.messageCircle,
          badgeCount: chatBadge,
        ),
        const DSNavigationItem(
          label: 'Profil',
          icon: LucideIcons.user,
          activeIcon: LucideIcons.user,
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
        const DSNavigationItem(
          label: 'Profil',
          icon: LucideIcons.user,
          activeIcon: LucideIcons.user,
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
