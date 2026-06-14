import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../bloc/insight_bloc.dart';
import '../widgets/heatmap_calendar_grid.dart';
import '../widgets/heatmap_dow_chart.dart';

/// Full-screen spending heatmap. Receives a snapshot of [InsightState] from
/// the caller (InsightPage) so it doesn't depend on BLoC context scope.
class HeatmapPage extends StatefulWidget {
  final InsightState state;

  const HeatmapPage({super.key, required this.state});

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  /// null = "All categories"
  String? _selectedCategory;

  // ── Category color palette (mirrors InsightPage pie chart) ────────────────
  static const List<Color> _palette = [
    Color(0xFF3B82F6),
    Color(0xFFDC2626),
    Color(0xFF059669),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF9CA3AF),
  ];

  List<CategoryInsight> get _categories => widget.state.categoryInsights
      .where((c) => c.actual > 0)
      .toList();

  Color _colorFor(int index) => _palette[index % _palette.length];

  Color get _activeColor {
    if (_selectedCategory == null) return const Color(0xFF3B82F6);
    final idx = _categories.indexWhere((c) => c.name == _selectedCategory);
    return idx >= 0 ? _colorFor(idx) : const Color(0xFF3B82F6);
  }

  // ── Filtered entries ──────────────────────────────────────────────────────

  List<DailyCategoryAmount> get _filteredEntries {
    final all = widget.state.dailyCategoryAmounts;
    if (_selectedCategory == null) return all;
    return all.where((e) => e.categoryName == _selectedCategory).toList();
  }

  // ── DoW totals for selected filter ───────────────────────────────────────

  List<double> get _filteredDowTotals {
    if (_selectedCategory == null) return widget.state.dowExpenseTotals;

    final totals = List<double>.filled(7, 0);
    for (final e in _filteredEntries) {
      totals[e.date.weekday % 7] += e.amount;
    }
    return totals;
  }

  // ── Stats for selected filter ─────────────────────────────────────────────

  double get _filteredTotal =>
      _filteredEntries.fold(0.0, (s, e) => s + e.amount);

  int get _filteredTxCount =>
      _filteredEntries.fold(0, (s, e) => s + e.txCount);

  int get _filteredActiveDays =>
      _filteredEntries.map((e) => e.date).toSet().length;

  double get _filteredBudget {
    if (_selectedCategory == null) return widget.state.totalBudget;
    return _categories
        .where((c) => c.name == _selectedCategory)
        .fold(0.0, (s, c) => s + c.budget);
  }

  // ── Insights ──────────────────────────────────────────────────────────────

  /// Day with the highest total spend (for the current filter).
  MapEntry<DateTime, double>? get _topDay {
    final dayMap = <DateTime, double>{};
    for (final e in _filteredEntries) {
      dayMap[e.date] = (dayMap[e.date] ?? 0) + e.amount;
    }
    if (dayMap.isEmpty) return null;
    return dayMap.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  double get _avgPerActiveDay {
    final days = _filteredActiveDays;
    return days > 0 ? _filteredTotal / days : 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.colors.scaffoldBg,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Heatmap', style: context.styles.titleMedium),
            if (state.selectedPlan != null)
              Text(
                '${DateFormat('MMM d').format(state.periodStart)} – '
                '${DateFormat('MMM d, y').format(state.periodEnd)}',
                style: context.styles.caption,
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 16),
            _buildStatsStrip(),
            const SizedBox(height: 16),
            _buildCalendarSection(),
            const SizedBox(height: 16),
            _buildDowSection(),
            const SizedBox(height: 16),
            _buildInsightsSection(),
          ],
        ),
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All', null, null),
          ...List.generate(_categories.length, (i) {
            final cat = _categories[i];
            return _chip(cat.name, cat.name, _colorFor(i));
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, Color? chipColor) {
    final isActive = _selectedCategory == value;
    final color = chipColor ?? context.colors.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : context.colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.5)
                  : context.colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chipColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? color : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats strip ───────────────────────────────────────────────────────────

  Widget _buildStatsStrip() {
    return Row(
      children: [
        _statCard('Total', CurrencyUtils.formatCurrency(_filteredTotal)),
        const SizedBox(width: 8),
        _statCard('Active Days', '$_filteredActiveDays days'),
        const SizedBox(width: 8),
        _statCard('Transactions', '$_filteredTxCount tx'),
        const SizedBox(width: 8),
        _statCard('Budget', CurrencyUtils.formatCurrency(_filteredBudget)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: context.styles.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: context.colors.textTertiary)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _activeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('Calendar Heatmap', style: context.styles.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text('Darker = more spending that day',
              style: context.styles.caption),
          const SizedBox(height: 16),
          HeatmapCalendarGrid(
            entries: _filteredEntries,
            periodStart: widget.state.periodStart,
            periodEnd: widget.state.periodEnd,
            color: _activeColor,
          ),
          const SizedBox(height: 12),
          _buildIntensityLegend(),
        ],
      ),
    );
  }

  Widget _buildIntensityLegend() {
    return Row(
      children: [
        Text('Less', style: context.styles.caption),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          final opacity = 0.08 + (i / 4) * 0.57;
          return Container(
            width: 18,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: _activeColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text('More', style: context.styles.caption),
      ],
    );
  }

  // ── Day-of-week chart ─────────────────────────────────────────────────────

  Widget _buildDowSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('Spending by Day of Week',
                  style: context.styles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          HeatmapDowChart(
            dowTotals: _filteredDowTotals,
            color: _activeColor,
          ),
        ],
      ),
    );
  }

  // ── Insights ──────────────────────────────────────────────────────────────

  Widget _buildInsightsSection() {
    final top = _topDay;
    final total = _filteredTotal;
    final budget = _filteredBudget;
    final budgetPct = budget > 0 ? (total / budget).clamp(0.0, 2.0) : null;

    if (top == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('Insights', style: context.styles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _insightRow(
            icon: '🔺',
            label: 'Highest day',
            value:
                '${DateFormat('EEE, MMM d').format(top.key)} · ${CurrencyUtils.formatCurrency(top.value)}',
          ),
          const SizedBox(height: 10),
          _insightRow(
            icon: '📆',
            label: 'Avg per active day',
            value: CurrencyUtils.formatCurrency(_avgPerActiveDay),
          ),
          if (budgetPct != null) ...[
            const SizedBox(height: 14),
            _buildBudgetBar(total, budget, budgetPct),
          ],
        ],
      ),
    );
  }

  Widget _insightRow(
      {required String icon,
      required String label,
      required String value}) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.styles.caption),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetBar(double total, double budget, double pct) {
    final isOver = total > budget;
    final barColor = isOver ? context.colors.expense : _activeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget usage', style: context.styles.caption),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: context.colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
                barColor.withValues(alpha: 0.75)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver
                  ? 'Over by ${CurrencyUtils.formatCurrency(total - budget)}'
                  : 'Remaining: ${CurrencyUtils.formatCurrency(budget - total)}',
              style: TextStyle(
                fontSize: 11,
                color: barColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'of ${CurrencyUtils.formatCurrency(budget)}',
              style: context.styles.caption,
            ),
          ],
        ),
      ],
    );
  }
}
