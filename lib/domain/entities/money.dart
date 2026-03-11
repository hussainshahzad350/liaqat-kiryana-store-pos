import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class Money {
  const Money(this.paisas);

  factory Money.fromNullablePaisas(int? value) {
    return value == null ? Money.zero : Money(value);
  }

  factory Money.fromNullableRupees(num? value) {
    if (value == null) return Money.zero;
    return Money((value * 100).round());
  }

  factory Money.fromPaisas(int value) {
    return Money(value);
  }

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

  /// Parses a string into a Money object, returning null if invalid.
  static Money? tryParse(String value) {
    if (value.trim().isEmpty) return Money.zero;
    try {
      String normalized = value.replaceAll(',', '').trim();
      if (normalized.isEmpty) return Money.zero;
      final validPattern = RegExp(r'^\d+(\.\d{1,2})?$');
      if (!validPattern.hasMatch(normalized)) return null;
      final double val = double.parse(normalized);
      return Money((val * 100).round());
    } catch (_) {
      return null;
    }
  }

  static const Money zero = Money(0);

  final int paisas;

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _noDecimalFormat = NumberFormat('#,##0', 'en_US');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          paisas == other.paisas;

  @override
  int get hashCode => paisas.hashCode;

  /// Shows smart format: "Rs 180" for whole, "Rs 1.50" for fractional
  @override
  String toString() => formattedSmart;

  Money operator +(Money other) => Money(paisas + other.paisas);

  Money operator -(Money other) => Money(paisas - other.paisas);

  Money operator *(num multiplier) => Money((paisas * multiplier).round());

  // Division returns a double (ratio) or another Money division logic could be implemented if needed.
  // For now keeping it simple.

  bool operator <(Money other) => paisas < other.paisas;

  bool operator >(Money other) => paisas > other.paisas;

  bool operator <=(Money other) => paisas <= other.paisas;

  bool operator >=(Money other) => paisas >= other.paisas;

  bool get isZero => paisas == 0;

  bool get isDebit => paisas > 0;

  bool get isCredit => paisas < 0;

  bool get isNegative => paisas < 0;

  bool get isPositive => paisas > 0;

  Money abs() => Money(paisas.abs());

  double get rupees => paisas / 100.0;

  /// Returns a smart string for numeric input fields.
  /// Whole amounts use no decimals (e.g. "180"), fractional use 1–2 decimals:
  /// 50 paisas -> "0.5", 150 paisas -> "1.5", 175 paisas -> "1.75".
  String toInputString() {
    final absValue = paisas.abs();
    // Whole rupees — no decimal part
    if (absValue % 100 == 0) {
      return (paisas ~/ 100).toString();
    }

    final value = paisas / 100.0;

    // Exactly one decimal place (e.g. 0.5, 1.5)
    if (absValue % 10 == 0) {
      final oneDecimal = value.toStringAsFixed(1);
      return paisas < 0 ? oneDecimal : oneDecimal;
    }

    // Up to two decimals for the rest (e.g. 1.25)
    final twoDecimals = value.toStringAsFixed(2);
    return paisas < 0 ? twoDecimals : twoDecimals;
  }

  /// Formats money intelligently: no decimals for whole numbers, shows decimals for fractional.
  /// e.g. Rs 180, Rs 1, Rs 1.50, Rs 0.75
  String get formattedSmart {
    final absValue = paisas.abs();
    final sign = paisas < 0 ? '-' : '';
    if (absValue % 100 == 0) {
      // Whole rupees — no decimal
      return '${sign}Rs ${_noDecimalFormat.format(absValue ~/ 100)}';
    } else {
      // Has fractional paisa — show 2 decimal places
      return '${sign}Rs ${_currencyFormat.format(absValue / 100.0)}';
    }
  }

  /// Formats the money value as "Rs 1,234.00"
  String get formatted {
    final absValue = paisas.abs() / 100.0;
    final sign = paisas < 0 ? '-' : '';
    return '${sign}Rs ${_currencyFormat.format(absValue)}';
  }

  /// Formats money as "Rs 1,234" (no decimals)
  String get formattedNoDecimal {
    final rupees = paisas / 100.0;
    return 'Rs ${_noDecimalFormat.format(rupees)}';
  }

  /// Returns formatted value without currency symbol (e.g., "1,234.00")
  String get valueOnly {
    return format(withSymbol: false);
  }

  /// Returns the value as a decimal string (e.g., "10.50")
  String toRupeesString() {
    return (paisas / 100.0).toStringAsFixed(2);
  }

  String format({bool withSymbol = true, bool noDecimals = false}) {
    final rupees = paisas / 100.0;
    final formatted = noDecimals
        ? _noDecimalFormat.format(rupees)
        : _currencyFormat.format(rupees);

    return withSymbol ? 'Rs $formatted' : formatted;
  }

  Money operator /(num divisor) {
    assert(divisor != 0);
    return Money((paisas / divisor).round());
  }
}
