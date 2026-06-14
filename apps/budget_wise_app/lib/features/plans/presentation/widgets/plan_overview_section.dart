import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../domain/entities/plan.dart';

/// Plan Overview Section - Displays plan summary with budget tracking
///
/// This widget shows:
/// - Plan header with name, period, and status
/// - Available to spend card with progress bar
/// - Expandable income tracking details
/// - Action buttons (Edit, Close, All Plans)
class PlanOverviewSection extends StatefulWidget {
  final Plan plan;
  final double actualIncome;
  final double totalPlanned;
  final double totalSpent;
  final VoidCallback? onEditPlan;
  final VoidCallback? onClosePlan;
  final VoidCallback? onViewAllPlans;

  const PlanOverviewSection({
    super.key,
    required this.plan,
    required this.actualIncome,
    this.totalPlanned = 0,
    this.totalSpent = 0,
    this.onEditPlan,
    this.onClosePlan,
    this.onViewAllPlans,
  });

  @override
  State<PlanOverviewSection> createState() => _PlanOverviewSectionState();
}

class _PlanOverviewSectionState extends State<PlanOverviewSection> {
  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  double get _expectedIncome => widget.plan.expectedIncome ?? 0;

  double get _availableToSpend => _expectedIncome - widget.totalSpent;

  double get _percentageLeft {
    if (_expectedIncome > 0) {
      return ((1 - (widget.totalSpent / _expectedIncome)) * 100).clamp(0, 100);
    }
    return widget.totalSpent > 0 ? 0.0 : 100.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanHeader(),
          const SizedBox(height: 20),
          _buildAvailableToSpendCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - PLAN HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlanInfo(),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildPlanInfo() {
    final daysLeft = widget.plan.endDate.difference(DateTime.now()).inDays + 1; // plus 1 on diff day
    final daysLeftText = daysLeft < 0
        ? 'Ended'
        : daysLeft == 0
            ? 'Last day'
            : '$daysLeft days left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.plan.name, style: context.styles.titleLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(widget.plan.formattedPeriod, style: context.styles.caption),
            const SizedBox(width: 8),
            Text('·', style: context.styles.caption),
            const SizedBox(width: 8),
            Text(daysLeftText, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: daysLeft <= 3 ? context.colors.expense : context.colors.accent,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = widget.plan.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? context.colors.accentLight : context.colors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? context.colors.accent : context.colors.textTertiary,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - AVAILABLE TO SPEND CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvailableToSpendCard() {
    final progress = (_percentageLeft / 100).clamp(0.0, 1.0);

    // Branded blue "card" hero. Fixed gradient (not theme accent) so white text
    // keeps strong contrast in both light and dark mode. Mirrors the Accounts
    // total-balance hero for app-wide consistency.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available to Spend',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.savings_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyUtils.formatCurrency(_availableToSpend.clamp(0, double.infinity)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyUtils.formatCurrency(widget.totalSpent)} spent',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 12,
                ),
              ),
              Text(
                '${_percentageLeft.toStringAsFixed(0)}% left',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: widget.onEditPlan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.lock_outline,
            label: 'Close',
            onTap: widget.onClosePlan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.list_alt,
            label: 'All Plans',
            onTap: widget.onViewAllPlans,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: context.styles.card,
        child: Column(
          children: [
            Icon(icon, size: 20, color: context.colors.accent),
            const SizedBox(height: 6),
            Text(label, style: context.styles.label),
          ],
        ),
      ),
    );
  }
}
