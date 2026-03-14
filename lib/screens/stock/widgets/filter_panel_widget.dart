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

    return Card(
      elevation: AppTokens.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.filters,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: loc.search,
                prefixIcon: const Icon(Icons.search),
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.extraSmallBorderRadius),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedCategoryId,
                    hint: Text(loc.category),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.extraSmallBorderRadius),
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
                const SizedBox(width: AppTokens.spacingMedium),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedSupplierId,
                    hint: Text(loc.supplier),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.extraSmallBorderRadius),
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
            const SizedBox(height: AppTokens.spacingMedium),
            Row(
              children: [
                Wrap(
                  spacing: AppTokens.spacingMedium,
                  children: [
                    FilterChip(
                      label: Text(loc.all),
                      selected: statusFilter == 'ALL',
                      onSelected: (v) => onStatusFilterChanged('ALL'),
                    ),
                    FilterChip(
                      label: Text(loc.lowStock),
                      selected: statusFilter == 'LOW',
                      onSelected: (v) => onStatusFilterChanged('LOW'),
                      backgroundColor:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      selectedColor: colorScheme.tertiaryContainer,
                      shape: StadiumBorder(
                          side: BorderSide(
                              color: statusFilter == 'LOW'
                                  ? colorScheme.tertiary
                                  : Colors.transparent)),
                    ),
                    FilterChip(
                      label: Text(loc.outOfStock),
                      selected: statusFilter == 'OUT',
                      onSelected: (v) => onStatusFilterChanged('OUT'),
                      backgroundColor:
                          colorScheme.errorContainer.withValues(alpha: 0.3),
                      selectedColor: colorScheme.errorContainer,
                      shape: StadiumBorder(
                          side: BorderSide(
                              color: statusFilter == 'OUT'
                                  ? colorScheme.error
                                  : Colors.transparent)),
                    ),
                    FilterChip(
                      label: Text(loc.expired),
                      selected: statusFilter == 'EXPIRED',
                      onSelected: (v) => onStatusFilterChanged('EXPIRED'),
                      backgroundColor:
                          colorScheme.onErrorContainer.withValues(alpha: 0.3),
                      selectedColor: colorScheme.onErrorContainer,
                      shape: StadiumBorder(
                          side: BorderSide(
                              color: statusFilter == 'EXPIRED'
                                  ? colorScheme.onError
                                  : Colors.transparent)),
                    ),
                    FilterChip(
                      label: Text(loc.oldStock),
                      selected: statusFilter == 'OLD',
                      onSelected: (v) => onStatusFilterChanged('OLD'),
                      backgroundColor:
                          colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      selectedColor: colorScheme.secondaryContainer,
                      shape: StadiumBorder(
                          side: BorderSide(
                              color: statusFilter == 'OLD'
                                  ? colorScheme.secondary
                                  : Colors.transparent)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
