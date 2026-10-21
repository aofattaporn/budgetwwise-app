import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'bottom_nav_item.dart';

/// App-wide bottom navigation bar widget
///
/// Contains 5 navigation items: Home, Plans, Transactions, Accounts, More
/// Fixed at the bottom of the screen with clean minimal design
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Navigation items configuration
  static const List<BottomNavItemData> _navItems = [
    BottomNavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    BottomNavItemData(
      icon: Icons.checklist_outlined,
      activeIcon: Icons.checklist,
      label: 'Plans',
    ),
    BottomNavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Transactions',
    ),
    BottomNavItemData(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Accounts',
    ),
    BottomNavItemData(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Insight',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x66000000) : const Color(0x222F6BFF),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            _navItems.length,
            (index) => BottomNavItem(
              data: _navItems[index],
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
              activeColor: context.colors.accent,
              inactiveColor: context.colors.textTertiary,
              indicatorColor: context.colors.accentLight,
            ),
          ),
        ),
      ),
    );
  }
}
