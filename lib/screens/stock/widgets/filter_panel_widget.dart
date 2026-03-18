import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/res/app_tokens.dart';

typedef OnStatusFilterChanged = Function(String status);
typedef OnSupplierFilterChanged = Function(int? supplierId);

class FilterPanelWidget extends StatelessWidget {
  final String searchQuery;
  final String statusFilter;
  final int? selectedSupplierId;
  final int? selectedCategoryId;
  final List<Map<String, dynamic>> availableSuppliers;
  final List<Map<String, dynamic>> availableCategories;
  final ValueChanged<String> onSearchChanged;
  final OnStatusFilterChanged onStatusFilterChanged;
  final OnSupplierFilterChanged onSupplierFilterChanged;
  final OnSupplierFilterChanged onCategoryFilterChanged;

  const FilterPanelWidget({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.selectedSupplierId,
    required this.selectedCategoryId,
    required this.availableSuppliers,
    required this.availableCategories,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onSupplierFilterChanged,
    required this.onCategoryFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Search box — fixed 220px
          SizedBox(
            width: 220,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: loc.search,
                prefixIcon: const Icon(Icons.search, size: AppTokens.iconSizeMedium),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spacingSmall,
                  horizontal: AppTokens.spacingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.extraSmallBorderRadius),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          // Status filter chips — horizontal scrollable
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(context, loc.all, 'ALL'),
                  _buildChip(context, loc.lowStock, 'LOW'),
                  _buildChip(context, loc.outOfStock, 'OUT'),
                  _buildChip(context, loc.expiringSoon, 'SOON'),
                  _buildChip(context, loc.expired, 'EXPIRED'),
                  _buildChip(context, loc.deadStock, 'DEAD'),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          // Category dropdown — 140px
          SizedBox(
            width: 140, 
            child: DropdownButtonFormField<int?>(
              value: selectedCategoryId,
              hint: Text(loc.category),
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.extraSmallBorderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMedium,
                    vertical: AppTokens.spacingSmall),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(loc.all)),
                ...availableCategories.map((c) => DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(c['name_english'] as String),
                    )),
              ],
              onChanged: (v) => onCategoryFilterChanged(v),
            ),
          ),
          const SizedBox(width: AppTokens.spacingSmall),
          // Supplier dropdown — 140px
          SizedBox(
            width: 140, 
            child: DropdownButtonFormField<int?>(
              value: selectedSupplierId,
              hint: Text(loc.supplier),
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.extraSmallBorderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMedium,
                    vertical: AppTokens.spacingSmall),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(loc.all)),
                ...availableSuppliers.map((s) => DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text(s['name_english'] as String),
                    )),
              ],
              onChanged: (v) => onSupplierFilterChanged(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, String filterValue) {
    final isActive = statusFilter == filterValue;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.spacingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onStatusFilterChanged(filterValue),
        selectedColor: colorScheme.primary,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );
  }
}

