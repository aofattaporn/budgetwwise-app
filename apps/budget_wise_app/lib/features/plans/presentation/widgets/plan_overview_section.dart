import 'package:flutter/material.dart';

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
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _primaryColor = Color(0xFF4D648D);

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isDetailsExpanded = false;

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

  double get _incomeDifference => _expectedIncome - widget.actualIncome;

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleDetailsExpanded() {
    setState(() {
      _isDetailsExpanded = !_isDetailsExpanded;
    });
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
          const SizedBox(height: 16),
          _buildIncomeTrackingSection(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.plan.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.plan.formattedPeriod,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isActive = widget.plan.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? _primaryColor.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? _primaryColor : Colors.grey.shade600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - AVAILABLE TO SPEND CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvailableToSpendCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardLabel(),
          const SizedBox(height: 8),
          _buildAvailableAmount(),
          const SizedBox(height: 16),
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildSpentAndPercentageRow(),
        ],
      ),
    );
  }

  Widget _buildCardLabel() {
    return Text(
      'Available to Spend',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildAvailableAmount() {
    return Text(
      CurrencyUtils.formatCurrency(_availableToSpend.clamp(0, double.infinity)),
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_percentageLeft / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.white.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          progress < 0.15 ? Colors.red.shade300 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildSpentAndPercentageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${CurrencyUtils.formatCurrency(widget.totalSpent)} spent',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          '${_percentageLeft.toStringAsFixed(0)}% left',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - INCOME TRACKING SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildIncomeTrackingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIncomeTrackingHeader(),
          if (_isDetailsExpanded) _buildIncomeTrackingDetails(),
        ],
      ),
    );
  }

  Widget _buildIncomeTrackingHeader() {
    return InkWell(
      onTap: _toggleDetailsExpanded,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Income Tracking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              _isDetailsExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTrackingDetails() {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDetailRow(
                label: 'Planned Income',
                value: CurrencyUtils.formatCurrency(_expectedIncome),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                label: 'Actual Income',
                value: CurrencyUtils.formatCurrency(widget.actualIncome),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 12),
              _buildDetailRow(
                label: 'Difference',
                value:
                    '${_incomeDifference >= 0 ? '+' : ''}${CurrencyUtils.formatCurrency(_incomeDifference)}',
                valueColor: _incomeDifference >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: _primaryColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
