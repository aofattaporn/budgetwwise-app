import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Transactions placeholder page
/// 
/// Temporary UI until actual transactions feature is implemented
class TransactionsPlaceholderPage extends StatelessWidget {
  const TransactionsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Transactions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
