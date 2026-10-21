import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// App Floating Action Button widget
///
/// A customizable FAB that can be positioned above the bottom navigation bar
/// Follows the app's design system with accent color
class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const AppFloatingActionButton({
    super.key,
    this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'mainAppFab',
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? context.colors.accent,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Icon(
        icon,
        size: 28,
      ),
    );
  }
}
