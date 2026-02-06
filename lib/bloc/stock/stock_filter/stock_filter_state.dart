import 'package:flutter/foundation.dart';

@immutable
class StockFilterState {
  final String searchQuery;
  final String statusFilter; // 'ALL', 'LOW', 'OUT', 'EXPIRED', 'OLD'
  final int? selectedSupplierId;
  final int? selectedCategoryId;
  final List<Map<String, dynamic>> availableSuppliers;
  final List<Map<String, dynamic>> availableCategories;
  final bool isLoading;
  final String? errorMessage;

  const StockFilterState({
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.selectedSupplierId,
    this.selectedCategoryId,
    this.availableSuppliers = const [],
    this.availableCategories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StockFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    int? selectedSupplierId,
    int? selectedCategoryId,
    List<Map<String, dynamic>>? availableSuppliers,
    List<Map<String, dynamic>>? availableCategories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StockFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedSupplierId: selectedSupplierId ?? this.selectedSupplierId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      availableSuppliers: availableSuppliers ?? this.availableSuppliers,
      availableCategories: availableCategories ?? this.availableCategories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
  
  // Helper to check if supplierId needs to be cleared (custom logic if needed)
  StockFilterState clearSupplier() {
    return StockFilterState(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      selectedSupplierId: null,
      selectedCategoryId: selectedCategoryId,
      availableSuppliers: availableSuppliers,
      availableCategories: availableCategories,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }

  StockFilterState clearCategory() {
    return StockFilterState(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      selectedSupplierId: selectedSupplierId,
      selectedCategoryId: null,
      availableSuppliers: availableSuppliers,
      availableCategories: availableCategories,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }
}
