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
    on<LoadTodayReport>(_onLoadTodayReport);
    on<LoadWeekReport>(_onLoadWeekReport);
    on<LoadMonthReport>(_onLoadMonthReport);
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

  Future<void> _onLoadTodayReport(
      LoadTodayReport event, Emitter<ReportsState> emit) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    await _onLoadSalesReport(LoadSalesReport(startDate: start, endDate: end), emit);
  }

  Future<void> _onLoadWeekReport(
      LoadWeekReport event, Emitter<ReportsState> emit) async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    await _onLoadSalesReport(LoadSalesReport(startDate: start, endDate: end), emit);
  }

  Future<void> _onLoadMonthReport(
      LoadMonthReport event, Emitter<ReportsState> emit) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
    await _onLoadSalesReport(LoadSalesReport(startDate: start, endDate: end), emit);
  }
}
