import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/repositories/customers_repository.dart';
import '../../../../models/customer_model.dart';

class CustomerController extends ChangeNotifier {
  final CustomersRepository _repository;

  CustomerController(this._repository);

  // States
  List<Customer> activeCustomers = [];
  List<Customer> archivedCustomers = [];
  bool isLoading = true;
  bool isArchivedLoading = false;
  String? errorMessage;

  int countTotal = 0;
  int balTotal = 0;
  int countActive = 0;
  int balActive = 0;
  int countArchived = 0;
  int balArchived = 0;

  bool showArchive = false;
  Customer? ledgerCustomer;
  int selectedIndex = -1;

  int _searchToken = 0;
  Timer? _searchDebounce;
  String _currentQuery = '';

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadStats(),
      loadActiveCustomers(query: _currentQuery),
    ]);
    if (showArchive) {
      await loadArchivedCustomers();
    }
  }

  Future<void> loadStats() async {
    try {
      final s = await _repository.getCustomerStats();
      countTotal = (s['countTotal'] as num?)?.toInt() ?? 0;
      balTotal = (s['balTotal'] as num?)?.toInt() ?? 0;
      countActive = (s['countActive'] as num?)?.toInt() ?? 0;
      balActive = (s['balActive'] as num?)?.toInt() ?? 0;
      countArchived = (s['countArchived'] as num?)?.toInt() ?? 0;
      balArchived = (s['balArchived'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadActiveCustomers({String query = ''}) async {
    final token = ++_searchToken;
    if (activeCustomers.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final result = query.isEmpty
          ? await _repository.getActiveCustomers()
          : await _repository.searchCustomers(query, activeOnly: true);

      if (token != _searchToken) return;

      activeCustomers = result;
      selectedIndex = -1;
      isLoading = false;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (token != _searchToken) return;
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadArchivedCustomers() async {
    isArchivedLoading = true;
    notifyListeners();
    try {
      final result = await _repository.getArchivedCustomers();
      archivedCustomers = result;
      isArchivedLoading = false;
      notifyListeners();
    } catch (e) {
      isArchivedLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _currentQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      loadActiveCustomers(query: _currentQuery);
    });
  }

  void toggleArchiveView() {
    showArchive = !showArchive;
    if (showArchive) {
      loadArchivedCustomers();
    }
    notifyListeners();
  }

  void closeArchiveView() {
    showArchive = false;
    notifyListeners();
  }

  Future<void> toggleArchiveStatus(Customer customer) async {
    try {
      final updated = customer.copyWith(isActive: !customer.isActive);
      await _repository.updateCustomer(customer.id!, updated);
      await refresh();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer(Customer customer) async {
    try {
      await _repository.deleteCustomer(customer.id!);
      await refresh();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void openLedger(Customer customer) {
    ledgerCustomer = customer;
    notifyListeners();
  }

  void closeLedger() {
    ledgerCustomer = null;
    notifyListeners();
  }

  Future<void> refreshLedgerCustomer() async {
    if (ledgerCustomer?.id == null) return;
    try {
      final updated = await _repository.getCustomerById(ledgerCustomer!.id!);
      if (updated != null) {
        ledgerCustomer = updated;
        notifyListeners();
      }
    } catch (e) {
      // Ignore background refresh errors
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    if (index >= -1 && index < activeCustomers.length) {
      selectedIndex = index;
      notifyListeners();
    }
  }

  void handleKeyboardNavigation(bool isDown) {
    if (activeCustomers.isEmpty) return;
    if (isDown) {
      if (selectedIndex < activeCustomers.length - 1) {
        selectedIndex++;
        notifyListeners();
      }
    } else {
      if (selectedIndex > 0) {
        selectedIndex--;
        notifyListeners();
      } else if (selectedIndex == 0) {
        selectedIndex = -1;
        notifyListeners();
      }
    }
  }

  void submitSelected() {
    if (selectedIndex >= 0 && selectedIndex < activeCustomers.length) {
      openLedger(activeCustomers[selectedIndex]);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
