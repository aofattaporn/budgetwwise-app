import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../di/injection.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../domain/services/transaction_balance_service.dart';
import '../../../accounts/presentation/bloc/account_bloc.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../main/presentation/pages/main_app_shell.dart';
import '../../../plans/presentation/bloc/active_plan_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../bloc/transaction_editor_bloc.dart';
import '../bloc/transaction_history_bloc.dart';
import 'transaction_editor_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionHistoryBloc>().add(const LoadTransactionHistory());
  }

  void _setProcessing(bool value) {
    final overlay = ProcessingOverlay.of(context);
    if (value) {
      overlay?.show();
    } else {
      overlay?.hide();
    }
  }

  Future<void> _waitForRefreshComplete() async {
    final bloc = context.read<TransactionHistoryBloc>();
    await bloc.stream
        .firstWhere((s) =>
            s.status == TransactionHistoryStatus.loaded ||
            s.status == TransactionHistoryStatus.error)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => bloc.state,
        );
  }

  void _refreshAllScreens() {
    context.read<TransactionHistoryBloc>().add(const RefreshTransactionHistory());
    context.read<HomeBloc>().add(const RefreshHomeData());
    context.read<AccountBloc>().add(const RefreshAccountsRequested());
    context.read<ActivePlanBloc>().add(const RefreshActivePlan());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _navigateToCreateTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => TransactionEditorBloc(
            transactionRepository: getIt<TransactionRepository>(),
            accountRepository: getIt<AccountRepository>(),
            planRepository: getIt<PlanRepository>(),
          ),
          child: const TransactionEditorPage(),
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      _setProcessing(true);
      _refreshAllScreens();
      await _waitForRefreshComplete();
      if (mounted) _setProcessing(false);
    }
  }

  Future<void> _navigateToEditTransaction(Transaction transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => TransactionEditorBloc(
            transactionRepository: getIt<TransactionRepository>(),
            accountRepository: getIt<AccountRepository>(),
            planRepository: getIt<PlanRepository>(),
          ),
          child: TransactionEditorPage(transaction: transaction),
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      _setProcessing(true);
      _refreshAllScreens();
      await _waitForRefreshComplete();
      if (mounted) _setProcessing(false);
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
                context.styles.sheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    txn.description ?? txn.type.name[0].toUpperCase() + txn.type.name.substring(1),
                    style: context.styles.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: context.colors.accent),
                  title: const Text('Edit Transaction'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _navigateToEditTransaction(txn);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: context.colors.expense),
                  title: Text('Delete Transaction', style: TextStyle(color: context.colors.expense)),
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

    _setProcessing(true);

    try {
      await getIt<TransactionBalanceService>().reverseImpact(txn);

      await getIt<TransactionRepository>().deleteTransaction(txn.id);
      getIt<PlanRepository>().invalidateCache();

      if (mounted) {
        context.showSnackBar('Transaction deleted');
        _refreshAllScreens();
        await _waitForRefreshComplete();
        if (mounted) _setProcessing(false);
      }
    } catch (e) {
      _setProcessing(false);
      if (mounted) {
        context.showSnackBar('Failed to delete transaction: $e',
            isError: true);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTH NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _previousMonth() {
    final current =
        context.read<TransactionHistoryBloc>().state.selectedMonth;
    final prev = DateTime(current.year, current.month - 1);
    context.read<TransactionHistoryBloc>().add(ChangeMonth(prev));
  }

  void _nextMonth() {
    final current =
        context.read<TransactionHistoryBloc>().state.selectedMonth;
    final now = DateTime.now();
    final next = DateTime(current.year, current.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      context.read<TransactionHistoryBloc>().add(ChangeMonth(next));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: SafeArea(
        child: BlocConsumer<TransactionHistoryBloc, TransactionHistoryState>(
          listener: (context, state) {
            if (state.status == TransactionHistoryStatus.error &&
                state.errorMessage != null) {
              context.showSnackBar(state.errorMessage!, isError: true);
            }
          },
          builder: _buildBody,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'historyCreateTransaction',
        onPressed: _navigateToCreateTransaction,
        backgroundColor: context.colors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionHistoryState state) {
    return Column(
      children: [
        _buildHeader(state),
        _buildMonthSelector(state),
        _buildSummaryRow(state),
        _buildTypeFilter(state),
        Expanded(child: _buildTransactionList(state)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(TransactionHistoryState state) {
    final unplannedCount = state.transactions
        .where((t) => t.type == TransactionType.expense && t.planItemId == null && t.description?.toLowerCase().contains('rebalancing') != true)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        children: [
          Expanded(child: Text('Transactions', style: context.styles.displayMedium)),
          if (unplannedCount > 0)
            IconButton(
              tooltip: 'Unplanned expenses',
              onPressed: () => _showUnplannedExpenses(state),
              icon: Badge(
                label: Text('$unplannedCount'),
                child: Icon(Icons.assignment_late_outlined, color: context.colors.expense),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTH SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMonthSelector(TransactionHistoryState state) {
    final monthFormat = DateFormat('MMMM yyyy');
    final now = DateTime.now();
    final isCurrentMonth = state.selectedMonth.year == now.year &&
        state.selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(Icons.chevron_left, color: context.colors.accent),
            splashRadius: 20,
          ),
          Text(monthFormat.format(state.selectedMonth), style: context.styles.titleMedium),
          IconButton(
            onPressed: isCurrentMonth ? null : _nextMonth,
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? context.colors.textTertiary : context.colors.accent,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryRow(TransactionHistoryState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Row(
        children: [
          _buildSummaryItem('Income', state.totalIncome, context.colors.income),
          Container(width: 1, height: 36, color: context.colors.divider),
          _buildSummaryItem('Expense', state.totalExpense, context.colors.expense),
          Container(width: 1, height: 36, color: context.colors.divider),
          _buildSummaryItem(
            'Net',
            state.netAmount,
            state.netAmount >= 0 ? context.colors.income : context.colors.expense,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: context.styles.caption),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatCurrency(amount.abs()),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPE FILTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTypeFilter(TransactionHistoryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _buildFilterChip('All', null, state.typeFilter),
          const SizedBox(width: 8),
          _buildFilterChip('Expense', TransactionType.expense, state.typeFilter),
          const SizedBox(width: 8),
          _buildFilterChip('Income', TransactionType.income, state.typeFilter),
          const SizedBox(width: 8),
          _buildFilterChip('Transfer', TransactionType.transfer, state.typeFilter),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type, TransactionType? current) {
    final isSelected = (type == null && current == null) || (type != null && type == current);
    return GestureDetector(
      onTap: () {
        context.read<TransactionHistoryBloc>().add(
          ChangeTypeFilter(type == null ? null : (isSelected ? null : type)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.accent : context.colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.accent : context.colors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTION LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionList(TransactionHistoryState state) {
    if (state.status == TransactionHistoryStatus.loading ||
        state.status == TransactionHistoryStatus.initial) {
      return Center(child: CircularProgressIndicator(color: context.colors.primary));
    }

    final grouped = state.groupedTransactions;
    if (grouped.isEmpty) return _buildEmptyState();

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () async {
        context.read<TransactionHistoryBloc>().add(const RefreshTransactionHistory());
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          return _buildDateGroup(date, grouped[date]!);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 36, color: context.colors.textTertiary),
          const SizedBox(height: 16),
          Text('No transactions this month', style: context.styles.bodyLarge),
          const SizedBox(height: 4),
          Text('Tap + to add a transaction', style: context.styles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<Transaction> txns) {
    final dateFormat = DateFormat('EEEE, MMM d');
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
    final label = isToday ? 'Today' : isYesterday ? 'Yesterday' : dateFormat.format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: context.styles.label),
              GestureDetector(
                onTap: () => _showDaySummary(label, txns),
                child: Text(
                  'Summary',
                  style: context.styles.caption.copyWith(
                    color: context.colors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...txns.map(_buildTransactionRow),
      ],
    );
  }

  void _showDaySummary(String dateLabel, List<Transaction> txns) {
    double income = 0;
    double expense = 0;
    double transfer = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    int transferCount = 0;

    for (final txn in txns) {
      switch (txn.type) {
        case TransactionType.income:
          income += txn.amount;
          incomeCount++;
          break;
        case TransactionType.expense:
          expense += txn.amount;
          expenseCount++;
          break;
        case TransactionType.transfer:
          transfer += txn.amount;
          transferCount++;
          break;
      }
    }

    final net = income - expense;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                context.styles.sheetHandle(),
                const SizedBox(height: 8),
                Text(dateLabel, style: context.styles.titleMedium),
                Text(
                  '${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                  style: context.styles.caption,
                ),
                const SizedBox(height: 16),

                // Summary rows
                if (incomeCount > 0)
                  _buildSummarySheetRow(
                    Icons.arrow_upward_rounded,
                    context.colors.income,
                    'Income',
                    '$incomeCount txn${incomeCount == 1 ? '' : 's'}',
                    '+${CurrencyUtils.formatCurrency(income)}',
                  ),
                if (expenseCount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummarySheetRow(
                    Icons.arrow_downward_rounded,
                    context.colors.expense,
                    'Expense',
                    '$expenseCount txn${expenseCount == 1 ? '' : 's'}',
                    '-${CurrencyUtils.formatCurrency(expense)}',
                  ),
                ],
                if (transferCount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummarySheetRow(
                    Icons.swap_horiz,
                    context.colors.accent,
                    'Transfer',
                    '$transferCount txn${transferCount == 1 ? '' : 's'}',
                    CurrencyUtils.formatCurrency(transfer),
                  ),
                ],

                // Net
                const SizedBox(height: 12),
                Divider(height: 1, color: context.colors.divider),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net', style: context.styles.bodyLarge),
                    Text(
                      '${net >= 0 ? '+' : '-'}${CurrencyUtils.formatCurrency(net.abs())}',
                      style: context.styles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: net >= 0 ? context.colors.income : context.colors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySheetRow(
    IconData icon,
    Color color,
    String label,
    String count,
    String amount,
  ) {
    return Row(
      children: [
        context.styles.iconBox(
          icon: icon,
          size: 36,
          bgColor: color.withValues(alpha: 0.1),
          iconColor: color,
          iconSize: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.styles.bodyLarge),
              Text(count, style: context.styles.caption),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showUnplannedExpenses(TransactionHistoryState state) {
    final unplanned = state.transactions
        .where((t) => t.type == TransactionType.expense && t.planItemId == null)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (_, controller) {
            return SafeArea(
              child: Column(
                children: [
                  context.styles.sheetHandle(),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 18, color: context.colors.expense),
                        const SizedBox(width: 8),
                        Text('Unplanned Expenses', style: context.styles.titleMedium),
                        const Spacer(),
                        Text(
                          '${unplanned.length} item${unplanned.length == 1 ? '' : 's'}',
                          style: context.styles.caption,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.colors.divider),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: unplanned.length,
                      itemBuilder: (_, i) => _buildTransactionRow(unplanned[i]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionRow(Transaction txn) {
    final timeFormat = DateFormat('h:mm a');
    final isExpense = txn.type == TransactionType.expense;
    final isIncome = txn.type == TransactionType.income;
    final isUnplanned = isExpense && txn.planItemId == null;

    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : isIncome
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz;
    final iconColor = isExpense ? context.colors.expense : isIncome ? context.colors.income : context.colors.accent;
    final bgColor = isExpense ? context.colors.expenseLight : isIncome ? context.colors.incomeLight : context.colors.accentLight;
    final amountPrefix = isExpense ? '-' : isIncome ? '+' : '';
    final amountColor = isExpense ? context.colors.expense : isIncome ? context.colors.income : context.colors.textPrimary;

    final isRebalancing = txn.description?.toLowerCase().contains('rebalancing') ?? false;

    return GestureDetector(
      onTap: () => _showTransactionActionSheet(txn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: context.styles.card,
        child: Row(
          children: [
            context.styles.iconBox(icon: icon, size: 36, bgColor: isRebalancing ? context.colors.accentLight : bgColor, iconColor: isRebalancing ? context.colors.accent : iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ?? txn.type.name[0].toUpperCase() + txn.type.name.substring(1),
                    style: context.styles.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(timeFormat.format(txn.occurredAt), style: context.styles.caption),
                      if (isUnplanned && !isRebalancing) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: context.colors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No plan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: context.colors.expense,
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ], 
              ),
            ),
            Text(
              '$amountPrefix${CurrencyUtils.formatCurrency(txn.amount)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isRebalancing ? context.colors.accent : amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
