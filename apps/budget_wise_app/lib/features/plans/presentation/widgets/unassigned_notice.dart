import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Widget displaying the unassigned transactions notice
class UnassignedNotice extends StatelessWidget {
  final int unassignedCount;
  final VoidCallback? onTap;

  const UnassignedNotice({
    super.key,
    this.unassignedCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceLight,
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: context.colors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unassignedCount > 0
                        ? '$unassignedCount transaction(s) not assigned to any plan item'
                        : 'All transactions are assigned to plan items',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (unassignedCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to review and assign them',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
