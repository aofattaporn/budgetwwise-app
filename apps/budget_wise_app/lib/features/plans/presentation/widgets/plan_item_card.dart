import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../domain/entities/plan_item.dart';
import '../pages/plan_item_editor_page.dart';

/// Widget displaying a single plan item card — minimal flat style
class PlanItemCard extends StatelessWidget {
  final PlanItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const PlanItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMenuTap,
  });

  Color _getProgressColor(BuildContext context) {
    switch (item.status) {
      case PlanItemStatus.overBudget:
        return context.colors.expense;
      case PlanItemStatus.nearLimit:
        return const Color(0xFFD97706); // amber
      default:
        return context.colors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = item.remainingAmount;
    final statusColor = _getProgressColor(context);
    final hasStatus = item.status == PlanItemStatus.overBudget ||
        item.status == PlanItemStatus.nearLimit;
    final pctUsed = item.progressPercentage * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.styles.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                context.styles.iconBox(
                  icon: PlanItemIcon.getIcon(item.iconIndex),
                  size: 40,
                  iconSize: 20,
                  radius: 12,
                  bgColor: statusColor.withValues(alpha: 0.12),
                  iconColor: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: context.styles.bodyLarge, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Expense', style: context.styles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                  child: Text(
                    '${pctUsed.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onMenuTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.chevron_right, size: 20, color: context.colors.textTertiary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prominent remaining / over, with spent vs planned alongside
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.isOverBudget ? 'Over budget' : 'Remaining',
                        style: context.styles.caption),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyUtils.formatCurrency(
                          item.isOverBudget ? item.overAmount : remaining),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: item.isOverBudget
                            ? context.colors.expense
                            : context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${CurrencyUtils.formatCurrency(item.actualAmount)} / ${CurrencyUtils.formatCurrency(item.expectedAmount)}',
                  style: context.styles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress (remaining — full when unused, decreases as spent)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 1.0 - item.progressPercentage,
                backgroundColor: context.colors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),

            if (hasStatus) ...[
              const SizedBox(height: 10),
              _buildStatusIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final isOver = item.status == PlanItemStatus.overBudget;
    final color = isOver ? context.colors.expense : const Color(0xFFD97706);
    return Row(
      children: [
        Icon(isOver ? Icons.error_outline : Icons.warning_amber_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          isOver ? 'Over planned amount' : 'Near limit',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

}
