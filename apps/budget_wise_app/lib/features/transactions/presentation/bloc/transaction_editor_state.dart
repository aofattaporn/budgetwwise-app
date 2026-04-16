part of 'transaction_editor_bloc.dart';

enum TransactionEditorStatus { initial, loading, ready, saving, success, error }

class TransactionEditorState extends Equatable {
  final TransactionEditorStatus status;
  final bool isEditing;
  final Transaction? existingTransaction;
  final TransactionType type;
  final String amount;
  final String selectedAccountId;
  final String selectedDestinationAccountId;
  final String selectedPlanItemId;
  final DateTime occurredAt;
  final String description;
  final List<Account> accounts;
  final List<PlanItem> planItems;
  final String? activePlanId;
  final String? errorMessage;

  TransactionEditorState({
    this.status = TransactionEditorStatus.initial,
    this.isEditing = false,
    this.existingTransaction,
    this.type = TransactionType.expense,
    this.amount = '',
    this.selectedAccountId = '',
    this.selectedDestinationAccountId = '',
    this.selectedPlanItemId = '',
    DateTime? occurredAt,
    this.description = '',
    this.accounts = const [],
    this.planItems = const [],
    this.activePlanId,
    this.errorMessage,
  }) : occurredAt = occurredAt ?? DateTime.now();

  Account? get selectedAccount {
    if (selectedAccountId.isEmpty) return null;
    try {
      return accounts.firstWhere((a) => a.id == selectedAccountId);
    } catch (_) {
      return null;
    }
  }

  Account? get selectedDestinationAccount {
    if (selectedDestinationAccountId.isEmpty) return null;
    try {
      return accounts.firstWhere((a) => a.id == selectedDestinationAccountId);
    } catch (_) {
      return null;
    }
  }

  PlanItem? get selectedPlanItem {
    if (selectedPlanItemId.isEmpty) return null;
    try {
      return planItems.firstWhere((p) => p.id == selectedPlanItemId);
    } catch (_) {
      return null;
    }
  }

  TransactionEditorState copyWith({
    TransactionEditorStatus? status,
    bool? isEditing,
    Transaction? existingTransaction,
    TransactionType? type,
    String? amount,
    String? selectedAccountId,
    String? selectedDestinationAccountId,
    String? selectedPlanItemId,
    DateTime? occurredAt,
    String? description,
    List<Account>? accounts,
    List<PlanItem>? planItems,
    String? activePlanId,
    String? errorMessage,
  }) {
    return TransactionEditorState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      existingTransaction:
          existingTransaction ?? this.existingTransaction,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      selectedDestinationAccountId: selectedDestinationAccountId ?? this.selectedDestinationAccountId,
      selectedPlanItemId: selectedPlanItemId ?? this.selectedPlanItemId,
      occurredAt: occurredAt ?? this.occurredAt,
      description: description ?? this.description,
      accounts: accounts ?? this.accounts,
      planItems: planItems ?? this.planItems,
      activePlanId: activePlanId ?? this.activePlanId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEditing,
        existingTransaction,
        type,
        amount,
        selectedAccountId,
        selectedDestinationAccountId,
        selectedPlanItemId,
        occurredAt,
        description,
        accounts,
        planItems,
        activePlanId,
        errorMessage,
      ];
}
