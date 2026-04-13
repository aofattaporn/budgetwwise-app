import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/account.dart';
import '../bloc/account_bloc.dart';
import '../widgets/dashed_border_painter.dart';
import 'account_create_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Account Screen - Main accounts list view
/// Displays all user accounts with total balance summary
/// ═══════════════════════════════════════════════════════════════════════════
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(const FetchAccountsRequested());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Navigate to create account screen
  Future<void> _navigateToCreateAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AccountBloc>(),
          child: const AccountCreateScreen(),
        ),
        fullscreenDialog: true,
      ),
    );

    // Refresh accounts list if account was created
    if (result == true && mounted) {
      context.read<AccountBloc>().add(const FetchAccountsRequested());
    }
  }

  /// Handle account item tap - navigate to edit
  Future<void> _onAccountTap(Account account) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AccountBloc>(),
          child: AccountCreateScreen(account: account),
        ),
      ),
    );

    // Refresh accounts list if account was updated
    if (result == true && mounted) {
      context.read<AccountBloc>().add(const FetchAccountsRequested());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOG METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAccountMenu(Account account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Menu options
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Account'),
              onTap: () {
                Navigator.pop(context);
                _onAccountTap(account);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[700]),
              title: Text(
                'Delete Account',
                style: TextStyle(color: Colors.red[700]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(account);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AccountBloc>().add(DeleteAccountRequested(account.id));
      
      // Wait a moment then refresh
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.read<AccountBloc>().add(const FetchAccountsRequested());
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - MAIN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _buildAppBar(),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildBody(state),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - STATES
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF4D648D),
      elevation: 0,
      title: const Text(
        'Accounts',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _navigateToCreateAccount,
        ),
      ],
    );
  }

  void _handleStateChanges(BuildContext context, AccountState state) {
    if (state is AccountError) {
      context.showSnackBar(state.message, isError: true);
    }
  }

  Widget _buildBody(AccountState state) {
    if (state is AccountLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4D648D),
        ),
      );
    }

    if (state is AccountLoaded) {
      return _buildAccountsList(state);
    }

    if (state is AccountError) {
      return _buildErrorState(state.message);
    }

    // Initial state
    return const SizedBox.shrink();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AccountBloc>().add(const FetchAccountsRequested());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D648D),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - ACCOUNT LIST CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountsList(AccountLoaded state) {
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AccountBloc>().add(const RefreshAccountsRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Total balance summary
            _buildTotalBalanceSummary(state, currencyFormat),
            
            // Accounts section header
            _buildSectionHeader(state.accountCount),
            
            // Accounts list
            _buildAccountsListView(state.accounts),
            
            // Add account button
            _buildAddAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceSummary(
    AccountLoaded state,
    NumberFormat currencyFormat,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(state.totalBalance),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.normal,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Across ${state.accountCount} ${state.accountCount == 1 ? 'account' : 'accounts'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Your Accounts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsListView(List<Account> accounts) {
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No accounts yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add an account to start tracking your finances',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _AccountCard(
          account: account,
          onTap: () => _onAccountTap(account),
          onMenuTap: () => _showAccountMenu(account),
        );
      },
    );
  }

  Widget _buildAddAccountButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: _navigateToCreateAccount,
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: const Color(0xFFD4D4D4),
            strokeWidth: 2,
            borderRadius: 8,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 24,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add New Account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Account Card Widget - Individual account display
/// ═══════════════════════════════════════════════════════════════════════════
class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            // Header row with icon, name, and menu
            Row(
              children: [
                // Account icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(account.type),
                    color: const Color(0xFF4D648D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Account name and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeName(account.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu button
                IconButton(
                  onPressed: onMenuTap,
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            
            // Balance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  currencyFormat.format(account.balance),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for account type
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

  /// Get display name for account type
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
}


