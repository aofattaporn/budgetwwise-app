import 'package:app_template/features/accounts/data/models/account_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountModel.fromJson', () {
    test('parses balances when Supabase returns them as strings', () {
      final model = AccountModel.fromJson({
        'id': 'a1',
        'name': 'Wallet',
        'type': 'cash',
        'opening_balance': '100.00',
        'balance': '73.25',
        'currency': 'USD',
        'created_at': '2026-05-01T00:00:00.000Z',
        'updated_at': '2026-05-02T00:00:00.000Z',
      });

      expect(model.openingBalance, 100.0);
      expect(model.balance, 73.25);
      expect(model.currency, 'USD');
    });

    test('parses balances when returned as numbers', () {
      final model = AccountModel.fromJson({
        'id': 'a1',
        'name': 'Wallet',
        'type': 'cash',
        'opening_balance': 100,
        'balance': 73.25,
        'currency': 'USD',
        'created_at': '2026-05-01T00:00:00.000Z',
        'updated_at': '2026-05-02T00:00:00.000Z',
      });

      expect(model.openingBalance, 100.0);
      expect(model.balance, 73.25);
    });
  });

  test('fromEntity -> toEntity round-trips the data', () {
    final original = AccountModel.fromJson({
      'id': 'a1',
      'name': 'Wallet',
      'type': 'cash',
      'opening_balance': 100,
      'balance': 73.25,
      'currency': 'USD',
      'created_at': '2026-05-01T00:00:00.000Z',
      'updated_at': '2026-05-02T00:00:00.000Z',
    });

    final roundTripped = AccountModel.fromEntity(original.toEntity());

    expect(roundTripped, original);
  });
}
