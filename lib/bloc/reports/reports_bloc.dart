import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/invoice_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final InvoiceRepository _invoiceRepository;

  ReportsBloc({required InvoiceRepository invoiceRepository})
      : _invoiceRepository = invoiceRepository,
        super(const ReportsState()) {
    on<LoadSalesReport>(_onLoadSalesReport);
  }

  Future<void> _onLoadSalesReport(
      LoadSalesReport event, Emitter<ReportsState> emit) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(event.startDate);
      final endDate = DateFormat('yyyy-MM-dd').format(event.endDate);
      final invoices =
          await _invoiceRepository.getInvoicesByDateRange(startDate, endDate);
      emit(state.copyWith(
        status: ReportStatus.loaded,
        salesReportData: invoices,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
