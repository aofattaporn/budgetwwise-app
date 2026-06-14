import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../di/injection.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../transactions/domain/services/transaction_balance_service.dart';
import '../../../transactions/presentation/bloc/transaction_editor_bloc.dart';
import '../../../transactions/presentation/pages/transaction_editor_page.dart';
import '../bloc/account_bloc.dart';
import 'account_create_screen.dart';

class AccountDetailPage extends StatefulWidget {
  final Account account;

  const AccountDetailPage({super.key, required this.account});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late Account _account;
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txns = await getIt<TransactionRepository>()
          .getTransactionsByAccountId(_account.id);
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

  Future<void> _navigateToEditAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AccountBloc>(),
          child: AccountCreateScreen(account: _account),
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      context.read<AccountBloc>().add(const RefreshAccountsRequested());
      // Refresh account from list
      final bloc = context.read<AccountBloc>();
      await bloc.stream
          .firstWhere((s) => s is AccountLoaded || s is AccountError)
          .timeout(const Duration(seconds: 5), onTimeout: () => bloc.state);
      if (mounted) {
        final state = bloc.state;
        if (state is AccountLoaded) {
          final updated =
              state.accounts.where((a) => a.id == _account.id).firstOrNull;
          if (updated != null) {
            setState(() => _account = updated);
          }
        }
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_transactions.isNotEmpty) {
      context.showSnackBar(
        'Cannot delete account with ${_transactions.length} transaction(s). Remove them first.',
        isError: true,
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete "${_account.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      context.read<AccountBloc>().add(DeleteAccountRequested(_account.id));
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
      context.read<AccountBloc>().add(const RefreshAccountsRequested());
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
        context.read<AccountBloc>().add(const RefreshAccountsRequested());
        // Update local account balance
        final bloc = context.read<AccountBloc>();
        await bloc.stream
            .firstWhere((s) => s is AccountLoaded || s is AccountError)
            .timeout(const Duration(seconds: 5), onTimeout: () => bloc.state);
        if (mounted) {
          final state = bloc.state;
          if (state is AccountLoaded) {
            final updated =
                state.accounts.where((a) => a.id == _account.id).firstOrNull;
            if (updated != null) {
              setState(() => _account = updated);
            }
          }
        }
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
                context.styles.sheetHandle(),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: context.styles.appBar(
        title: _account.name,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _navigateToEditAccount),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDeleteAccount),
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
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: context.styles.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              context.styles.iconBox(
                icon: _getIconForType(_account.type),
                size: AppDimens.iconMd,
                bgColor: _getColorForType(_account.type).withValues(alpha: 0.12),
                iconColor: _getColorForType(_account.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_account.name, style: context.styles.titleLarge),
                    const SizedBox(height: 2),
                    Text(_getTypeName(_account.type), style: context.styles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Current Balance', CurrencyUtils.formatCurrency(_account.balance), isBold: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: context.colors.divider),
          ),
          _buildInfoRow('Opening Balance', CurrencyUtils.formatCurrency(_account.openingBalance)),
          const SizedBox(height: 10),
          _buildInfoRow('Currency', _account.currency),
          const SizedBox(height: 10),
          _buildInfoRow('Created', DateFormat('MMM d, yyyy').format(_account.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.styles.bodySmall),
        Text(
          value,
          style: isBold ? context.styles.titleLarge : context.styles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction History', style: context.styles.titleMedium),
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
          Icon(Icons.receipt_long_outlined, size: 32, color: context.colors.textTertiary),
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
    final iconColor = isExpense ? context.colors.expense : isIncome ? context.colors.income : context.colors.accent;
    final bgColor = isExpense ? context.colors.expenseLight : isIncome ? context.colors.incomeLight : context.colors.accentLight;
    final amountPrefix = isExpense ? '-' : isIncome ? '+' : '';
    final amountColor = isExpense ? context.colors.expense : isIncome ? context.colors.income : context.colors.textPrimary;

    return GestureDetector(
      onTap: () => _showTransactionActionSheet(txn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: context.styles.card,
        child: Row(
          children: [
            context.styles.iconBox(icon: icon, size: 36, bgColor: bgColor, iconColor: iconColor),
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
                  Text(timeFormat.format(txn.occurredAt), style: context.styles.caption),
                ],
              ),
            ),
            Text(
              '$amountPrefix${CurrencyUtils.formatCurrency(txn.amount)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  IconData _getIconForType(String type) {
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

  String _getTypeName(String type) {
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

  /// Distinct, subtle accent hue per account type (matches the accounts list).
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return const Color(0xFFF59E0B); // amber
      case 'ewallet':
      case 'e-wallet':
        return const Color(0xFF14B8A6); // teal
      case 'bank':
      case 'debit':
      default:
        return const Color(0xFF3B82F6); // blue
    }
  }
}
