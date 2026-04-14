import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Account Bloc
/// Manages account-related business logic and state
/// ═══════════════════════════════════════════════════════════════════════════
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _repository;
  final TransactionRepository _transactionRepository;

  AccountBloc({
    required AccountRepository repository,
    required TransactionRepository transactionRepository,
  })  : _repository = repository,
        _transactionRepository = transactionRepository,
        super(const AccountInitial()) {
    // Register event handlers
    on<FetchAccountsRequested>(_onFetchAccounts);
    on<CreateAccountRequested>(_onCreateAccount);
    on<UpdateAccountRequested>(_onUpdateAccount);
    on<DeleteAccountRequested>(_onDeleteAccount);
    on<RefreshAccountsRequested>(_onRefreshAccounts);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Event Handlers
  // ─────────────────────────────────────────────────────────────────────────

  /// Handle fetch accounts request
  Future<void> _onFetchAccounts(
    FetchAccountsRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());

    try {
      final accounts = await _repository.getAccounts();
      final totalBalance = _calculateTotalBalance(accounts);

      emit(AccountLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      emit(AccountError('Failed to fetch accounts: ${e.toString()}'));
    }
  }

  /// Handle create account request
  Future<void> _onCreateAccount(
    CreateAccountRequested event,
    Emitter<AccountState> emit,
  ) async {
    print('🔵 AccountBloc: Create account requested - ${event.account.name}');
    emit(const AccountLoading());

    try {
      print('🔵 AccountBloc: Calling repository.createAccount...');
      final createdAccount = await _repository.createAccount(event.account);
      print('✅ AccountBloc: Account created successfully - ID: ${createdAccount.id}');
      
      // Fetch updated accounts list
      print('🔵 AccountBloc: Fetching updated accounts list...');
      final accounts = await _repository.getAccounts();
      final totalBalance = _calculateTotalBalance(accounts);
      print('✅ AccountBloc: Loaded ${accounts.length} accounts, total: $totalBalance');

      emit(AccountLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      print('❌ AccountBloc: Create account failed - $e');
      emit(AccountError('Failed to create account: ${e.toString()}'));
    }
  }

  /// Handle update account request
  Future<void> _onUpdateAccount(
    UpdateAccountRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());

    try {
      print('🔄 [AccountBloc] Updating account: ${event.account.name}');
      await _repository.updateAccount(event.account);
      print('✅ [AccountBloc] Account updated successfully');
      
      // Fetch updated accounts list
      final accounts = await _repository.getAccounts();
      final totalBalance = _calculateTotalBalance(accounts);

      emit(AccountLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      print('❌ [AccountBloc] Error updating account: $e');
      emit(AccountError('Failed to update account: ${e.toString()}'));
    }
  }

  /// Handle delete account request
  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<AccountState> emit,
  ) async {
    // Check if any transactions reference this account
    try {
      final txnCount = await _transactionRepository.countByAccountId(event.accountId);
      if (txnCount > 0) {
        emit(AccountError(
          'Cannot delete — $txnCount ${txnCount == 1 ? 'transaction is' : 'transactions are'} linked. Delete them first.',
        ));
        // Re-fetch accounts so UI returns to loaded state
        final accounts = await _repository.getAccounts();
        final totalBalance = _calculateTotalBalance(accounts);
        emit(AccountLoaded(accounts: accounts, totalBalance: totalBalance));
        return;
      }
    } catch (e) {
      emit(AccountError('Failed to check transactions: ${e.toString()}'));
      return;
    }

    emit(const AccountLoading());

    try {
      print('🗑️ [AccountBloc] Deleting account: ${event.accountId}');
      await _repository.deleteAccount(event.accountId);
      print('✅ [AccountBloc] Account deleted successfully');
      
      // Fetch updated accounts list
      final accounts = await _repository.getAccounts();
      final totalBalance = _calculateTotalBalance(accounts);

      emit(AccountLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      print('❌ [AccountBloc] Error deleting account: $e');
      emit(AccountError('Failed to delete account: ${e.toString()}'));
    }
  }

  /// Handle refresh accounts request
  Future<void> _onRefreshAccounts(
    RefreshAccountsRequested event,
    Emitter<AccountState> emit,
  ) async {
    // Don't emit loading state for refresh to avoid UI flicker
    try {
      final accounts = await _repository.getAccounts();
      final totalBalance = _calculateTotalBalance(accounts);

      emit(AccountLoaded(
        accounts: accounts,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      emit(AccountError('Failed to refresh accounts: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculate total balance across all accounts
  double _calculateTotalBalance(List<Account> accounts) {
    return accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );
  }
}
