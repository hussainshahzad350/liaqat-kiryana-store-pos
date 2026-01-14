import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sales Calculation Tests', () {
    test('Subtotal calculation should be correct', () {
      final prices = [100.0, 200.0, 50.0];

      final subtotal = prices.reduce((a, b) => a + b);

      expect(subtotal, 350.0);
    });

    test('Discount should be applied correctly', () {
      const subtotal = 1000.0;
      const discount = 100.0;

      const grandTotal = subtotal - discount;

      expect(grandTotal, 900.0);
    });
  });
}
