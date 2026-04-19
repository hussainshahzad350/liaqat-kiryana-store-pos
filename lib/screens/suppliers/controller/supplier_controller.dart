import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/repositories/suppliers_repository.dart';
import '../../../../models/supplier_model.dart';

class SupplierController extends ChangeNotifier {
  final SuppliersRepository _repository;

  SupplierController(this._repository);

  // States
  List<Supplier> activeSuppliers = [];
  List<Supplier> archivedSuppliers = [];
  bool isLoading = true;
  bool isArchivedLoading = false;
  String? listErrorMessage;
  String? statsErrorMessage;

  int countTotal = 0;
  int balTotal = 0;
  int countActive = 0;
  int balActive = 0;
  int countArchived = 0;
  int balArchived = 0;

  bool showArchive = false;
  Supplier? ledgerSupplier;
  int selectedIndex = -1;

  int _searchToken = 0;
  Timer? _searchDebounce;
  String _currentQuery = '';

  List<Supplier> get visibleSuppliers =>
      showArchive ? archivedSuppliers : activeSuppliers;

  String? get errorMessage => listErrorMessage ?? statsErrorMessage;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadStats(),
      loadActiveSuppliers(query: _currentQuery),
    ]);
    if (showArchive) {
      await loadArchivedSuppliers();
    }
  }

  Future<void> loadStats() async {
    try {
      final s = await _repository.getSupplierStats();
      countTotal = (s['countTotal'] as num?)?.toInt() ?? 0;
      balTotal = (s['balTotal'] as num?)?.toInt() ?? 0;
      countActive = (s['countActive'] as num?)?.toInt() ?? 0;
      balActive = (s['balActive'] as num?)?.toInt() ?? 0;
      countArchived = (s['countArchived'] as num?)?.toInt() ?? 0;
      balArchived = (s['balArchived'] as num?)?.toInt() ?? 0;
      statsErrorMessage = null;
      notifyListeners();
    } catch (e) {
      statsErrorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadActiveSuppliers({String query = ''}) async {
    final token = ++_searchToken;
    if (activeSuppliers.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    try {
      // Maintaining exact same method pattern without forced pagination to guarantee duplicate UX mapping
      final result = query.isEmpty
          ? await _repository.getActiveSuppliers()
          : await _repository.searchSuppliers(
              query,
              activeOnly: true,
            );

      final activeResult = result.map((e) => Supplier.fromMap(e)).toList();

      if (token != _searchToken) return;

      activeSuppliers = activeResult;
      selectedIndex = -1;
      isLoading = false;
      listErrorMessage = null;
      notifyListeners();
    } catch (e) {
      if (token != _searchToken) return;
      isLoading = false;
      listErrorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadArchivedSuppliers() async {
    isArchivedLoading = true;
    notifyListeners();
    try {
      final result = await _repository.getInactiveSuppliers();
      archivedSuppliers = result.map((e) => Supplier.fromMap(e)).toList();
      isArchivedLoading = false;
      listErrorMessage = null;
      notifyListeners();
    } catch (e) {
      isArchivedLoading = false;
      listErrorMessage = e.toString();
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _currentQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      loadActiveSuppliers(query: _currentQuery);
    });
  }

  void toggleArchiveView() {
    showArchive = !showArchive;
    if (showArchive) {
      loadArchivedSuppliers();
    }
    notifyListeners();
  }

  void closeArchiveView() {
    showArchive = false;
    notifyListeners();
  }

  Future<void> toggleArchiveStatus(Supplier supplier) async {
    try {
      await _repository.toggleSupplierStatus(supplier.id!);
      await refresh();
    } catch (e) {
      listErrorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteSupplier(Supplier supplier) async {
    try {
      await _repository.deleteSupplier(supplier.id!);
      await refresh();
      if (ledgerSupplier?.id == supplier.id) {
        ledgerSupplier = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      listErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void openLedger(Supplier supplier) {
    ledgerSupplier = supplier;
    notifyListeners();
  }

  void closeLedger() {
    ledgerSupplier = null;
    notifyListeners();
  }

  Future<void> refreshLedgerSupplier() async {
    if (ledgerSupplier?.id == null) return;
    try {
      final updatedMap = await _repository.getSupplierById(ledgerSupplier!.id!);
      if (updatedMap != null) {
        ledgerSupplier = Supplier.fromMap(updatedMap);
      } else {
        ledgerSupplier = null;
      }
      notifyListeners();
    } catch (e) {
      // Ignore background refresh errors
    }
  }

  void clearError() {
    listErrorMessage = null;
    statsErrorMessage = null;
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    if (index >= -1 && index < visibleSuppliers.length) {
      selectedIndex = index;
      notifyListeners();
    }
  }

  void handleKeyboardNavigation(bool isDown) {
    final suppliers = visibleSuppliers;
    if (suppliers.isEmpty) return;
    if (isDown) {
      if (selectedIndex < suppliers.length - 1) {
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
    final suppliers = visibleSuppliers;
    if (selectedIndex >= 0 && selectedIndex < suppliers.length) {
      openLedger(suppliers[selectedIndex]);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
