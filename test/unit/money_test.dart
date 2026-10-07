import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/domain/entities/money.dart';

void main() {
  group('Money Entity Tests', () {
    test(
        'input and decimal strings round-trip paisas including credit balances',
        () {
      for (final paisas in [
        0,
        1,
        5,
        10,
        99,
        100,
        101,
        123450,
        -1,
        -3333,
        99999999
      ]) {
        final money = Money(paisas);
        expect(Money.fromRupeesString(money.toInputString()), money);
        expect(Money.fromRupeesString(money.toRupeesString()), money);
      }
    });

    test('displayed totals retain cents, grouping and the credit sign', () {
      expect(const Money(0).formatted, 'Rs 0.00');
      expect(const Money(1).formattedSmart, 'Rs 0.01');
      expect(const Money(123456).formattedSmart, 'Rs 1,234.56');
      expect(const Money(-123456).formatted, '-Rs 1,234.56');
      expect(const Money(123400).formattedSmart, 'Rs 1,234');
      expect(
          (const Money(3333) + const Money(3333) + const Money(3335)).formatted,
          'Rs 100.01');
    });

    test('should initialize with correct paisas', () {
      const money = Money(1050);
      expect(money.paisas, 1050);
    });

    test('should create from rupees string correctly', () {
      final money = Money.fromRupeesString('10.50');
      expect(money.paisas, 1050);

      final money2 = Money.fromRupeesString('10');
      expect(money2.paisas, 1000);

      final money3 = Money.fromRupeesString('0.05');
      expect(money3.paisas, 5);

      final moneyEmpty = Money.fromRupeesString('');
      expect(moneyEmpty.paisas, 0);
    });

    test('should support addition', () {
      const m1 = Money(100); // 1.00
      const m2 = Money(250); // 2.50
      final sum = m1 + m2;
      expect(sum.paisas, 350);
    });

    test('should support subtraction', () {
      const m1 = Money(500);
      const m2 = Money(200);
      final diff = m1 - m2;
      expect(diff.paisas, 300);
    });

    test('should support comparisons', () {
      const m1 = Money(100);
      const m2 = Money(200);

      expect(m1 < m2, true);
      expect(m2 > m1, true);
      expect(m1 <= m1, true);
      expect(m1 >= m1, true);
      expect(m1 == const Money(100), true);
    });

    test('toString should format as currency', () {
      const money = Money(123450); // 1234.50
      // Note: The actual formatting depends on locale, which might be tricky in unit tests
      // without setting up locale. However, Money uses 'en_US' explicitly.
      // 1,234.50
      expect(money.toString(), 'Rs 1,234.50');
    });

    test('toRupeesString should return decimal string', () {
      const money = Money(1050);
      expect(money.toRupeesString(), '10.50');

      const money2 = Money(5);
      expect(money2.toRupeesString(), '0.05');
    });
  });
}
