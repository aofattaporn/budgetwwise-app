import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../widgets/plan_item_card.dart';

/// Revise Plan Page - re-budget every item at once mid-period.
///
/// Saving records the previous design as a revision (once the plan has
/// transactions), so it stays viewable from the plan history.
/// Pops `true` when the plan was changed.
class RevisePlanPage extends StatefulWidget {
  final Plan plan;
  final List<PlanItem> items;

  const RevisePlanPage({super.key, required this.plan, required this.items});

  @override
  State<RevisePlanPage> createState() => _RevisePlanPageState();
}

class _RevisePlanPageState extends State<RevisePlanPage> {
  late final Map<String, TextEditingController> _controllers = {
    for (final item in widget.items)
      item.id: TextEditingController(text: _format(item.expectedAmount)),
  };
  final _noteController = TextEditingController();
  bool _saving = false;

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  double _amountOf(PlanItem item) =>
      double.tryParse(_controllers[item.id]!.text) ?? 0;

  Map<String, double> get _changedAmounts => {
        for (final item in widget.items)
          if (_amountOf(item) != item.expectedAmount) item.id: _amountOf(item),
      };

  /// Same budget cap as the item editor: tracking-only items don't count.
  double get _totalPlanned => widget.items
      .where((i) => !i.isTrackingOnly)
      .fold(0.0, (sum, i) => sum + _amountOf(i));

  bool get _isOverIncome {
    final income = widget.plan.expectedIncome;
    return income != null && _totalPlanned > income;
  }

  bool get _canSave => !_saving && !_isOverIncome && _changedAmounts.isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      final revision = await getIt<PlanRepository>().revisePlan(
        widget.plan.id,
        _changedAmounts,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            revision == null ? 'Plan updated' : 'Saved as version $revision'),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to revise plan: $e'),
        backgroundColor: context.colors.expense,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(title: 'Revise Plan'),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        children: [
          _buildSummary(),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Budget items', style: context.styles.label),
              const Spacer(),
              Text(
                _changedAmounts.isEmpty
                    ? 'No changes'
                    : '${_changedAmounts.length} changed',
                style: context.styles.caption.copyWith(
                  color: _changedAmounts.isEmpty ? null : context.colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.items.sortedForDisplay().map(_buildItemRow),
          const SizedBox(height: 12),
          Text('Reason (optional)', style: context.styles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: context.styles.input(
              hint: 'e.g. Fuel came in under, food is short',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'The current design is kept in the plan history so you can '
            'compare later.',
            style: context.styles.caption,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding, 12, AppDimens.pagePadding, 12),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          child: ElevatedButton(
            onPressed: _canSave ? _save : null,
            style: context.styles.primaryButton,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Revision'),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(PlanItem item) {
    final newAmount = _amountOf(item);
    final delta = newAmount - item.expectedAmount;
    final belowSpent = !item.isTrackingOnly && newAmount < item.actualAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PlanItemCard(
        item: item.copyWith(expectedAmount: newAmount),
        dimWhenDepleted: false,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          delta == 0
                              ? 'Current budget'
                              : 'Was ${CurrencyUtils.formatCurrency(item.expectedAmount)}',
                          style: context.styles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (delta != 0) ...[
                        const SizedBox(width: 8),
                        _buildDeltaChip(delta),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 124,
                  child: TextField(
                    controller: _controllers[item.id],
                    textAlign: TextAlign.end,
                    decoration:
                        context.styles.input(hint: '0', prefixText: '฿ '),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (belowSpent) ...[
              const SizedBox(height: 8),
              Text(
                'Below what you already spent '
                '(${CurrencyUtils.formatCurrency(item.actualAmount)})',
                style: context.styles.caption
                    .copyWith(color: context.colors.expense),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaChip(double delta) {
    final up = delta > 0;
    final color = up ? context.colors.income : context.colors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            CurrencyUtils.formatCurrency(delta.abs()),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final income = widget.plan.expectedIncome;
    final planned = _totalPlanned;
    final original = widget.items
        .where((i) => !i.isTrackingOnly)
        .fold(0.0, (sum, i) => sum + i.expectedAmount);
    final delta = planned - original;
    final over = _isOverIncome;
    final accent = over ? context.colors.expense : context.colors.accent;
    final ratio = (income != null && income > 0)
        ? (planned / income).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total planned', style: context.styles.caption),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  CurrencyUtils.formatCurrency(planned),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: over
                        ? context.colors.expense
                        : context.colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (delta != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildDeltaChip(delta),
                ),
            ],
          ),
          if (income != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  over
                      ? 'Over income by ${CurrencyUtils.formatCurrency(planned - income)}'
                      : '${CurrencyUtils.formatCurrency(income - planned)} unallocated',
                  style: context.styles.caption.copyWith(
                    color: over ? context.colors.expense : null,
                    fontWeight: over ? FontWeight.w600 : null,
                  ),
                ),
                Text('of ${CurrencyUtils.formatCurrency(income)}',
                    style: context.styles.caption),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
