import 'package:flutter_bloc/flutter_bloc.dart';
import 'reports_event.dart';
import 'reports_state.dart';
import '../../core/repositories/invoice_repository.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final InvoiceRepository _invoiceRepository;

  ReportsBloc({required InvoiceRepository invoiceRepository})
      : _invoiceRepository = invoiceRepository,
        super(const ReportsState()) {
    on<LoadSalesReport>(_onLoadSalesReport);
  }

  Future<void> _onLoadSalesReport(
      LoadSalesReport event, Emitter<ReportsState> emit) async {
    emit(state.copyWith(status: ReportsStatus.loading));
    try {
      final invoices = await _invoiceRepository.getInvoicesByDateRange(
          event.startDate.toIso8601String(), event.endDate.toIso8601String());
      emit(state.copyWith(
        status: ReportsStatus.success,
        salesReport: invoices,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReportsStatus.error, errorMessage: e.toString()));
    }
  }
}
