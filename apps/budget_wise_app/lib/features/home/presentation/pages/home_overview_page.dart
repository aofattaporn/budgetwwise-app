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
            if (state.hasActivePlan) _buildBudgetSummaryCard(state),
            if (state.hasActivePlan) _buildCashFlowSummary(state),
            if (!state.hasActivePlan) _buildNoPlanCard(),
            _buildTodayItemsCard(state),
            _buildAccountsCard(state),
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
  // BUILD - TODAY'S ITEMS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compact summary of today's activity. Tapping opens a bottom sheet that
  /// lists every transaction logged today.
  Widget _buildTodayItemsCard(HomeState state) {
    final items = state.todayTransactions;
    final count = items.length;
    final expenseTotal = state.todayExpenseTotal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: count == 0 ? null : () => _showTodayItemsSheet(state),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: context.styles.card,
          child: Row(
            children: [
              context.styles.iconBox(
                icon: Icons.today_rounded,
                bgColor: context.colors.accent.withValues(alpha: 0.08),
                iconColor: context.colors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items Today', style: context.styles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'No transactions yet today'
                          : '$count ${count == 1 ? 'item' : 'items'} · spent ${CurrencyUtils.formatCurrency(expenseTotal)}',
                      style: context.styles.caption,
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Icon(Icons.chevron_right_rounded,
                    color: context.colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodayItemsSheet(HomeState state) {
    final items = state.todayTransactions;
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                context.styles.sheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text('Today', style: context.styles.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    '$dateLabel · ${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: context.styles.caption,
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    shrinkWrap: true,
                    children: items.map(_buildTransactionRow).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    // Branded blue hero for the active plan. Fixed gradient (not theme accent)
    // so white text keeps strong contrast in both light and dark, consistent
    // with the Accounts and Plans heroes.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Plan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: daysLeft <= 3
                      ? const Color(0xFFEF4444)
                      : Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: Text(
                  daysLeftText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            plan.formattedPeriod,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Remaining Budget',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatCurrency(remaining),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyUtils.formatCurrency(spent)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 12,
                ),
              ),
              Text(
                'Budget: ${CurrencyUtils.formatCurrency(budget)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 12,
                ),
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
          IntrinsicHeight(
            child: Row(
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
                      '${fmt(state.realRemainingBudget)} − '
                      '${fmt(state.remainingExpectedExpenses)}',
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.colors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_rounded, size: 28, color: context.colors.accent),
          ),
          const SizedBox(height: 16),
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
  // BUILD - ACCOUNTS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compact summary of all accounts. Tapping opens a bottom sheet that lists
  /// every account with its balance.
  Widget _buildAccountsCard(HomeState state) {
    final count = state.accountCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: count == 0 ? null : () => _showAccountsSheet(state),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: context.styles.card,
          child: Row(
            children: [
              context.styles.iconBox(
                icon: Icons.account_balance_wallet_rounded,
                bgColor: context.colors.accent.withValues(alpha: 0.08),
                iconColor: context.colors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Accounts', style: context.styles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'No accounts yet'
                          : '$count ${count == 1 ? 'account' : 'accounts'} · ${CurrencyUtils.formatCurrency(state.totalBalance)}',
                      style: context.styles.caption,
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Icon(Icons.chevron_right_rounded,
                    color: context.colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountsSheet(HomeState state) {
    final accounts = state.accounts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                context.styles.sheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text('Accounts', style: context.styles.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Total ${CurrencyUtils.formatCurrency(state.totalBalance)}',
                    style: context.styles.caption,
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    shrinkWrap: true,
                    children: accounts.map(_buildAccountRow).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  // BUILD - TRANSACTION ROW (shared by the Today bottom sheet)
  // ═══════════════════════════════════════════════════════════════════════════

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
