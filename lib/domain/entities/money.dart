import 'package:flutter/foundation.dart';

@immutable
class Money {
  final int paisas;

  const Money(this.paisas);

  /// Factory from rupees string input (e.g. "10.50")
  factory Money.fromRupeesString(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return const Money(0);

    final parts = normalized.split('.');
    final rupees = int.parse(parts[0]);
    final paisaPart = parts.length > 1
        ? parts[1].padRight(2, '0').substring(0, 2)
        : '00';

    final paisas = rupees * 100 + int.parse(paisaPart);
    return Money(paisas);
  }

  Money operator +(Money other) => Money(paisas + other.paisas);
  Money operator -(Money other) => Money(paisas - other.paisas);

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
}