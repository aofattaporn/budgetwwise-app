import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<List<Transaction>> getRecentTransactions({int limit = 5});
  Future<Transaction> createTransaction(Transaction transaction);
  Future<Transaction> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<int> countByAccountId(String accountId);
  Future<int> countByPlanItemId(String planItemId);
  Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  });
}
