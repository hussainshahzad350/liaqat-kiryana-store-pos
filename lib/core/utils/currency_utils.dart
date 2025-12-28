import '../../domain/entities/money.dart';

class CurrencyUtils {
    /// Formats paisas to 'Rs 180' (no decimal) for UI
    static String formatNoDecimal(Money money) {
      final rupees = money.paisas ~/ 100;
      return 'Rs $rupees';
    }
  /// Formats paisas to "Rs 10.50"
  /// Note: Does NOT round. 1050 -> 10.50
  static String format(Money money) {
    final paisas = money.paisas;
    final rupees = paisas ~/ 100;
    final remainder = paisas % 100;
    return 'Rs $rupees.${remainder.toString().padLeft(2, '0')}';
  }

  static String formatRupees(int paisas) => format(Money(paisas));

  static Money parse(String input) => Money.fromRupeesString(input);

  static int toPaisas(String input) => parse(input).paisas;

  static String toDecimal(int paisas) {
    final rupees = paisas ~/ 100;
    final remainder = paisas % 100;
    return '$rupees.${remainder.toString().padLeft(2, '0')}';
  }

  static String toDecimalMoney(Money money) => toDecimal(money.paisas);
}