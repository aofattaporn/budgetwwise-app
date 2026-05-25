import '../../../accounts/domain/repositories/account_repository.dart';
import '../entities/transaction.dart';

/// Single source of truth for how a [Transaction] affects account balances.
///
/// The apply/reverse math used to be copy-pasted across the transaction editor
/// bloc and every delete call site, which let the implementations drift. All of
/// them now delegate here.
///
/// Sign conventions (apply): an `expense` decreases the source balance, an
/// `income` increases it, and a `transfer` moves the amount from source to
/// destination. [reverseImpact] applies the opposite of each.
class TransactionBalanceService {
  final AccountRepository _accountRepository;

  TransactionBalanceService(this._accountRepository);

  /// Apply a transaction's effect to the account balance(s).
  /// Call after creating a transaction.
  Future<void> applyImpact(Transaction txn) => _adjust(txn, reverse: false);

  /// Undo a transaction's effect on the account balance(s).
  /// Call before editing (with the original) and before deleting.
  Future<void> reverseImpact(Transaction txn) => _adjust(txn, reverse: true);

  Future<void> _adjust(Transaction txn, {required bool reverse}) async {
    final accounts = await _accountRepository.getAccounts();
    final source = accounts.firstWhere((a) => a.id == txn.accountId);

    switch (txn.type) {
      case TransactionType.expense:
        final delta = reverse ? txn.amount : -txn.amount;
        await _accountRepository.updateAccount(
          source.copyWith(balance: source.balance + delta),
        );
        break;
      case TransactionType.income:
        final delta = reverse ? -txn.amount : txn.amount;
        await _accountRepository.updateAccount(
          source.copyWith(balance: source.balance + delta),
        );
        break;
      case TransactionType.transfer:
        final sourceDelta = reverse ? txn.amount : -txn.amount;
        await _accountRepository.updateAccount(
          source.copyWith(balance: source.balance + sourceDelta),
        );
        if (txn.destinationAccountId != null) {
          final dest =
              accounts.firstWhere((a) => a.id == txn.destinationAccountId);
          final destDelta = reverse ? -txn.amount : txn.amount;
          await _accountRepository.updateAccount(
            dest.copyWith(balance: dest.balance + destDelta),
          );
        }
        break;
    }
  }
}
