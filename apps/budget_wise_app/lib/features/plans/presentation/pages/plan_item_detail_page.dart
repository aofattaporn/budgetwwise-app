import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../di/injection.dart';
import '../../../../domain/entities/plan_item.dart';
import 'plan_item_editor_page.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../transactions/domain/services/transaction_balance_service.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../transactions/presentation/bloc/transaction_editor_bloc.dart';
import '../../../transactions/presentation/pages/transaction_editor_page.dart';
import '../bloc/active_plan_bloc.dart';

class PlanItemDetailPage extends StatefulWidget {
  final PlanItem item;

  const PlanItemDetailPage({super.key, required this.item});

  @override
  State<PlanItemDetailPage> createState() => _PlanItemDetailPageState();
}

class _PlanItemDetailPageState extends State<PlanItemDetailPage> {
  late PlanItem _item;
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txns = await getIt<TransactionRepository>()
          .getTransactionsByPlanItemId(_item.id);
      if (mounted) {
        setState(() {
          _transactions = txns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showSnackBar('Failed to load transactions: $e', isError: true);
      }
    }
  }

  Future<void> _navigateToEditItem() async {
    final state = context.read<ActivePlanBloc>().state;
    if (state.plan == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PlanItemEditorPage(
          plan: state.plan!,
          existingItem: _item,
          currentTotalPlanned: state.totalPlannedExpenses,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      context.read<ActivePlanBloc>().add(
            UpdatePlanItemRequested(
              itemId: _item.id,
              name: result['name'] as String,
              description: result['description'] as String?,
              expectedAmount: result['amount'] as double,
              iconIndex: result['iconIndex'] as int?,
            ),
          );
      // Refresh the plan to get updated item
      context.read<ActivePlanBloc>().add(const RefreshActivePlan());
      // Update local item with new values
      setState(() {
        _item = _item.copyWith(
          name: result['name'] as String,
          description: result['description'] as String?,
          expectedAmount: result['amount'] as double,
          iconIndex: result['iconIndex'] as int?,
        );
      });
    }
  }

  Future<void> _confirmDeleteItem() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "${_item.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      context.read<ActivePlanBloc>().add(DeletePlanItemRequested(_item.id));
      Navigator.pop(context, true);
    }
  }

  Future<void> _navigateToEditTransaction(Transaction txn) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => TransactionEditorBloc(
            transactionRepository: getIt<TransactionRepository>(),
            accountRepository: getIt<AccountRepository>(),
            planRepository: getIt<PlanRepository>(),
          ),
          child: TransactionEditorPage(transaction: txn),
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      _loadTransactions();
      context.read<ActivePlanBloc>().add(const RefreshActivePlan());
    }
  }

  Future<void> _confirmDeleteTransaction(Transaction txn) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction? '
          'The account balance will be reverted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await getIt<TransactionBalanceService>().reverseImpact(txn);

      await getIt<TransactionRepository>().deleteTransaction(txn.id);
      getIt<PlanRepository>().invalidateCache();

      if (mounted) {
        context.showSnackBar('Transaction deleted');
        _loadTransactions();
        context.read<ActivePlanBloc>().add(const RefreshActivePlan());
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  void _showTransactionActionSheet(Transaction txn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading:
                      Icon(Icons.edit_outlined, color: context.colors.accent),
                  title: const Text('Edit Transaction'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _navigateToEditTransaction(txn);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: context.colors.expense),
                  title: Text('Delete Transaction',
                      style: TextStyle(color: context.colors.expense)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteTransaction(txn);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(
        title: _item.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEditItem,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: _confirmDeleteItem,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: _loadTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              _buildTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final progressColor = _item.isOverBudget
        ? context.colors.expense
        : _item.isNearLimit
            ? const Color(0xFFB1A296)
            : context.colors.accent;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              context.styles.iconBox(icon: PlanItemIcon.getIcon(_item.iconIndex)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_item.name, style: context.styles.titleLarge),
                    const SizedBox(height: 2),
                    Text('Expense Category', style: context.styles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Planned', CurrencyUtils.formatCurrency(_item.expectedAmount)),
          const SizedBox(height: 10),
          _buildInfoRow('Actual', CurrencyUtils.formatCurrency(_item.actualAmount)),
          const SizedBox(height: 10),
          _buildInfoRow(
            _item.isOverBudget ? 'Over Budget' : 'Remaining',
            CurrencyUtils.formatCurrency(
                _item.isOverBudget ? _item.overAmount : _item.remainingAmount),
            valueColor: _item.isOverBudget ? context.colors.expense : context.colors.income,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _item.progressPercentage,
              backgroundColor: context.colors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          if (_item.isOverBudget || _item.isNearLimit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _item.isOverBudget
                      ? Icons.error_outline
                      : Icons.warning_amber_outlined,
                  size: 14,
                  color: progressColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _item.isOverBudget ? 'Over planned amount' : 'Near limit',
                  style: TextStyle(fontSize: 12, color: progressColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.styles.bodySmall),
        Text(
          value,
          style: context.styles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referenced Transactions',
            style: context.styles.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'}',
            style: context.styles.caption,
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: context.colors.primary),
              ),
            )
          else if (_transactions.isEmpty)
            _buildEmptyTransactions()
          else
            ..._transactions.map(_buildTransactionRow),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: context.styles.card,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 36, color: context.colors.textTertiary),
          const SizedBox(height: 8),
          Text('No transactions yet', style: context.styles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction txn) {
    final timeFormat = DateFormat('MMM d, HH:mm');
    final isExpense = txn.type == TransactionType.expense;
    final isIncome = txn.type == TransactionType.income;

    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : isIncome
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz;
    final iconColor = isExpense
        ? context.colors.expense
        : isIncome
            ? context.colors.income
            : context.colors.accent;
    final amountPrefix = isExpense ? '-' : isIncome ? '+' : '';
    final amountColor = isExpense
        ? context.colors.expense
        : isIncome
            ? context.colors.income
            : context.colors.textPrimary;

    return GestureDetector(
      onTap: () => _showTransactionActionSheet(txn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: context.styles.card,
        child: Row(
          children: [
            context.styles.iconBox(
              icon: icon,
              size: 36,
              bgColor: iconColor.withValues(alpha: 0.1),
              iconColor: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ??
                        txn.type.name[0].toUpperCase() +
                            txn.type.name.substring(1),
                    style: context.styles.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormat.format(txn.occurredAt),
                    style: context.styles.caption,
                  ),
                ],
              ),
            ),
            Text(
              '$amountPrefix${CurrencyUtils.formatCurrency(txn.amount)}',
              style: context.styles.bodyLarge.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
