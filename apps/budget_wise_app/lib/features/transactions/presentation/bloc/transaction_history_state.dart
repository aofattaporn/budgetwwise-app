part of 'transaction_history_bloc.dart';

enum TransactionHistoryStatus { initial, loading, loaded, error }

class TransactionHistoryState extends Equatable {
  final TransactionHistoryStatus status;
  final List<Transaction> transactions;
  final DateTime selectedMonth;
  final TransactionType? typeFilter;
  final String? errorMessage;

  const TransactionHistoryState({
    required this.status,
    required this.transactions,
    required this.selectedMonth,
    this.typeFilter,
    this.errorMessage,
  });

  factory TransactionHistoryState.initial() {
    final now = DateTime.now();
    return TransactionHistoryState(
      status: TransactionHistoryStatus.initial,
      transactions: const [],
      selectedMonth: DateTime(now.year, now.month),
    );
  }

  /// Filtered transactions based on type filter
  List<Transaction> get filteredTransactions {
    if (typeFilter == null) return transactions;
    return transactions.where((t) => t.type == typeFilter).toList();
  }

  /// Group filtered transactions by date
  Map<DateTime, List<Transaction>> get groupedTransactions {
    final map = <DateTime, List<Transaction>>{};
    for (final txn in filteredTransactions) {
      final dateKey = DateTime(
        txn.occurredAt.year,
        txn.occurredAt.month,
        txn.occurredAt.day,
      );
      map.putIfAbsent(dateKey, () => []).add(txn);
    }
    return map;
  }

  double get totalIncome => filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get netAmount => totalIncome - totalExpense;

  TransactionHistoryState copyWith({
    TransactionHistoryStatus? status,
    List<Transaction>? transactions,
    DateTime? selectedMonth,
    TransactionType? typeFilter,
    bool clearTypeFilter = false,
    String? errorMessage,
  }) {
    return TransactionHistoryState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        selectedMonth,
        typeFilter,
        errorMessage,
      ];
}
