import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';

/// Horizontal bar chart showing expense totals by day-of-week (Sun–Sat).
///
/// [dowTotals] has exactly 7 entries indexed 0=Sun … 6=Sat.
/// [color] is the fill hue.
class HeatmapDowChart extends StatelessWidget {
  final List<double> dowTotals;
  final Color color;

  const HeatmapDowChart({
    super.key,
    required this.dowTotals,
    required this.color,
  });

  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final maxVal = dowTotals.fold(0.0, (m, v) => v > m ? v : m);

    return Column(
      children: List.generate(7, (i) {
        final val = dowTotals[i];
        final frac = maxVal > 0 ? val / maxVal : 0.0;
        final isWeekend = i == 0 || i == 6;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: isWeekend
                        ? context.colors.expense.withValues(alpha: 0.7)
                        : context.colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        color: context.colors.border.withValues(alpha: 0.4),
                      ),
                      FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.withValues(
                                alpha: isWeekend ? 0.65 : 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 6),
                          child: val > 0
                              ? Text(
                                  CurrencyUtils.formatCurrency(val),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
