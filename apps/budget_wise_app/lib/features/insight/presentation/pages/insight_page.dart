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

  /// Category selected for the cumulative-vs-pace chart. Null = auto-pick the
  /// highest-spend category for the current plan.
  String? _cumulativeCategory;

  /// Whether the Category Status list body is expanded.
  bool _showCategoryStatus = true;

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
      return RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async {
          context.read<InsightBloc>().add(const RefreshInsightData());
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildEmptyState(),
            ),
          ),
        ),
      );
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
            const SizedBox(height: 16),
            _buildPacingBanner(state),
            const SizedBox(height: 20),
            _buildInlineHeatmap(state),
            const SizedBox(height: 20),
            if (state.categoryInsights.isNotEmpty) ...[
              _buildCategoryStatusList(state),
              const SizedBox(height: 20),
            ],
            if (state.totalBudget > 0) ...[
              _buildCumulativePaceChart(state),
              const SizedBox(height: 20),
            ],
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
  // CATEGORY STATUS LIST (สถานะรายหมวด)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Per-category budget vs actual, sorted by % used (highest first), each with
  /// a usage bar and a status pill. Mirrors the report's "สถานะรายหมวด" table.
  Widget _buildCategoryStatusList(InsightState state) {
    final cats = state.categoryInsights
        .where((c) => c.budget > 0 || c.actual > 0)
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    if (cats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                setState(() => _showCategoryStatus = !_showCategoryStatus),
            child: Row(
              children: [
                Text('Category Status', style: context.styles.titleMedium),
                const Spacer(),
                Text(
                  '${cats.length} categor${cats.length == 1 ? 'y' : 'ies'}',
                  style: context.styles.caption,
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _showCategoryStatus ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more,
                      size: 22, color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          if (_showCategoryStatus) ...[
            const SizedBox(height: 12),
            ...cats.map(_buildCategoryStatusRow),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryStatusRow(CategoryInsight cat) {
    const amber = Color(0xFFF59E0B);
    final hasBudget = cat.budget > 0;
    final ratio = hasBudget ? cat.actual / cat.budget : 0.0;
    final pctText = hasBudget ? '${(ratio * 100).toStringAsFixed(0)}%' : '—';

    final Color statusColor;
    final String statusText;
    if (!hasBudget) {
      statusColor = context.colors.textTertiary;
      statusText = 'No budget';
    } else if (cat.isOverBudget) {
      statusColor = context.colors.expense;
      statusText = 'Over ${CurrencyUtils.formatCurrency(cat.overAmount)}';
    } else if (ratio >= 0.999) {
      statusColor = amber;
      statusText = 'Full';
    } else if (ratio >= 0.85) {
      statusColor = amber;
      statusText = '${CurrencyUtils.formatCurrency(cat.remaining)} left';
    } else {
      statusColor = context.colors.income;
      statusText = '${CurrencyUtils.formatCurrency(cat.remaining)} left';
    }

    final barColor = !hasBudget
        ? context.colors.textTertiary
        : cat.isOverBudget
            ? context.colors.expense
            : ratio >= 0.85
                ? amber
                : context.colors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cat.name, style: context.styles.bodyLarge),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasBudget
                      ? '${CurrencyUtils.formatCurrency(cat.actual)} / ${CurrencyUtils.formatCurrency(cat.budget)}'
                      : CurrencyUtils.formatCurrency(cat.actual),
                  style: context.styles.caption,
                ),
              ),
              Text(
                pctText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 6, color: context.colors.divider),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    color: barColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUMULATIVE SPEND VS PACE CHART (Food สะสม vs เส้น pace)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cumulative spending of a chosen category vs the straight "ideal pace" line
  /// (budget ÷ period days). Mirrors the report's "Food สะสม vs เส้น pace".
  Widget _buildCumulativePaceChart(InsightState state) {
    final budgeted = state.categoryInsights
        .where((c) => c.budget > 0)
        .toList()
      ..sort((a, b) => b.actual.compareTo(a.actual));
    if (budgeted.isEmpty) return const SizedBox.shrink();

    // Resolve the selected category, defaulting to the highest-spend one.
    final selectedName = budgeted.any((c) => c.name == _cumulativeCategory)
        ? _cumulativeCategory!
        : budgeted.first.name;
    final selected = budgeted.firstWhere((c) => c.name == selectedName);
    final budget = selected.budget;

    // Ordered list of every day in the period.
    final days = state.dailyAmounts.map((d) => d.date).toList();
    if (days.isEmpty) return const SizedBox.shrink();
    final totalDays = days.length;

    // Per-day spend for the selected category.
    final perDay = <DateTime, double>{};
    for (final e in state.dailyCategoryAmounts) {
      if (e.categoryName != selectedName) continue;
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      perDay[key] = (perDay[key] ?? 0) + e.amount;
    }

    // Build cumulative + pace series. Cumulative stops growing on days that
    // have no spend; pace rises linearly to the full budget.
    final cumulativeSpots = <FlSpot>[];
    final paceSpots = <FlSpot>[];
    final perDayPace = budget / totalDays;
    double running = 0;
    for (int i = 0; i < totalDays; i++) {
      running += perDay[days[i]] ?? 0;
      cumulativeSpots.add(FlSpot(i.toDouble(), running));
      paceSpots.add(FlSpot(i.toDouble(), perDayPace * (i + 1)));
    }

    final cumColor =
        selected.isOverBudget ? context.colors.expense : context.colors.accent;
    final maxY = [running, budget].reduce((a, b) => a > b ? a : b) * 1.15;
    final dateFormat = DateFormat('M/d');
    final labelInterval =
        (totalDays / 5).ceil().toDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Cumulative vs Pace',
                    style: context.styles.titleMedium),
              ),
              _buildCategoryDropdown(budgeted, selectedName),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Budget ${CurrencyUtils.formatCurrency(budget)} ÷ $totalDays days = '
            '${CurrencyUtils.formatCurrency(perDayPace)}/day',
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
                        if (idx < 0 || idx >= totalDays) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateFormat.format(days[idx]),
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
                maxX: (totalDays - 1).toDouble(),
                minY: 0,
                maxY: maxY == 0 ? 1 : maxY,
                lineBarsData: [
                  // Cumulative actual spend
                  LineChartBarData(
                    spots: cumulativeSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: cumColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: cumColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Ideal pace line (dashed)
                  LineChartBarData(
                    spots: paceSpots,
                    isCurved: false,
                    color: context.colors.textTertiary,
                    barWidth: 1.5,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isCum = spot.barIndex == 0;
                        final idx = spot.x.toInt().clamp(0, totalDays - 1);
                        final date = dateFormat.format(days[idx]);
                        return LineTooltipItem(
                          '$date\n${isCum ? 'Spent' : 'Pace'}: ${CurrencyUtils.formatCurrency(spot.y)}',
                          TextStyle(
                            color: isCum
                                ? cumColor
                                : context.colors.textSecondary,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(cumColor, 'Cumulative'),
              const SizedBox(width: 20),
              _buildLegendDot(context.colors.textTertiary, 'Ideal pace'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
      List<CategoryInsight> categories, String selectedName) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedName,
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        dropdownColor: context.colors.cardBg,
        icon: Icon(Icons.arrow_drop_down, color: context.colors.textSecondary),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.accent,
        ),
        items: categories
            .map((c) => DropdownMenuItem(
                  value: c.name,
                  child: Text(c.name),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _cumulativeCategory = value);
        },
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
  // PERIOD PACING BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPacingBanner(InsightState state) {
    if (state.totalBudget == 0) return const SizedBox.shrink();

    final pacing = state.pacingStatus;
    final elapsed = state.periodElapsedDays;
    final total = state.periodTotalDays;
    final timePct = state.periodProgressPct;
    final spentPct = state.budgetSpentPct.clamp(0.0, 1.0);
    final dailyRemaining = state.dailyBudgetRemaining;
    final remaining = state.periodRemainingDays;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;
    switch (pacing) {
      case PacingStatus.underPace:
        statusColor = context.colors.income;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Under pace';
      case PacingStatus.overPace:
        statusColor = context.colors.expense;
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'Over pace';
      case PacingStatus.onPace:
        statusColor = context.colors.accent;
        statusIcon = Icons.radio_button_checked;
        statusLabel = 'On track';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Budget Pace', style: context.styles.titleMedium),
              const Spacer(),
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Day $elapsed of $total  ·  $remaining days left',
            style: context.styles.caption,
          ),
          const SizedBox(height: 14),
          _pacingRow(
            label: 'Time',
            pct: timePct,
            barColor: context.colors.accent,
            trailing: '${(timePct * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 8),
          _pacingRow(
            label: 'Spent',
            pct: spentPct,
            barColor: pacing == PacingStatus.overPace
                ? context.colors.expense
                : context.colors.income,
            trailing: '${(state.budgetSpentPct * 100).toStringAsFixed(0)}%',
          ),
          if (dailyRemaining > 0 && remaining > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: context.colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '${CurrencyUtils.formatCurrency(dailyRemaining)}/day to stay on budget',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else if (state.totalExpense > state.totalBudget) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 12, color: context.colors.expense),
                const SizedBox(width: 6),
                Text(
                  'Over budget by ${CurrencyUtils.formatCurrency(state.totalExpense - state.totalBudget)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pacingRow({
    required String label,
    required double pct,
    required Color barColor,
    required String trailing,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.textTertiary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: context.colors.border.withValues(alpha: 0.5),
                ),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            trailing,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
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
