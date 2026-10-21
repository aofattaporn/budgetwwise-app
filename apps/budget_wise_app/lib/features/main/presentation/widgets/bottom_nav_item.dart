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

/// Bottom navigation item: icon inside a pill indicator, label below.
class BottomNavItem extends StatelessWidget {
  final BottomNavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Color indicatorColor;

  const BottomNavItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
    this.activeColor = const Color(0xFF2F6BFF),
    this.inactiveColor = const Color(0xFF8E97A8),
    this.indicatorColor = const Color(0xFFE8F0FF),
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final icon = isSelected ? (data.activeIcon ?? data.icon) : data.icon;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: data.label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 56 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? indicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
