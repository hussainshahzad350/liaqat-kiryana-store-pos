// test/unit/cash_ledger_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/models/cash_ledger_model.dart';

void main() {
  group('CashLedger.paymentMode', () {
    test('defaults to CASH when not provided in constructor', () {
      final entry = CashLedger(
        transactionDate: DateTime(2024, 1, 15),
        description: 'Test',
        type: 'IN',
        amount: 1000,
      );
      expect(entry.paymentMode, 'CASH');
    });

    test('stores custom payment mode when provided in constructor', () {
      final entry = CashLedger(
        transactionDate: DateTime(2024, 1, 15),
        description: 'Bank transfer',
        type: 'IN',
        amount: 5000,
        paymentMode: 'BANK',
      );
      expect(entry.paymentMode, 'BANK');
    });

    test('accepts all expected payment mode values', () {
      for (final mode in ['CASH', 'CARD', 'BANK', 'EASYPAISA', 'JAZZCASH']) {
        final entry = CashLedger(
          transactionDate: DateTime(2024, 1, 15),
          description: 'Payment via $mode',
          type: 'IN',
          amount: 100,
          paymentMode: mode,
        );
        expect(entry.paymentMode, mode);
      }
    });
  });

  group('CashLedger.fromMap', () {
    test('parses paymentMode from map', () {
      final map = {
        'id': 1,
        'transaction_date': '2024-01-15',
        'transaction_time': '10:30 AM',
        'description': 'Sale',
        'type': 'IN',
        'amount': 5000,
        'balance_after': 15000,
        'remarks': null,
        'payment_mode': 'BANK',
      };
      final entry = CashLedger.fromMap(map);
      expect(entry.paymentMode, 'BANK');
    });

    test('defaults paymentMode to CASH when missing from map', () {
      final map = {
        'id': 2,
        'transaction_date': '2024-01-15',
        'transaction_time': '11:00 AM',
        'description': 'Purchase',
        'type': 'OUT',
        'amount': 2000,
        'balance_after': 13000,
        'remarks': null,
        // payment_mode key absent
      };
      final entry = CashLedger.fromMap(map);
      expect(entry.paymentMode, 'CASH');
    });

    test('defaults paymentMode to CASH when map value is null', () {
      final map = {
        'id': 3,
        'transaction_date': '2024-01-15',
        'transaction_time': null,
        'description': 'Old entry',
        'type': 'IN',
        'amount': 1000,
        'balance_after': null,
        'remarks': null,
        'payment_mode': null,
      };
      final entry = CashLedger.fromMap(map);
      expect(entry.paymentMode, 'CASH');
    });

    test('parses EASYPAISA payment mode', () {
      final map = {
        'transaction_date': '2024-02-10',
        'description': 'Digital payment',
        'type': 'IN',
        'amount': 3000,
        'payment_mode': 'EASYPAISA',
      };
      final entry = CashLedger.fromMap(map);
      expect(entry.paymentMode, 'EASYPAISA');
    });

    test('correctly parses all other fields alongside paymentMode', () {
      final map = {
        'id': 42,
        'transaction_date': '2024-03-20',
        'transaction_time': '02:15 PM',
        'description': 'Full entry test',
        'type': 'OUT',
        'amount': 7500,
        'balance_after': 22500,
        'remarks': 'Test remark',
        'payment_mode': 'CARD',
      };
      final entry = CashLedger.fromMap(map);
      expect(entry.id, 42);
      expect(entry.description, 'Full entry test');
      expect(entry.type, 'OUT');
      expect(entry.amount, 7500);
      expect(entry.balanceAfter, 22500);
      expect(entry.remarks, 'Test remark');
      expect(entry.paymentMode, 'CARD');
    });
  });

  group('CashLedger.toMap', () {
    test('includes payment_mode in serialized map', () {
      final entry = CashLedger(
        id: 10,
        transactionDate: DateTime(2024, 5, 1),
        transactionTime: '09:00 AM',
        description: 'Cash deposit',
        type: 'IN',
        amount: 10000,
        balanceAfter: 50000,
        remarks: 'Opening balance',
        paymentMode: 'CASH',
      );
      final map = entry.toMap();
      expect(map['payment_mode'], 'CASH');
    });

    test('serializes non-CASH payment mode correctly', () {
      final entry = CashLedger(
        transactionDate: DateTime(2024, 5, 1),
        description: 'Bank transfer',
        type: 'IN',
        amount: 20000,
        paymentMode: 'BANK',
      );
      final map = entry.toMap();
      expect(map['payment_mode'], 'BANK');
    });

    test('round-trips paymentMode through fromMap and toMap', () {
      final original = CashLedger(
        id: 1,
        transactionDate: DateTime(2024, 6, 15),
        transactionTime: '03:00 PM',
        description: 'Round-trip test',
        type: 'OUT',
        amount: 500,
        balanceAfter: 9500,
        paymentMode: 'JAZZCASH',
      );
      final map = original.toMap();
      final restored = CashLedger.fromMap(map);
      expect(restored.paymentMode, original.paymentMode);
    });
  });

  group('CashLedger.copyWith', () {
    test('copies paymentMode when not overridden', () {
      final original = CashLedger(
        transactionDate: DateTime(2024, 1, 1),
        description: 'Original',
        type: 'IN',
        amount: 1000,
        paymentMode: 'BANK',
      );
      final copy = original.copyWith(description: 'Updated');
      expect(copy.paymentMode, 'BANK');
    });

    test('updates paymentMode when specified in copyWith', () {
      final original = CashLedger(
        transactionDate: DateTime(2024, 1, 1),
        description: 'Original',
        type: 'IN',
        amount: 1000,
        paymentMode: 'CASH',
      );
      final updated = original.copyWith(paymentMode: 'CARD');
      expect(updated.paymentMode, 'CARD');
      // Original unchanged
      expect(original.paymentMode, 'CASH');
    });

    test('preserves all other fields when only paymentMode is updated', () {
      final original = CashLedger(
        id: 5,
        transactionDate: DateTime(2024, 7, 4),
        transactionTime: '12:00 PM',
        description: 'July payment',
        type: 'IN',
        amount: 3000,
        balanceAfter: 8000,
        remarks: 'July note',
        paymentMode: 'CASH',
      );
      final updated = original.copyWith(paymentMode: 'EASYPAISA');
      expect(updated.id, 5);
      expect(updated.description, 'July payment');
      expect(updated.type, 'IN');
      expect(updated.amount, 3000);
      expect(updated.balanceAfter, 8000);
      expect(updated.remarks, 'July note');
      expect(updated.paymentMode, 'EASYPAISA');
    });
  });

  group('CashLedger.isInflow / isOutflow', () {
    test('isInflow is true for type IN', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'In',
        type: 'IN',
        amount: 100,
      );
      expect(entry.isInflow, true);
      expect(entry.isOutflow, false);
    });

    test('isInflow is true for type OPENING', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'Opening',
        type: 'OPENING',
        amount: 100,
      );
      expect(entry.isInflow, true);
      expect(entry.isOutflow, false);
    });

    test('isOutflow is true for type OUT', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'Out',
        type: 'OUT',
        amount: 100,
      );
      expect(entry.isOutflow, true);
      expect(entry.isInflow, false);
    });

    test('isOutflow is true for type CLOSING', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'Closing',
        type: 'CLOSING',
        amount: 100,
      );
      expect(entry.isOutflow, true);
      expect(entry.isInflow, false);
    });

    test('isInflow and isOutflow are both false for unknown type', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'Unknown',
        type: 'OTHER',
        amount: 100,
      );
      expect(entry.isInflow, false);
      expect(entry.isOutflow, false);
    });

    // Regression: digital payment entries should still report isInflow correctly
    test('BANK payment mode does not affect isInflow calculation', () {
      final entry = CashLedger(
        transactionDate: DateTime.now(),
        description: 'Bank sale',
        type: 'IN',
        amount: 5000,
        paymentMode: 'BANK',
      );
      expect(entry.isInflow, true);
    });
  });

  group('CashLedger equality and hashCode', () {
    test('two entries with same id, date, amount are equal', () {
      final date = DateTime(2024, 1, 10);
      final a = CashLedger(
        id: 1, transactionDate: date, description: 'A', type: 'IN', amount: 500, paymentMode: 'CASH');
      final b = CashLedger(
        id: 1, transactionDate: date, description: 'B', type: 'OUT', amount: 500, paymentMode: 'BANK');
      // Equality is based on id, transactionDate, and amount only
      expect(a, equals(b));
    });

    test('entries differing in paymentMode but same id/date/amount have same hash', () {
      final date = DateTime(2024, 1, 10);
      final a = CashLedger(id: 1, transactionDate: date, description: 'X', type: 'IN', amount: 100, paymentMode: 'CASH');
      final b = CashLedger(id: 1, transactionDate: date, description: 'X', type: 'IN', amount: 100, paymentMode: 'BANK');
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}