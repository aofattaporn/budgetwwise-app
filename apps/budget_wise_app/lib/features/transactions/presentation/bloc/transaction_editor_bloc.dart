import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'transaction_editor_event.dart';
part 'transaction_editor_state.dart';

class TransactionEditorBloc
    extends Bloc<TransactionEditorEvent, TransactionEditorState> {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final PlanRepository _planRepository;

  TransactionEditorBloc({
    required TransactionRepository transactionRepository,
    required AccountRepository accountRepository,
    required PlanRepository planRepository,
  })  : _transactionRepository = transactionRepository,
        _accountRepository = accountRepository,
        _planRepository = planRepository,
        super(TransactionEditorState()) {
    on<TransactionEditorLoaded>(_onLoaded);
    on<TransactionTypeChanged>(_onTypeChanged);
    on<TransactionAmountChanged>(_onAmountChanged);
    on<TransactionAccountChanged>(_onAccountChanged);
    on<TransactionDestinationAccountChanged>(_onDestinationAccountChanged);
    on<TransactionPlanItemChanged>(_onPlanItemChanged);
    on<TransactionDateChanged>(_onDateChanged);
    on<TransactionTimeChanged>(_onTimeChanged);
    on<TransactionDescriptionChanged>(_onDescriptionChanged);
    on<TransactionEditorSubmitted>(_onSubmitted);
  }

  Future<void> _onLoaded(
    TransactionEditorLoaded event,
    Emitter<TransactionEditorState> emit,
  ) async {
    emit(state.copyWith(status: TransactionEditorStatus.loading));

    try {
      final accounts = await _accountRepository.getAccounts();
      final activePlan = await _planRepository.getActivePlan();
      List<PlanItem> planItems = [];
      if (activePlan != null) {
        planItems = await _planRepository.getPlanItems(activePlan.id);
      }

      if (event.transaction != null) {
        final txn = event.transaction!;
        emit(state.copyWith(
          status: TransactionEditorStatus.ready,
          isEditing: true,
          existingTransaction: txn,
          type: txn.type,
          amount: txn.amount.toString(),
          selectedAccountId: txn.accountId,
          selectedDestinationAccountId: txn.destinationAccountId ?? '',
          selectedPlanItemId: txn.planItemId,
          occurredAt: txn.occurredAt,
          description: txn.description ?? '',
          accounts: accounts,
          planItems: planItems,
          activePlanId: activePlan?.id,
        ));
      } else {
        emit(state.copyWith(
          status: TransactionEditorStatus.ready,
          accounts: accounts,
          planItems: planItems,
          activePlanId: activePlan?.id,
          occurredAt: DateTime.now(),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Failed to load data: $e',
      ));
    }
  }

  void _onTypeChanged(
    TransactionTypeChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(
      type: event.type,
      // Clear plan item if switching to transfer
      selectedPlanItemId: event.type == TransactionType.transfer ? '' : null,
      // Clear destination account if switching away from transfer
      selectedDestinationAccountId: event.type != TransactionType.transfer ? '' : null,
    ));
  }

  void _onAmountChanged(
    TransactionAmountChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(amount: event.amount));
  }

  void _onAccountChanged(
    TransactionAccountChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(selectedAccountId: event.accountId));
  }

  void _onDestinationAccountChanged(
    TransactionDestinationAccountChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(selectedDestinationAccountId: event.accountId));
  }

  void _onPlanItemChanged(
    TransactionPlanItemChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(selectedPlanItemId: event.planItemId));
  }

  void _onDateChanged(
    TransactionDateChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    final current = state.occurredAt;
    final updated = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      current.hour,
      current.minute,
    );
    emit(state.copyWith(occurredAt: updated));
  }

  void _onTimeChanged(
    TransactionTimeChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    final current = state.occurredAt;
    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      event.time.hour,
      event.time.minute,
    );
    emit(state.copyWith(occurredAt: updated));
  }

  void _onDescriptionChanged(
    TransactionDescriptionChanged event,
    Emitter<TransactionEditorState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onSubmitted(
    TransactionEditorSubmitted event,
    Emitter<TransactionEditorState> emit,
  ) async {
    // Validation
    final amount = double.tryParse(state.amount);
    if (amount == null || amount <= 0) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Amount must be greater than 0',
      ));
      emit(state.copyWith(status: TransactionEditorStatus.ready));
      return;
    }

    if (state.selectedAccountId.isEmpty) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Please select an account',
      ));
      emit(state.copyWith(status: TransactionEditorStatus.ready));
      return;
    }

    if (state.type == TransactionType.transfer &&
        state.selectedDestinationAccountId.isEmpty) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Please select a destination account',
      ));
      emit(state.copyWith(status: TransactionEditorStatus.ready));
      return;
    }

    if (state.type == TransactionType.transfer &&
        state.selectedAccountId == state.selectedDestinationAccountId) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Source and destination accounts must be different',
      ));
      emit(state.copyWith(status: TransactionEditorStatus.ready));
      return;
    }

    emit(state.copyWith(status: TransactionEditorStatus.saving));

    try {
      final transaction = Transaction(
        id: state.isEditing ? state.existingTransaction!.id : '',
        accountId: state.selectedAccountId,
        destinationAccountId: state.type == TransactionType.transfer
            ? state.selectedDestinationAccountId
            : null,
        planItemId: state.selectedPlanItemId.isNotEmpty
            ? state.selectedPlanItemId
            : null,
        type: state.type,
        amount: amount,
        description: state.description.isNotEmpty ? state.description : null,
        occurredAt: state.occurredAt,
      );

      if (state.isEditing) {
        // BR-TXN-EDIT-09: Reverse original balance impact first
        final original = state.existingTransaction!;
        await _reverseBalanceImpact(original);
        await _transactionRepository.updateTransaction(transaction);
      } else {
        await _transactionRepository.createTransaction(transaction);
      }

      // Apply balance impact based on type
      await _applyBalanceImpact(transaction);

      // Invalidate plan cache so actuals are re-computed from transactions
      _planRepository.invalidateCache();

      emit(state.copyWith(status: TransactionEditorStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: TransactionEditorStatus.error,
        errorMessage: 'Failed to save transaction: $e',
      ));
      emit(state.copyWith(status: TransactionEditorStatus.ready));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Business Rules: Balance Impact
  // ─────────────────────────────────────────────────────────────────────────

  /// Apply balance changes after creating/editing a transaction
  /// Plan item actuals are computed from transactions table (no manual update needed)
  Future<void> _applyBalanceImpact(Transaction txn) async {
    final accounts = await _accountRepository.getAccounts();
    final account = accounts.firstWhere((a) => a.id == txn.accountId);

    switch (txn.type) {
      case TransactionType.expense:
        // BR-TXN-EDIT-02: Deduct from account
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance - txn.amount),
        );
        break;
      case TransactionType.income:
        // BR-TXN-EDIT-03: Add to account
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance + txn.amount),
        );
        break;
      case TransactionType.transfer:
        // BR-TXN-EDIT-04: Deduct from source, add to destination
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance - txn.amount),
        );
        if (txn.destinationAccountId != null) {
          final destAccount = accounts.firstWhere((a) => a.id == txn.destinationAccountId);
          await _accountRepository.updateAccount(
            destAccount.copyWith(balance: destAccount.balance + txn.amount),
          );
        }
        break;
    }
  }

  /// Reverse balance changes before editing/deleting a transaction
  Future<void> _reverseBalanceImpact(Transaction txn) async {
    final accounts = await _accountRepository.getAccounts();
    final account = accounts.firstWhere((a) => a.id == txn.accountId);

    switch (txn.type) {
      case TransactionType.expense:
        // Reverse: add back to account
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance + txn.amount),
        );
        break;
      case TransactionType.income:
        // Reverse: deduct from account
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance - txn.amount),
        );
        break;
      case TransactionType.transfer:
        // Reverse: add back to source, deduct from destination
        await _accountRepository.updateAccount(
          account.copyWith(balance: account.balance + txn.amount),
        );
        if (txn.destinationAccountId != null) {
          final destAccount = accounts.firstWhere((a) => a.id == txn.destinationAccountId);
          await _accountRepository.updateAccount(
            destAccount.copyWith(balance: destAccount.balance - txn.amount),
          );
        }
        break;
    }
  }
}
