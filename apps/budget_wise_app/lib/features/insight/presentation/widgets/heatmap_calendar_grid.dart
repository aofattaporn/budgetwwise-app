import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../bloc/insight_bloc.dart';

/// Calendar grid (Sun–Sat columns) showing per-day expense intensity.
///
/// [entries] contains only the days that have spending for the selected
/// category (or all categories when no filter is applied).
/// [periodStart] and [periodEnd] define the full grid date range.
/// [color] is the base hue used for cell shading.
class HeatmapCalendarGrid extends StatelessWidget {
  final List<DailyCategoryAmount> entries;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Color color;

  const HeatmapCalendarGrid({
    super.key,
    required this.entries,
    required this.periodStart,
    required this.periodEnd,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Build date → aggregate map
    final map = <DateTime, _DayAgg>{};
    for (final e in entries) {
      final existing = map[e.date] ?? _DayAgg(0, 0);
      map[e.date] = _DayAgg(existing.amount + e.amount, existing.count + e.txCount);
    }

    final maxAmount = map.values.fold(0.0, (m, v) => v.amount > m ? v.amount : m);

    // Build all days in range
    final days = <DateTime>[];
    var cur = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    while (!cur.isAfter(end)) {
      days.add(cur);
      cur = DateTime(cur.year, cur.month, cur.day + 1);
    }

    // Sunday = 0, dart weekday: Mon=1…Sun=7 → convert: (weekday % 7)
    final firstDayOffset = days.first.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekHeaders(context),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: firstDayOffset + days.length,
          itemBuilder: (context, index) {
            if (index < firstDayOffset) {
              return const SizedBox.shrink();
            }
            final day = days[index - firstDayOffset];
            final agg = map[day];
            return _DayCell(
              day: day,
              agg: agg,
              maxAmount: maxAmount,
              color: color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekHeaders(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: List.generate(7, (i) {
        final isWeekend = i == 0 || i == 6;
        return Expanded(
          child: Text(
            labels[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isWeekend
                  ? context.colors.expense.withValues(alpha: 0.6)
                  : context.colors.textTertiary,
            ),
          ),
        );
      }),
    );
  }
}

class _DayAgg {
  final double amount;
  final int count;
  const _DayAgg(this.amount, this.count)
      : assert(count >= 0);
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final _DayAgg? agg;
  final double maxAmount;
  final Color color;

  const _DayCell({
    required this.day,
    required this.agg,
    required this.maxAmount,
    required this.color,
  });

  double get _intensity {
    if (agg == null || maxAmount == 0) return 0;
    return (agg!.amount / maxAmount).clamp(0.0, 1.0);
  }

  Color get _cellColor {
    if (agg == null) return Colors.transparent;
    // Map intensity to opacity band: 0.08 → 0.65
    final opacity = 0.08 + _intensity * 0.57;
    return color.withValues(alpha: opacity);
  }

  Color get _borderColor {
    if (agg == null) return Colors.transparent;
    final opacity = 0.2 + _intensity * 0.5;
    return color.withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = agg != null;

    return Tooltip(
      message: hasData
          ? '${DateFormat('MMM d').format(day)}: ${CurrencyUtils.formatCurrency(agg!.amount)} · ${agg!.count}x'
          : DateFormat('MMM d').format(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hasData ? _cellColor : context.colors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasData ? _borderColor : context.colors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: hasData ? color : context.colors.textTertiary,
              ),
            ),
            if (hasData) ...[
              const SizedBox(height: 1),
              Text(
                '${agg!.count}x',
                style: TextStyle(
                  fontSize: 7,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
