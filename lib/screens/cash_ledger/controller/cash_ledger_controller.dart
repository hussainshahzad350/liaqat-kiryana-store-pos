import 'package:flutter/foundation.dart';
import '../../../../core/repositories/cash_repository.dart';
import '../../../../models/cash_ledger_model.dart';
import '../../../../domain/entities/money.dart';
import 'package:intl/intl.dart';

enum CashLedgerState { loading, loaded, error }

typedef _CashLedgerStats = ({
  Money cashInDrawer,
  Money totalDigitalIn,
  Money totalInflow,
});

typedef _CashLedgerTransactions = ({
  List<CashLedger> entries,
  bool hasNextPage,
});

class CashLedgerController extends ChangeNotifier {
  final CashRepository _repository;

  CashLedgerController(this._repository);

  CashLedgerState state = CashLedgerState.loading;
  String? errorMessage;

  // Pagination & Data
  List<CashLedger> allEntries = [];
  int _page = 0;
  final int _limit = 20;
  bool hasNextPage = true;
  bool isLoadMoreRunning = false;
  int _requestToken = 0;

  // Filter properties
  DateTime? selectedDate; // null = show ALL transactions (default)
  String searchQuery = '';
  // Can be 'ALL', 'CASH', 'DIGITAL'
  String paymentModeFilter = 'ALL';

  // Balances
  Money cashInDrawer = Money.zero;
  Money totalDigitalIn = Money.zero;
  Money totalInflow = Money.zero;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    final token = ++_requestToken;
    state = CashLedgerState.loading;
    notifyListeners();

    _page = 0;
    hasNextPage = true;
    allEntries = [];

    try {
      final stats = await _loadStats();
      if (token != _requestToken) return;

      cashInDrawer = stats.cashInDrawer;
      totalDigitalIn = stats.totalDigitalIn;
      totalInflow = stats.totalInflow;

      final transactions = await _loadTransactions();
      if (token != _requestToken) return;

      allEntries = transactions.entries;
      hasNextPage = transactions.hasNextPage;

      errorMessage = null;
      state = CashLedgerState.loaded;
    } catch (e) {
      if (token != _requestToken) return;
      state = CashLedgerState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<_CashLedgerStats> _loadStats() async {
    // Current physical cash in drawer (filtered for CASH only)
    final cashInDrawer = await _repository.getPhysicalCashBalance();

    // Pull today's entries to compute daily inflow split
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayEntries =
        await _repository.getCashLedgerByDateRange(todayStr, todayStr);

    int cashInPaisas = 0;
    int digitalInPaisas = 0;

    for (var entry in dayEntries) {
      if (entry.isInflow) {
        if (entry.paymentMode.isCash) {
          cashInPaisas += entry.amount;
        } else {
          digitalInPaisas += entry.amount;
        }
      }
    }

    return (
      cashInDrawer: cashInDrawer,
      totalDigitalIn: Money.fromPaisas(digitalInPaisas),
      totalInflow: Money.fromPaisas(cashInPaisas + digitalInPaisas),
    );
  }

  Future<_CashLedgerTransactions> _loadTransactions() async {
    List<CashLedger> data;
    var nextHasNextPage = true;

    if (selectedDate != null) {
      // Date-filtered mode
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
      data = await _repository.getCashLedgerByDateRange(
        dateStr,
        dateStr,
        paymentModeFilter: paymentModeFilter,
      );
      nextHasNextPage = false; // date-range loads all at once
    } else if (searchQuery.isNotEmpty) {
      // Search mode
      data = await _repository.searchCashLedger(
        searchQuery,
        paymentModeFilter: paymentModeFilter,
      );
      nextHasNextPage = false;
    } else {
      // Default: paginated all-time view (matches old screen behavior)
      data = await _repository.getCashLedger(
        limit: _limit,
        offset: 0,
        paymentModeFilter: paymentModeFilter,
      );
      if (data.length < _limit) {
        nextHasNextPage = false;
      }
    }

    return (
      entries: data,
      hasNextPage: nextHasNextPage,
    );
  }

  Future<void> loadMore() async {
    if (isLoadMoreRunning || !hasNextPage || state != CashLedgerState.loaded) {
      return;
    }
    // Only paginated in default all-time view
    if (selectedDate != null || searchQuery.isNotEmpty) return;

    isLoadMoreRunning = true;
    notifyListeners();

    final token = _requestToken;

    try {
      final nextPage = _page + 1;
      final data = await _repository.getCashLedger(
        limit: _limit,
        offset: nextPage * _limit,
        paymentModeFilter: paymentModeFilter,
      );
      if (token != _requestToken) return;

      _page = nextPage;

      if (data.isNotEmpty) {
        allEntries.addAll(data);
      }

      if (data.length < _limit) {
        hasNextPage = false;
      }
    } catch (e) {
      if (token != _requestToken) return;
      errorMessage = e.toString();
    } finally {
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  void updateDate(DateTime? newDate) {
    selectedDate = newDate;
    refresh();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    refresh();
  }

  void setPaymentModeFilter(String mode) {
    paymentModeFilter = mode;
    refresh();
  }
}
