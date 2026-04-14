part of 'transaction_history_bloc.dart';

abstract class TransactionHistoryEvent extends Equatable {
  const TransactionHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionHistory extends TransactionHistoryEvent {
  const LoadTransactionHistory();
}

class RefreshTransactionHistory extends TransactionHistoryEvent {
  const RefreshTransactionHistory();
}

class ChangeMonth extends TransactionHistoryEvent {
  final DateTime month;
  const ChangeMonth(this.month);

  @override
  List<Object?> get props => [month];
}

class ChangeTypeFilter extends TransactionHistoryEvent {
  final TransactionType? type;
  const ChangeTypeFilter(this.type);

  @override
  List<Object?> get props => [type];
}
