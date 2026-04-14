import 'package:flutter/material.dart';
import 'tokens.dart';

/// A single item in [DSNavigationBar].
class DSNavigationItem {
  const DSNavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badgeCount = 0,
  });

  final String label;

  /// Outlined icon — shown when this item is **inactive**.
  final IconData icon;

  /// Filled icon — shown when this item is **active**.
  /// Falls back to [icon] if not provided.
  final IconData? activeIcon;

  /// When > 0, shows a red badge with this count in the top-right of the icon.
  final int badgeCount;
}

/// Design-system bottom navigation bar.
///
/// Active item: filled icon, bold label, short coral indicator pill at the
/// very bottom edge. Inactive items: outlined icon, regular label.
///
/// Use as [Scaffold.bottomNavigationBar]. Handles safe-area insets internally.
///
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: DSNavigationBar(
///     selectedIndex: _currentIndex,
///     onDestinationSelected: (i) => setState(() => _currentIndex = i),
///     items: const [
///       DSNavigationItem(label: 'Jobs',   icon: LucideIcons.listMusic,         activeIcon: LucideIcons.listMusic),
///       DSNavigationItem(label: 'Chat',   icon: LucideIcons.messageCircle,  activeIcon: LucideIcons.messageCircle),
///       DSNavigationItem(label: 'Profil', icon: LucideIcons.user,       activeIcon: LucideIcons.user),
///     ],
///   ),
/// )
/// ```
class DSNavigationBar extends StatelessWidget {
  const DSNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<DSNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg.surface,
        border: Border(
          top: BorderSide(color: c.border.subtle, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                _DSNavItem(
                  item: items[i],
                  isSelected: selectedIndex == i,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DSNavItem extends StatelessWidget {
  const _DSNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DSNavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DSTheme.of(context);
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = isSelected ? c.text.primary : c.text.muted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon + label — centered vertically in the item area
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: DSMotion.normal,
                      curve: DSMotion.ease,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 0,
                        vertical: isSelected ? 3 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.brand.primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DSRadius.pill),
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: isSelected ? -6 : -8,
                        child: _Badge(count: item.badgeCount),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),

            // Indicator pill — anchored to bottom edge
            Positioned(
              bottom: 4,
              child: AnimatedContainer(
                duration: DSMotion.normal,
                curve: DSMotion.ease,
                width: isSelected ? 36.0 : 0.0,
                height: 3.0,
                decoration: BoxDecoration(
                  color: c.brand.primary,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.6,
        ),
      ),
    );
  }
}
