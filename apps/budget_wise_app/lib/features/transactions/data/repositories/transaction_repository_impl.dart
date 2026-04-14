import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remote;

  TransactionRepositoryImpl(this.remote);

  @override
  Future<List<Transaction>> getTransactions() async {
    final models = await remote.fetchTransactions();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    final models = await remote.fetchRecentTransactions(limit: limit);
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final created = await remote.createTransaction(model);
    return created.toEntity();
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final updated = await remote.updateTransaction(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await remote.deleteTransaction(id);
  }

  @override
  Future<int> countByAccountId(String accountId) async {
    return await remote.countByAccountId(accountId);
  }

  @override
  Future<int> countByPlanItemId(String planItemId) async {
    return await remote.countByPlanItemId(planItemId);
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final models = await remote.fetchByDateRange(start: start, end: end);
    return models.map((e) => e.toEntity()).toList();
  }
}
