import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../di/injection.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../transactions/domain/services/transaction_balance_service.dart';
import '../../../accounts/presentation/bloc/account_bloc.dart';
import '../../../plans/presentation/bloc/active_plan_bloc.dart';
import '../../../main/presentation/pages/main_app_shell.dart';
import '../../../transactions/transactions.dart';
import '../bloc/home_bloc.dart';

/// Home Overview Page - Main dashboard showing financial summary
///
/// This page displays:
/// - Total balance across all accounts
/// - Active plan budget summary
/// - Account list overview
/// - Recent transactions placeholder (pending transactions feature)
class HomeOverviewPage extends StatefulWidget {
  const HomeOverviewPage({super.key});

  @override
  State<HomeOverviewPage> createState() => _HomeOverviewPageState();
}

class _HomeOverviewPageState extends State<HomeOverviewPage> {
  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  void _setProcessing(bool value) {
    final overlay = ProcessingOverlay.of(context);
    if (value) {
      overlay?.show();
    } else {
      overlay?.hide();
    }
  }

  /// Wait for the HomeBloc to finish refreshing before hiding overlay
  Future<void> _waitForRefreshComplete() async {
    final bloc = context.read<HomeBloc>();
    // Wait for the bloc to emit a non-loading state (loaded/error)
    await bloc.stream.firstWhere(
      (s) => s.status == HomeStatus.loaded || s.status == HomeStatus.error,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () => bloc.state,
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeData());
  }

