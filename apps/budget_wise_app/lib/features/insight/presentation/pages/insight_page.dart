import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../di/injection.dart';
import '../../../settings/settings.dart';
import '../bloc/insight_bloc.dart';
import '../bloc/insight_chat_cubit.dart';
import '../widgets/heatmap_calendar_grid.dart';
import '../widgets/insight_chat_sheet.dart';
import 'heatmap_page.dart';

class InsightPage extends StatefulWidget {
  const InsightPage({super.key});

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  late final InsightChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    _chatCubit = InsightChatCubit(
      supabaseClient: getIt<SupabaseClient>(),
    );
    context.read<InsightBloc>().add(const LoadInsightData());
  }

  @override
  void dispose() {
    _chatCubit.close();
    super.dispose();
  }

  void _showChatSheet(InsightState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _chatCubit,
        child: InsightChatSheet(planId: state.selectedPlan?.id ?? ''),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _previousPlan() {
    final state = context.read<InsightBloc>().state;
    if (state.canGoPrevious) {
      context
          .read<InsightBloc>()
          .add(ChangeInsightPlan(state.selectedPlanIndex + 1));
    }
  }

  void _nextPlan() {
    final state = context.read<InsightBloc>().state;
    if (state.canGoNext) {
      context
          .read<InsightBloc>()
          .add(ChangeInsightPlan(state.selectedPlanIndex - 1));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      floatingActionButton: BlocConsumer<InsightBloc, InsightState>(
        listener: (BuildContext context, InsightState state) {},
        builder: (context, state) => FloatingActionButton(
          onPressed: () => _showChatSheet(state),
          backgroundColor: context.colors.accent,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<InsightBloc, InsightState>(
          listener: (context, state) {
            if (state.status == InsightStatus.error &&
                state.errorMessage != null) {
              context.showSnackBar(state.errorMessage!, isError: true);
            }
          },
          builder: _buildBody,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InsightState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildPlanSelector(state),
        Expanded(
          child: state.status == InsightStatus.loading ||
                  state.status == InsightStatus.initial
              ? Center(
                  child: CircularProgressIndicator(
                      color: context.colors.primary))
              : _buildContent(state),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Insight', style: context.styles.displayMedium),
                const SizedBox(height: 4),
                Text('Budget tracking & spending trends',
                    style: context.styles.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: context.colors.scaffoldBg,
                    appBar: AppBar(
                      title: const Text('Settings'),
                      backgroundColor: context.colors.scaffoldBg,
                      foregroundColor: context.colors.textPrimary,
                      elevation: 0,
                    ),
                    body: const SettingsPlaceholderPage(),
                  ),
                ),
              );
            },
            icon: Icon(Icons.settings_outlined,
                color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAN SELECTOR (replaces month selector)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlanSelector(InsightState state) {
    final plan = state.selectedPlan;
    final dateFormat = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: state.canGoPrevious ? _previousPlan : null,
            icon: Icon(
              Icons.chevron_left,
              color: state.canGoPrevious
                  ? context.colors.accent
                  : context.colors.textTertiary,
            ),
            splashRadius: 20,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  plan?.name ?? 'No Plan',
                  style: context.styles.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (plan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${dateFormat.format(plan.startDate)} – ${dateFormat.format(plan.endDate)}, ${plan.endDate.year}',
                    style: context.styles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: state.canGoNext ? _nextPlan : null,
            icon: Icon(
              Icons.chevron_right,
              color: state.canGoNext
                  ? context.colors.accent
                  : context.colors.textTertiary,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent(InsightState state) {
    if (state.transactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () async {
        context.read<InsightBloc>().add(const RefreshInsightData());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            _buildSummaryCards(state),
            const SizedBox(height: 20),
            _buildInlineHeatmap(state),
            const SizedBox(height: 20),
            if (state.overspentCategories.isNotEmpty) ...[
              _buildOverspendList(state),
              const SizedBox(height: 20),
            ],
            _buildDailyChart(state),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined,
              size: 36, color: context.colors.textTertiary),
          const SizedBox(height: 16),
          Text('No data for this period', style: context.styles.bodyLarge),
          const SizedBox(height: 4),
          Text('Add transactions to see insights',
              style: context.styles.bodySmall),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(InsightState state) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            state.totalIncome,
            context.colors.income,
            Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expense',
            state.totalExpense,
            context.colors.expense,
            Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Net',
            state.netAmount,
            state.netAmount >= 0
                ? context.colors.income
                : context.colors.expense,
            state.netAmount >= 0
                ? Icons.trending_up
                : Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: context.styles.caption),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyUtils.formatCurrency(amount.abs()),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY INCOME VS EXPENSE LINE CHART
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDailyChart(InsightState state) {
    final daily = state.dailyAmounts;
    if (daily.isEmpty) return const SizedBox.shrink();

    // Find max for Y axis
    double maxY = 0;
    for (final d in daily) {
      if (d.income > maxY) maxY = d.income;
      if (d.expense > maxY) maxY = d.expense;
    }
    maxY = maxY == 0 ? 1000 : maxY * 1.2;

    final dateFormat = DateFormat('M/d');
    // Show ~5 labels evenly spaced
    final labelInterval = (daily.length / 5).ceil().toDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Income vs Expense',
              style: context.styles.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${dateFormat.format(state.periodStart)} – ${dateFormat.format(state.periodEnd)}',
            style: context.styles.caption,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.colors.divider,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          _formatCompact(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: labelInterval,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateFormat.format(daily[idx].date),
                            style: TextStyle(
                              fontSize: 9,
                              color: context.colors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (daily.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: daily
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                        .toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: context.colors.income,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.colors.income
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: daily
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                        .toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: context.colors.expense,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.colors.expense
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        final idx = spot.x.toInt().clamp(0, daily.length - 1);
                        final date = dateFormat.format(daily[idx].date);
                        return LineTooltipItem(
                          '$date\n${isIncome ? 'Income' : 'Expense'}: ${CurrencyUtils.formatCurrency(spot.y)}',
                          TextStyle(
                            color: isIncome
                                ? context.colors.income
                                : context.colors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(context.colors.income, 'Income'),
              const SizedBox(width: 20),
              _buildLegendDot(context.colors.expense, 'Expense'),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERSPEND LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverspendList(InsightState state) {
    final overspent = state.overspentCategories;

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: context.colors.expense),
              const SizedBox(width: 8),
              Text('Over Budget', style: context.styles.titleMedium),
              const Spacer(),
              Text(
                '${overspent.length} item${overspent.length == 1 ? '' : 's'}',
                style: context.styles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overspent.map(_buildOverspendRow),
        ],
      ),
    );
  }

  Widget _buildOverspendRow(CategoryInsight category) {
    final overPct = category.budget > 0
        ? ((category.actual / category.budget - 1) * 100)
        : 100.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.name, style: context.styles.bodyLarge),
              ),
              Text(
                '+${CurrencyUtils.formatCurrency(category.overAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget: ${CurrencyUtils.formatCurrency(category.budget)} · '
                  'Actual: ${CurrencyUtils.formatCurrency(category.actual)}',
                  style: context.styles.caption,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${overPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.colors.expense,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Visual bar: budget (gray) + over (red)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final maxAmount =
                      category.actual > category.budget
                          ? category.actual
                          : category.budget;
                  final budgetWidth = maxAmount > 0
                      ? (category.budget / maxAmount * totalWidth)
                      : 0.0;
                  final actualWidth = maxAmount > 0
                      ? (category.actual / maxAmount * totalWidth)
                      : 0.0;

                  return Stack(
                    children: [
                      // Background
                      Container(
                        width: totalWidth,
                        color: context.colors.divider,
                      ),
                      // Budget portion
                      Container(
                        width: budgetWidth,
                        color: context.colors.accent.withValues(alpha: 0.3),
                      ),
                      // Actual portion (over budget in red)
                      Container(
                        width: actualWidth,
                        color: context.colors.expense.withValues(alpha: 0.6),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUDGET VS ACTUAL BAR CHART (replaces Income vs Expense)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetVsActualChart(InsightState state) {
    if (state.planItems.isEmpty) {
      // No plan — fall back to simple income vs expense
      return _buildIncomeVsExpenseBar(state);
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget vs Actual', style: context.styles.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Plan: ${state.activePlan?.name ?? 'Active'}',
                style: context.styles.caption,
              ),
              const Spacer(),
              Text(
                'Total budget: ${CurrencyUtils.formatCurrency(state.totalBudget)}',
                style: context.styles.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Budget vs actual summary bar
          _buildBudgetSummaryBar(state),
          const SizedBox(height: 20),
          // Per-category horizontal bars
          ...state.categoryInsights
              .where((c) => c.actual > 0 || c.budget > 0)
              .map(_buildCategoryBar),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryBar(InsightState state) {
    final budget = state.totalBudget;
    final actual = state.totalExpense;
    final isOver = actual > budget;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Spent', style: context.styles.bodyLarge),
            Text(
              CurrencyUtils.formatCurrency(actual),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOver ? context.colors.expense : context.colors.income,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (_, constraints) {
                final maxVal = actual > budget ? actual : budget;
                final budgetW = maxVal > 0
                    ? (budget / maxVal * constraints.maxWidth)
                    : constraints.maxWidth;
                final actualW = maxVal > 0
                    ? (actual / maxVal * constraints.maxWidth)
                    : 0.0;

                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      color: context.colors.divider,
                    ),
                    Container(width: budgetW, color: context.colors.accent.withValues(alpha: 0.2)),
                    Container(
                      width: actualW,
                      color: isOver
                          ? context.colors.expense.withValues(alpha: 0.7)
                          : context.colors.income.withValues(alpha: 0.7),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver
                  ? 'Over by ${CurrencyUtils.formatCurrency(actual - budget)}'
                  : 'Remaining: ${CurrencyUtils.formatCurrency(budget - actual)}',
              style: TextStyle(
                fontSize: 11,
                color: isOver ? context.colors.expense : context.colors.income,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Budget: ${CurrencyUtils.formatCurrency(budget)}',
              style: context.styles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBar(CategoryInsight cat) {
    final maxVal = cat.actual > cat.budget ? cat.actual : cat.budget;
    if (maxVal == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cat.name, style: context.styles.bodyLarge),
              ),
              if (cat.isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: context.colors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${CurrencyUtils.formatCurrency(cat.overAmount)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.colors.expense,
                    ),
                  ),
                ),
              Text(
                '${CurrencyUtils.formatCurrency(cat.actual)} / ${CurrencyUtils.formatCurrency(cat.budget)}',
                style: context.styles.caption,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final budgetW = cat.budget / maxVal * w;
                  final actualW = cat.actual / maxVal * w;
                  final color = cat.isOverBudget
                      ? context.colors.expense
                      : context.colors.accent;
                  return Stack(
                    children: [
                      Container(width: w, color: context.colors.divider),
                      if (cat.budget > 0)
                        Container(
                            width: budgetW,
                            color: context.colors.accent.withValues(alpha: 0.15)),
                      Container(
                          width: actualW,
                          color: color.withValues(alpha: 0.7)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseBar(InsightState state) {
    final maxVal =
        state.totalIncome > state.totalExpense
            ? state.totalIncome
            : state.totalExpense;
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income vs Expense', style: context.styles.titleMedium),
          const SizedBox(height: 4),
          Text('Monthly comparison', style: context.styles.caption),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: maxVal * 1.3,
                groupsSpace: 40,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = groupIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label\n${CurrencyUtils.formatCurrency(rod.toY)}',
                        TextStyle(
                          color: rod.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          _formatCompact(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Income', 'Expense'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.colors.divider,
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: state.totalIncome,
                        color: context.colors.income,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: state.totalExpense,
                        color: context.colors.expense,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INLINE HEATMAP (replaces donut chart)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInlineHeatmap(InsightState state) {
    final entries = state.dailyCategoryAmounts;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HeatmapPage(state: state)),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: context.styles.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spending Heatmap',
                          style: context.styles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${state.activeDaysWithExpense} active days · '
                        '${CurrencyUtils.formatCurrency(state.totalExpense)} total',
                        style: context.styles.caption,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text('Details', style: context.styles.caption),
                    Icon(Icons.chevron_right,
                        size: 16, color: context.colors.textTertiary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            HeatmapCalendarGrid(
              entries: entries,
              periodStart: state.periodStart,
              periodEnd: state.periodEnd,
              color: context.colors.accent,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Less', style: context.styles.caption),
                const SizedBox(width: 6),
                ...List.generate(5, (i) {
                  final opacity = 0.08 + (i / 4) * 0.57;
                  return Container(
                    width: 16,
                    height: 10,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: context.colors.accent.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                Text('More', style: context.styles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.styles.caption),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}
