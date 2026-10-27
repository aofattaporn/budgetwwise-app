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

  /// Extra content rendered inside the card, below the summary (e.g. an editor).
  final Widget? footer;

  /// Fade the card and mark it inactive once the budget is used up.
  final bool dimWhenDepleted;

  const PlanItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMenuTap,
    this.footer,
    this.dimWhenDepleted = true,
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

    final isOver = item.isOverBudget;
    final decoration = context.styles.card.copyWith(
      border: hasStatus
          ? Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2)
          : context.styles.card.border,
    );

    final dimmed = dimWhenDepleted && item.isDepleted;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: decoration.copyWith(
            color: dimmed ? context.colors.surfaceLight : null,
            boxShadow: dimmed ? const [] : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildRing(context, statusColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: context.styles.bodyLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildChip(
                              context,
                              item.isTrackingOnly
                                  ? 'Tracking'
                                  : item.recurrenceType.label,
                              context.colors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                CurrencyUtils.formatCurrency(
                                    isOver ? item.overAmount : remaining),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isOver
                                      ? context.colors.expense
                                      : context.colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(isOver ? 'over' : 'left',
                                style: context.styles.caption),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Spent ${CurrencyUtils.formatCurrency(item.actualAmount)} of ${CurrencyUtils.formatCurrency(item.expectedAmount)}',
                                style: context.styles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasStatus || dimmed) ...[
                              const SizedBox(width: 8),
                              _buildChip(
                                context,
                                isOver
                                    ? 'Over'
                                    : dimmed
                                        ? 'Inactive'
                                        : 'Near limit',
                                dimmed && !isOver
                                    ? context.colors.textSecondary
                                    : statusColor,
                                filled: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 14),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(BuildContext context, Color statusColor) {
    const size = 64.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: item.progressPercentage),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: item.isTrackingOnly ? 0 : value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: statusColor.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ),
          Icon(PlanItemIcon.getIcon(item.iconIndex),
              size: 22, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color,
      {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.14)
            : context.colors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
