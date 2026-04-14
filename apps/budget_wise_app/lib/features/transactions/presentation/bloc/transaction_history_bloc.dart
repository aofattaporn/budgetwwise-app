import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'transaction_history_event.dart';
part 'transaction_history_state.dart';

class TransactionHistoryBloc
    extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  final TransactionRepository _repository;

  TransactionHistoryBloc({
    required TransactionRepository repository,
  })  : _repository = repository,
        super(TransactionHistoryState.initial()) {
    on<LoadTransactionHistory>(_onLoad);
    on<RefreshTransactionHistory>(_onRefresh);
    on<ChangeMonth>(_onChangeMonth);
    on<ChangeTypeFilter>(_onChangeTypeFilter);
  }

  Future<void> _onLoad(
    LoadTransactionHistory event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    emit(state.copyWith(status: TransactionHistoryStatus.loading));
    await _fetchTransactions(emit);
  }

  Future<void> _onRefresh(
    RefreshTransactionHistory event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    await _fetchTransactions(emit);
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    emit(state.copyWith(
      selectedMonth: event.month,
      status: TransactionHistoryStatus.loading,
    ));
    await _fetchTransactions(emit);
  }

  Future<void> _onChangeTypeFilter(
    ChangeTypeFilter event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    if (event.type == null) {
      emit(state.copyWith(clearTypeFilter: true));
    } else {
      emit(state.copyWith(typeFilter: event.type));
    }
  }

  Future<void> _fetchTransactions(
      Emitter<TransactionHistoryState> emit) async {
    try {
      final month = state.selectedMonth;
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final transactions = await _repository.getTransactionsByDateRange(
        start: start,
        end: end,
      );

      emit(state.copyWith(
        status: TransactionHistoryStatus.loaded,
        transactions: transactions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TransactionHistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
