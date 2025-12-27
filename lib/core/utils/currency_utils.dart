// WARNING:
// All inputs are expected in PAISAS unless explicitly stated.
// Never pass rupees directly to these methods.

class CurrencyUtils {
  // 1. Human writes "10.50" -> Database stores 1050
  static int toPaisas(String amount) {
    if (amount.isEmpty) return 0;
    try {
      final doubleValue = double.parse(amount);
      return (doubleValue * 100).round();
    } catch (e) {
      return 0;
    }
  }

  // 2. Database gives 1050 -> Human sees "10.50" (for editing)
  static String toDecimal(int paisas) {
    return (paisas / 100.0).toStringAsFixed(2);
  }

  // 3. Database gives 1050 -> Customer sees "Rs 11" (Rounded for Bill)
  static String formatRupees(int paisas) {
    // In Pakistan, we rarely deal with 0.50 on the final bill.
    // This rounds 10.50 -> 11, and 10.49 -> 10.
    final rupees = (paisas / 100.0).round(); 
    return 'Rs $rupees';
  }
}