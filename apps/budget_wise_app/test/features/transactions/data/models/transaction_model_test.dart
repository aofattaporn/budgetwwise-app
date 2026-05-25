import 'package:app_template/features/transactions/data/models/transaction_model.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel.fromJson', () {
    test('parses amount when Supabase returns it as a string', () {
      final model = TransactionModel.fromJson({
        'id': 't1',
        'account_id': 'a1',
        'destination_account_id': null,
        'plan_item_id': null,
        'type': 'expense',
        'amount': '12.50',
        'description': null,
        'occurred_at': '2026-05-01T10:00:00.000Z',
        'created_at': null,
        'updated_at': null,
      });

      expect(model.amount, 12.5);
      expect(model.type, 'expense');
      expect(model.occurredAt, DateTime.parse('2026-05-01T10:00:00.000Z'));
    });

    test('parses amount when returned as a number', () {
      final model = TransactionModel.fromJson({
        'id': 't1',
        'account_id': 'a1',
        'type': 'income',
        'amount': 99.99,
        'occurred_at': '2026-05-01T10:00:00.000Z',
      });

      expect(model.amount, 99.99);
    });
  });

  group('TransactionModel <-> entity type mapping', () {
    test('toEntity maps known type strings to the enum', () {
      TransactionType typeFor(String s) => TransactionModel.fromJson({
            'id': 't',
            'account_id': 'a',
            'type': s,
            'amount': 1,
            'occurred_at': '2026-05-01T10:00:00.000Z',
          }).toEntity().type;

      expect(typeFor('expense'), TransactionType.expense);
      expect(typeFor('income'), TransactionType.income);
      expect(typeFor('transfer'), TransactionType.transfer);
    });

    test('toEntity falls back to expense for an unknown type', () {
      final entity = TransactionModel.fromJson({
        'id': 't',
        'account_id': 'a',
        'type': 'mystery',
        'amount': 1,
        'occurred_at': '2026-05-01T10:00:00.000Z',
      }).toEntity();

      expect(entity.type, TransactionType.expense);
    });

    test('fromEntity serialises the enum to its name', () {
      final model = TransactionModel.fromEntity(Transaction(
        id: 't',
        accountId: 'a',
        type: TransactionType.transfer,
        amount: 5,
        occurredAt: DateTime.parse('2026-05-01T10:00:00.000Z'),
      ));

      expect(model.type, 'transfer');
    });
  });

  test('toJson -> fromJson round-trips a transaction', () {
    final original = TransactionModel.fromJson({
      'id': 't1',
      'account_id': 'a1',
      'destination_account_id': 'a2',
      'plan_item_id': 'i1',
      'type': 'transfer',
      'amount': 42.0,
      'description': 'move savings',
      'occurred_at': '2026-05-01T10:00:00.000Z',
    });

    final restored = TransactionModel.fromJson(original.toJson());

    expect(restored, original);
  });
}
