import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Widget for empty state when no active plan exists
class NoPlanWidget extends StatelessWidget {
  final VoidCallback? onCreatePlan;
  final VoidCallback? onViewAllPlans;

  const NoPlanWidget({
    super.key,
    this.onCreatePlan,
    this.onViewAllPlans,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.checklist_rounded, size: 32, color: context.colors.accent),
            ),
            const SizedBox(height: 24),
            Text('No Active Plan', style: context.styles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create a plan to start tracking your budget',
              style: context.styles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreatePlan,
                style: context.styles.primaryButton,
                child: const Text('Create New Plan'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onViewAllPlans,
              style: TextButton.styleFrom(foregroundColor: context.colors.accent),
              child: const Text('View All Plans'),
            ),
          ],
        ),
      ),
    );
  }
}
