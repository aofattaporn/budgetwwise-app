import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel extends Equatable {
  final String id;
  final String accountId;
  final String? destinationAccountId;
  final String? planItemId;
  final String type;
  final double amount;
  final String? description;
  final DateTime occurredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.accountId,
    this.destinationAccountId,
    this.planItemId,
    required this.type,
    required this.amount,
    this.description,
    required this.occurredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        destinationAccountId: json['destination_account_id'] as String?,
        planItemId: json['plan_item_id'] as String?,
        type: json['type'] as String,
        amount: double.parse(json['amount'].toString()),
        description: json['description'] as String?,
        occurredAt: DateTime.parse(json['occurred_at']),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'destination_account_id': destinationAccountId,
        'plan_item_id': planItemId,
        'type': type,
        'amount': amount,
        'description': description,
        'occurred_at': occurredAt.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  Transaction toEntity() => Transaction(
        id: id,
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        planItemId: planItemId,
        type: _parseType(type),
        amount: amount,
        description: description,
        occurredAt: occurredAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TransactionModel.fromEntity(Transaction entity) => TransactionModel(
        id: entity.id,
        accountId: entity.accountId,
        destinationAccountId: entity.destinationAccountId,
        planItemId: entity.planItemId,
        type: entity.type.name,
        amount: entity.amount,
        description: entity.description,
        occurredAt: entity.occurredAt,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  static TransactionType _parseType(String type) {
    switch (type) {
      case 'expense':
        return TransactionType.expense;
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        destinationAccountId,
        planItemId,
        type,
        amount,
        description,
        occurredAt,
        createdAt,
        updatedAt,
      ];
}
