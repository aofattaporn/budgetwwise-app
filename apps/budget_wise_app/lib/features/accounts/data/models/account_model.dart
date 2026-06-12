import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

class AccountModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final double openingBalance;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        openingBalance: double.parse(json['opening_balance'].toString()),
        balance: double.parse(json['balance'].toString()),
        currency: json['currency'] as String,
        createdAt: DateTime.parse(json['created_at']).toLocal(),
        updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'opening_balance': openingBalance,
        'balance': balance,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Account toEntity() => Account(
        id: id,
        name: name,
        type: type,
        openingBalance: openingBalance,
        balance: balance,
        currency: currency,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory AccountModel.fromEntity(Account entity) => AccountModel(
        id: entity.id,
        name: entity.name,
        type: entity.type,
        openingBalance: entity.openingBalance,
        balance: entity.balance,
        currency: entity.currency,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, name, type, openingBalance, balance, currency, createdAt, updatedAt];
}
