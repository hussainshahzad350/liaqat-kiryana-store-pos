import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

enum ActivityType { purchase, sale, adjustment, returnIn, returnOut }

@immutable
class StockActivityEntity {
  final String id;
  final DateTime timestamp;
  final ActivityType type;
  final String referenceNumber; // Bill #, Invoice #
  final int? referenceId;
  final String description;
  final double quantityChange;
  final Money? financialImpact;
  final String user;
  final String status; // COMPLETED, CANCELLED

  const StockActivityEntity({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.referenceNumber,
    this.referenceId,
    required this.description,
    required this.quantityChange,
    this.financialImpact,
    required this.user,
    required this.status,
  });
}