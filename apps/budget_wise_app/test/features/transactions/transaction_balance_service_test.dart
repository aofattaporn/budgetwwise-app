import 'package:app_template/features/accounts/domain/entities/account.dart';
import 'package:app_template/features/accounts/domain/repositories/account_repository.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:app_template/features/transactions/domain/services/transaction_balance_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [AccountRepository] so the service can be tested without Supabase.
class _FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _store;

  _FakeAccountRepository(List<Account> accounts)
      : _store = {for (final a in accounts) a.id: a};

  double balanceOf(String id) => _store[id]!.balance;

  @override
  Future<List<Account>> getAccounts() async => _store.values.toList();

  @override
  Future<Account> updateAccount(Account account) async {
    _store[account.id] = account;
    return account;
  }

  @override
  Future<Account> createAccount(Account account) async {
    _store[account.id] = account;
    return account;
  }

  @override
  Future<void> deleteAccount(String id) async => _store.remove(id);
}

Account _account(String id, double balance) => Account(
      id: id,
      name: id,
      type: 'cash',
      openingBalance: balance,
      balance: balance,
      currency: 'USD',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Transaction _txn({
  required TransactionType type,
  required double amount,
  String accountId = 'src',
  String? destinationAccountId,
}) =>
    Transaction(
      id: 't1',
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      type: type,
      amount: amount,
      occurredAt: DateTime(2026),
    );

void main() {
  group('TransactionBalanceService.applyImpact', () {
    test('expense decreases the source balance', () async {
      final repo = _FakeAccountRepository([_account('src', 100)]);
      final service = TransactionBalanceService(repo);

      await service.applyImpact(_txn(type: TransactionType.expense, amount: 30));

      expect(repo.balanceOf('src'), 70);
    });

    test('income increases the source balance', () async {
      final repo = _FakeAccountRepository([_account('src', 100)]);
      final service = TransactionBalanceService(repo);

      await service.applyImpact(_txn(type: TransactionType.income, amount: 30));

      expect(repo.balanceOf('src'), 130);
    });

    test('transfer moves the amount from source to destination', () async {
      final repo = _FakeAccountRepository([
        _account('src', 100),
        _account('dst', 50),
      ]);
      final service = TransactionBalanceService(repo);

      await service.applyImpact(_txn(
        type: TransactionType.transfer,
        amount: 30,
        destinationAccountId: 'dst',
      ));

      expect(repo.balanceOf('src'), 70);
      expect(repo.balanceOf('dst'), 80);
    });
  });

  group('TransactionBalanceService.reverseImpact', () {
    test('reverses an expense by adding the amount back', () async {
      final repo = _FakeAccountRepository([_account('src', 70)]);
      final service = TransactionBalanceService(repo);

      await service
          .reverseImpact(_txn(type: TransactionType.expense, amount: 30));

      expect(repo.balanceOf('src'), 100);
    });

    test('reverses an income by deducting the amount', () async {
      final repo = _FakeAccountRepository([_account('src', 130)]);
      final service = TransactionBalanceService(repo);

      await service
          .reverseImpact(_txn(type: TransactionType.income, amount: 30));

      expect(repo.balanceOf('src'), 100);
    });

    test('reverses a transfer on both accounts', () async {
      final repo = _FakeAccountRepository([
        _account('src', 70),
        _account('dst', 80),
      ]);
      final service = TransactionBalanceService(repo);

      await service.reverseImpact(_txn(
        type: TransactionType.transfer,
        amount: 30,
        destinationAccountId: 'dst',
      ));

      expect(repo.balanceOf('src'), 100);
      expect(repo.balanceOf('dst'), 50);
    });
  });

  test('apply then reverse round-trips to the original balances', () async {
    final repo = _FakeAccountRepository([
      _account('src', 100),
      _account('dst', 50),
    ]);
    final service = TransactionBalanceService(repo);
    final transfer = _txn(
      type: TransactionType.transfer,
      amount: 42.5,
      destinationAccountId: 'dst',
    );

    await service.applyImpact(transfer);
    await service.reverseImpact(transfer);

    expect(repo.balanceOf('src'), 100);
    expect(repo.balanceOf('dst'), 50);
  });
}
