part of 'transaction_editor_bloc.dart';

abstract class TransactionEditorEvent extends Equatable {
  const TransactionEditorEvent();

  @override
  List<Object?> get props => [];
}

class TransactionEditorLoaded extends TransactionEditorEvent {
  final Transaction? transaction;

  const TransactionEditorLoaded({this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionTypeChanged extends TransactionEditorEvent {
  final TransactionType type;

  const TransactionTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class TransactionAmountChanged extends TransactionEditorEvent {
  final String amount;

  const TransactionAmountChanged(this.amount);

  @override
  List<Object?> get props => [amount];
}

class TransactionAccountChanged extends TransactionEditorEvent {
  final String accountId;

  const TransactionAccountChanged(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class TransactionDestinationAccountChanged extends TransactionEditorEvent {
  final String accountId;

  const TransactionDestinationAccountChanged(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class TransactionPlanItemChanged extends TransactionEditorEvent {
  final String planItemId;

  const TransactionPlanItemChanged(this.planItemId);

  @override
  List<Object?> get props => [planItemId];
}

class TransactionDateChanged extends TransactionEditorEvent {
  final DateTime date;

  const TransactionDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class TransactionTimeChanged extends TransactionEditorEvent {
  final TimeOfDay time;

  const TransactionTimeChanged(this.time);

  @override
  List<Object?> get props => [time];
}

class TransactionDescriptionChanged extends TransactionEditorEvent {
  final String description;

  const TransactionDescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

class TransactionEditorSubmitted extends TransactionEditorEvent {
  const TransactionEditorSubmitted();
}
