import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import 'plan_item_editor_page.dart';

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
        content: Text(revision == null
            ? 'Plan updated'
            : 'Saved as version $revision'),
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set new budgets for this period. The current design is kept in '
            'the plan history so you can compare later.',
            style: context.styles.caption,
          ),
          const SizedBox(height: 16),
          ...widget.items.map(_buildItemRow),
          const SizedBox(height: 8),
          _buildTotal(),
          const SizedBox(height: 16),
          Text('Reason (optional)', style: context.styles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: context.styles.input(
              hint: 'e.g. Fuel came in under, food is short',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
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
        ],
      ),
    );
  }

  Widget _buildItemRow(PlanItem item) {
    final changed = _amountOf(item) != item.expectedAmount;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: context.styles.card,
      child: Row(
        children: [
          context.styles.iconBox(icon: PlanItemIcon.getIcon(item.iconIndex)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: context.styles.bodyLarge),
                Text(
                  'Spent ${CurrencyUtils.formatCurrency(item.actualAmount)}'
                  '${changed ? ' · was ${CurrencyUtils.formatCurrency(item.expectedAmount)}' : ''}',
                  style: context.styles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controllers[item.id],
              textAlign: TextAlign.end,
              decoration: context.styles.input(hint: '0', prefixText: '฿ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    final income = widget.plan.expectedIncome;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total planned', style: context.styles.label),
        Text(
          income == null
              ? CurrencyUtils.formatCurrency(_totalPlanned)
              : '${CurrencyUtils.formatCurrency(_totalPlanned)} / ${CurrencyUtils.formatCurrency(income)}',
          style: context.styles.bodyLarge.copyWith(
            color: _isOverIncome ? context.colors.expense : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
