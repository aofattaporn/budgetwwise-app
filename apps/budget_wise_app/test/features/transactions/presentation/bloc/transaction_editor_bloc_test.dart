import 'package:app_template/domain/repositories/plan_repository.dart';
import 'package:app_template/features/accounts/domain/entities/account.dart';
import 'package:app_template/features/accounts/domain/repositories/account_repository.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:app_template/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:app_template/features/transactions/presentation/bloc/transaction_editor_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fakes: only the methods exercised by the submit path are
/// implemented; everything else routes to [noSuchMethod] and throws, which
/// keeps the unused surface from being silently relied upon.
class _FakeTransactionRepository implements TransactionRepository {
  int createCount = 0;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    createCount++;
    return transaction;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAccountRepository implements AccountRepository {
  final Map<String, Account> store;

  _FakeAccountRepository(List<Account> accounts)
      : store = {for (final a in accounts) a.id: a};

  @override
  Future<List<Account>> getAccounts() async => store.values.toList();

  @override
  Future<Account> updateAccount(Account account) async {
    store[account.id] = account;
    return account;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePlanRepository implements PlanRepository {
  int invalidateCount = 0;

  @override
  void invalidateCache() => invalidateCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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

void main() {
  late _FakeTransactionRepository txnRepo;
  late _FakeAccountRepository accRepo;
  late _FakePlanRepository planRepo;

  TransactionEditorBloc build() => TransactionEditorBloc(
        transactionRepository: txnRepo,
        accountRepository: accRepo,
        planRepository: planRepo,
      );

  setUp(() {
    txnRepo = _FakeTransactionRepository();
    accRepo = _FakeAccountRepository([_account('a1', 100)]);
    planRepo = _FakePlanRepository();
  });

  group('TransactionEditorBloc validation', () {
    test('rejects submit with no amount and creates nothing', () async {
      final bloc = build();
      bloc.add(const TransactionEditorSubmitted());

      final errored =
          await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(errored.errorMessage, contains('Amount'));
      expect(txnRepo.createCount, 0);
      await bloc.close();
    });

    test('rejects submit with no account selected', () async {
      final bloc = build();
      bloc.add(const TransactionAmountChanged('50'));
      bloc.add(const TransactionEditorSubmitted());

      final errored =
          await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(errored.errorMessage, contains('account'));
      expect(txnRepo.createCount, 0);
      await bloc.close();
    });
  });

  test('valid expense creates the transaction, deducts balance, invalidates cache',
      () async {
    final bloc = build();
    bloc.add(const TransactionAmountChanged('30'));
    bloc.add(const TransactionAccountChanged('a1'));
    bloc.add(const TransactionEditorSubmitted());

    await bloc.stream
        .firstWhere((s) => s.status == TransactionEditorStatus.success);

    expect(txnRepo.createCount, 1);
    expect(accRepo.store['a1']!.balance, 70); // 100 - 30
    expect(planRepo.invalidateCount, 1);
    await bloc.close();
  });
}
