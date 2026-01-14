import 'package:equatable/equatable.dart';
import '../../models/invoice_model.dart';

enum ReportsStatus { initial, loading, success, error }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final List<Invoice> salesReport;
  final String? errorMessage;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.salesReport = const [],
    this.errorMessage,
  });

  ReportsState copyWith({
    ReportsStatus? status,
    List<Invoice>? salesReport,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      salesReport: salesReport ?? this.salesReport,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, salesReport, errorMessage];
}
