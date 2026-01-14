import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class Money {
  final int paisas;

  const Money(this.paisas);

  static const Money zero = Money(0);

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _noDecimalFormat = NumberFormat('#,##0', 'en_US');

  /// Factory from rupees string input (e.g. "10.50")
  factory Money.fromRupeesString(String value) {
    if (value.trim().isEmpty) return const Money(0);
    try {
       // Handle commas if present in string input e.g "1,200.50"
       String normalized = value.replaceAll(',', '').trim();
       if (normalized.isEmpty) return const Money(0);

       final double val = double.parse(normalized);
       return Money((val * 100).round());
    } catch (_) {
      return const Money(0);
    }
  }

  Money operator +(Money other) => Money(paisas + other.paisas);
  Money operator -(Money other) => Money(paisas - other.paisas);
  Money operator *(num multiplier) => Money((paisas * multiplier).round());
  
  // Division returns a double (ratio) or another Money division logic could be implemented if needed.
  // For now keeping it simple.

  bool operator <(Money other) => paisas < other.paisas;
  bool operator >(Money other) => paisas > other.paisas;
  bool operator <=(Money other) => paisas <= other.paisas;
  bool operator >=(Money other) => paisas >= other.paisas;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paisas == other.paisas;

  @override
  int get hashCode => paisas.hashCode;

  /// Formats the money value as "Rs 1,234.00"
  @override
  String toString() => formatted;

  /// Formats the money value as "Rs 1,234.00"
  String get formatted {
    final rupees = paisas / 100.0;
    return 'Rs ${_currencyFormat.format(rupees)}';
  }

  /// Formats money as "Rs 1,234" (no decimals)
  String get formattedNoDecimal {
    final rupees = paisas / 100.0;
    return 'Rs ${_noDecimalFormat.format(rupees)}';
  }

  /// Returns the value as a decimal string (e.g., "10.50")
  String toRupeesString() {
    return (paisas / 100.0).toStringAsFixed(2);
  }
}