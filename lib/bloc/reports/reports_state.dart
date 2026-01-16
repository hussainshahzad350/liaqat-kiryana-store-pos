import 'package:equatable/equatable.dart';
import '../../models/invoice_model.dart';

enum ReportStatus { initial, loading, loaded, error }

class ReportsState extends Equatable {
  final ReportStatus status;
  final List<Invoice> salesReportData;
  final String? errorMessage;

  const ReportsState({
    this.status = ReportStatus.initial,
    this.salesReportData = const [],
    this.errorMessage,
  });

  ReportsState copyWith({
    ReportStatus? status,
    List<Invoice>? salesReportData,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      salesReportData: salesReportData ?? this.salesReportData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, salesReportData, errorMessage];
}
