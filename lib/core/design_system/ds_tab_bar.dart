import 'package:flutter/material.dart';
import 'tokens.dart';

/// A single tab definition for [DSTabBar].
class DSTabItem {
  const DSTabItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.activeColor,
    this.badgeCount = 0,
  });

  final String label;

  /// Icon shown when the tab is **inactive**.
  final IconData? icon;

  /// Icon shown when the tab is **active**. Falls back to [icon] if not provided.
  final IconData? activeIcon;

  /// Indicator + label color when this tab is selected.
  /// Falls back to [DSColors.brand.primary] if not provided.
  final Color? activeColor;

  /// When > 0, shows a red badge with this count on the tab icon.
  final int badgeCount;
}

/// Design-system tab bar.
///
/// Drop-in replacement for [TabBar]. Use as [AppBar.bottom] or inline.
/// Requires a [DefaultTabController] ancestor (or pass [controller] directly).
///
/// ```dart
/// DefaultTabController(
///   length: 3,
///   child: Scaffold(
///     appBar: AppBar(
///       bottom: DSTabBar(
///         tabs: [
///           DSTabItem(label: 'Home',    icon: LucideIcons.home,   activeIcon: LucideIcons.home),
///           DSTabItem(label: 'Search',  icon: LucideIcons.search),
///           DSTabItem(label: 'Profile', icon: LucideIcons.user,  activeIcon: LucideIcons.user),
///         ],
///       ),
///     ),
///     body: TabBarView(children: [...]),
///   ),
/// )
/// ```
class DSTabBar extends StatelessWidget implements PreferredSizeWidget {
  const DSTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.coloredIndicatorOnly = false,
  });

  final List<DSTabItem> tabs;
  final TabController? controller;

  /// When `true`, tabs scroll horizontally and align to the start.
  final bool isScrollable;

  /// When `true`, only the indicator line uses [DSTabItem.activeColor].
  /// The label and icon stay black ([DSColors.text.primary]) regardless of
  /// which tab is selected.
  final bool coloredIndicatorOnly;

  bool get _hasIcons =>
      tabs.any((t) => t.icon != null || t.activeIcon != null);

  @override
  Size get preferredSize => Size.fromHeight(_hasIcons ? 56 : 44);

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? DefaultTabController.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final c = DSTheme.of(context);
        return TabBar(
        controller: ctrl,
        isScrollable: isScrollable,
        tabAlignment:
            isScrollable ? TabAlignment.start : TabAlignment.fill,

        // Colors — indicator always uses activeColor; label only when not coloredIndicatorOnly
        labelColor: coloredIndicatorOnly ? c.text.primary : (tabs[ctrl.index].activeColor ?? c.brand.primary),
        unselectedLabelColor: c.text.muted,

        // Indicator — 3px line, full tab width
        indicatorColor: tabs[ctrl.index].activeColor ?? c.brand.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,

        // Divider under the whole bar
        dividerColor: c.border.subtle,
        dividerHeight: 1,

        // Typography
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),

        padding: EdgeInsets.zero,
        tabs: [
          for (int i = 0; i < tabs.length; i++)
            _buildTab(tabs[i], isActive: ctrl.index == i),
        ],
      );
      },
    );
  }

  Widget _buildTab(DSTabItem item, {required bool isActive}) {
    final icon = isActive ? (item.activeIcon ?? item.icon) : item.icon;

    if (icon != null) {
      final iconWidget = item.badgeCount > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20),
                Positioned(
                  top: -6,
                  right: -10,
                  child: _TabBadge(count: item.badgeCount),
                ),
              ],
            )
          : Icon(icon, size: 20);

      return Tab(
        height: 56,
        icon: iconWidget,
        iconMargin: const EdgeInsets.only(bottom: 3),
        text: item.label,
      );
    }

    return Tab(height: 44, text: item.label);
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.7,
        ),
      ),
    );
  }
}