  void _refreshData() {
    context.read<HomeBloc>().add(const RefreshHomeData());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: _handleStateChanges,
          builder: _buildBody,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'homeCreateTransaction',
        onPressed: _navigateToCreateTransaction,
        backgroundColor: context.colors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
      // Reverse balance impact, then delete
      await getIt<TransactionBalanceService>().reverseImpact(txn);

      await getIt<TransactionRepository>().deleteTransaction(txn.id);

      // Invalidate plan cache so actuals are recomputed
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
        context.showSnackBar('Failed to delete transaction: $e', isError: true);
      }
    }
  }

  void _refreshAllScreens() {
    _refreshData();
    context.read<AccountBloc>().add(const RefreshAccountsRequested());
    context.read<ActivePlanBloc>().add(const RefreshActivePlan());
    context.read<TransactionHistoryBloc>().add(const RefreshTransactionHistory());
  }

  void _handleStateChanges(BuildContext context, HomeState state) {
    if (state.status == HomeStatus.error && state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
    }
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.status == HomeStatus.loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: context.colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state),
            _buildTotalBalanceCard(state),
            if (state.hasActivePlan) _buildBudgetSummaryCard(state),
            if (state.hasActivePlan) _buildCashFlowSummary(state),
            if (!state.hasActivePlan) _buildNoPlanCard(),
            _buildAccountsSection(state),
            _buildRecentTransactionsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(HomeState state) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getGreeting(), style: context.styles.displayMedium),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(now),
            style: context.styles.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - TOTAL BALANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTotalBalanceCard(HomeState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Balance', style: context.styles.label),
              Text(
                '${state.accountCount} ${state.accountCount == 1 ? 'account' : 'accounts'}',
                style: context.styles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyUtils.formatCurrency(state.totalBalance),
            style: context.styles.displayLarge,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - BUDGET SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetSummaryCard(HomeState state) {
    final plan = state.activePlan!;
    final spent = state.totalActualExpenses;
    final budget = state.totalPlannedExpenses;
    final remaining = state.remainingBudget;
    final progress = budget > 0 ? (remaining / budget).clamp(0.0, 1.0) : 0.0;
    final daysLeft = plan.endDate.difference(DateTime.now()).inDays + 1; 
    final daysLeftText = daysLeft < 0
        ? 'Ended'
        : daysLeft == 0
            ? 'Last day'
            : '$daysLeft days left';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Plan', style: context.styles.label),
              Text(daysLeftText, style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: daysLeft <= 3 ? context.colors.expense : context.colors.accent,
              )),
            ],
          ),
          const SizedBox(height: 4),
          Text(plan.name, style: context.styles.titleLarge),
          const SizedBox(height: 2),
          Text(plan.formattedPeriod, style: context.styles.caption),
          const SizedBox(height: 16),
          Text('Remaining Budget', style: context.styles.caption),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatCurrency(remaining),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: remaining >= 0 ? context.colors.textPrimary : context.colors.expense,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: context.colors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.15 ? context.colors.expense : context.colors.accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyUtils.formatCurrency(spent)}',
                style: context.styles.caption,
              ),
              Text(
                'Budget: ${CurrencyUtils.formatCurrency(budget)}',
                style: context.styles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - CASH FLOW SUMMARY (KPI grid)
  // ═══════════════════════════════════════════════════════════════════════════

  /// A 2×2 grid of key figures: total balance, free cash, overrun, and the
  /// budget that is genuinely still usable. Mirrors the report's KPI cards.
  Widget _buildCashFlowSummary(HomeState state) {
    final freeCash = state.freeCash;
    final overrun = state.totalOverrun;
    final realRemaining = state.realRemainingBudget;

    final fmt = CurrencyUtils.formatCurrency;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildKpiCard(
                  label: 'Balance รวมทุกบัญชี',
                  value: fmt(state.totalBalance),
                  valueColor: context.colors.textPrimary,
                  detail:
                      '${state.accountCount} ${state.accountCount == 1 ? 'account' : 'accounts'}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  label: 'Free Cash',
                  value: fmt(freeCash),
                  valueColor: freeCash >= 0
                      ? context.colors.income
                      : context.colors.expense,
                  detail: '${fmt(state.totalBalance)} − '
                      '${fmt(state.totalPlannedExpenses)} + '
                      '${fmt(state.actualIncome)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildKpiCard(
                  label: 'Overrun แล้ว',
                  value: overrun > 0 ? '-${fmt(overrun)}' : fmt(0),
                  valueColor: overrun > 0
                      ? context.colors.expense
                      : context.colors.textPrimary,
                  detail: overrun > 0
                      ? 'ใช้เกินงบในบางหมวด'
                      : 'ยังไม่มีหมวดไหนเกินงบ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  label: 'งบที่เหลือใช้ได้จริง',
                  value: fmt(realRemaining),
                  valueColor: context.colors.accent,
                  detail: 'รวมเฉพาะหมวดที่ยังไม่เกินงบ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color valueColor,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.styles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: context.styles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: context.styles.card,
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 32, color: context.colors.textTertiary),
          const SizedBox(height: 12),
          Text('No Active Plan', style: context.styles.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Create a plan to start tracking your budget',
            style: context.styles.bodySmall,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - ACCOUNTS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountsSection(HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accounts', style: context.styles.titleMedium),
          const SizedBox(height: 12),
          if (state.accounts.isEmpty)
            _buildNoAccountsCard()
          else
            ...state.accounts.map(_buildAccountRow),
        ],
      ),
    );
  }

  Widget _buildNoAccountsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: context.styles.card,
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 32, color: context.colors.textTertiary),
          const SizedBox(height: 12),
          Text('No accounts yet', style: context.styles.bodyLarge),
          const SizedBox(height: 4),
          Text('Add an account to start tracking', style: context.styles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAccountRow(Account account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: context.styles.card,
      child: Row(
        children: [
          context.styles.iconBox(icon: _getAccountIcon(account.type)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: context.styles.bodyLarge),
                const SizedBox(height: 2),
                Text(_getAccountTypeName(account.type), style: context.styles.caption),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatCurrency(account.balance),
            style: context.styles.bodyLarge,
          ),
        ],
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money_rounded;
      case 'bank':
        return Icons.account_balance;
      case 'debit':
        return Icons.credit_card;
      case 'ewallet':
      case 'e-wallet':
        return Icons.wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getAccountTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank Account';
      case 'debit':
        return 'Debit Card';
      case 'ewallet':
      case 'e-wallet':
        return 'E-Wallet';
      default:
        return type;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - RECENT TRANSACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentTransactionsSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Transactions', style: context.styles.titleMedium),
              const SizedBox(height: 12),
              if (state.recentTransactions.isEmpty)
                _buildNoTransactionsCard()
              else
                ...state.recentTransactions.map(_buildTransactionRow),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoTransactionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: context.styles.card,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 32, color: context.colors.textTertiary),
          const SizedBox(height: 12),
          Text('No transactions yet', style: context.styles.bodyLarge),
          const SizedBox(height: 4),
          Text('Transactions will appear here once recorded', style: context.styles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction txn) {
    final dateFormat = DateFormat('MMM d, HH:mm');
    final isExpense = txn.type == TransactionType.expense;
    final isIncome = txn.type == TransactionType.income;

    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : isIncome
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz_rounded;
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
        padding: const EdgeInsets.all(16),
        decoration: context.styles.card,
        child: Row(
          children: [
            context.styles.iconBox(
              icon: icon,
              bgColor: iconColor.withValues(alpha: 0.08),
              iconColor: iconColor,
              size: 40,
              iconSize: 18,
            ),
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
                  Text(dateFormat.format(txn.occurredAt), style: context.styles.caption),
                ],
              ),
            ),
            Text(
              '$amountPrefix${CurrencyUtils.formatCurrency(txn.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
