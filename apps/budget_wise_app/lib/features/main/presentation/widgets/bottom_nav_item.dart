import 'package:flutter/material.dart';

/// Data class for bottom navigation item
class BottomNavItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const BottomNavItemData({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Bottom navigation item widget
class BottomNavItem extends StatelessWidget {
  final BottomNavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const BottomNavItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
    this.activeColor = const Color(0xFF3B82F6),
    this.inactiveColor = const Color(0xFFA3A3A3),
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final icon = isSelected ? (data.activeIcon ?? data.icon) : data.icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
