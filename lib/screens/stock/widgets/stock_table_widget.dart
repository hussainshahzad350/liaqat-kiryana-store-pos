import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/entity/stock_item_entity.dart';
import '../../../core/res/app_tokens.dart';
import '../utils/stock_sort_util.dart';

typedef OnAdjustStock = Function(StockItemEntity item);
typedef OnQuickPurchase = Function(BuildContext context, StockItemEntity item);
typedef OnViewHistory = Function(String title, StockItemEntity item);
typedef OnSort = Function(int columnIndex, bool ascending);

class StockTableWidget extends StatefulWidget {
  final List<StockItemEntity> items;
  final bool hasReachedMax;
  final int sortColumnIndex;
  final bool isAscending;
  final int focusedIndex;
  final OnAdjustStock onAdjustStock;
  final OnQuickPurchase onQuickPurchase;
  final OnViewHistory onViewHistory;
  final OnSort onSort;
  final VoidCallback onLoadMore;

  const StockTableWidget({
    super.key,
    required this.items,
    required this.hasReachedMax,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.focusedIndex,
    required this.onAdjustStock,
    required this.onQuickPurchase,
    required this.onViewHistory,
    required this.onSort,
    required this.onLoadMore,
  });

  @override
  State<StockTableWidget> createState() => _StockTableWidgetState();
}

class _StockTableWidgetState extends State<StockTableWidget> {
  final FocusNode _tableFocusNode = FocusNode();

  @override
  void dispose() {
    _tableFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortedItems = StockSortUtil.sort(
      items: widget.items,
      columnIndex: widget.sortColumnIndex,
      ascending: widget.isAscending,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.cardBorderRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMedium),
            child: Text(
              loc.stockDetails,
              style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Focus(
                focusNode: _tableFocusNode,
                child: DataTable(
                  sortColumnIndex: widget.sortColumnIndex,
                  sortAscending: widget.isAscending,
                  headingRowHeight: AppTokens.tableHeaderHeight,
                  dataRowMinHeight: AppTokens.tableDataRowHeight,
                  dataRowMaxHeight: AppTokens.tableDataRowHeight,
                  headingRowColor:
                      WidgetStateProperty.all(colorScheme.primaryContainer),
                  headingTextStyle:
                      textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                  columns: [
                    DataColumn(label: Text(loc.item), onSort: widget.onSort),
                    DataColumn(label: Text(loc.category), onSort: widget.onSort),
                    DataColumn(
                        label: Text(loc.cost), onSort: widget.onSort, numeric: true),
                    DataColumn(
                        label: Text(loc.price), onSort: widget.onSort, numeric: true),
                    DataColumn(
                        label: Text(loc.quantity),
                        onSort: widget.onSort,
                        numeric: true),
                    DataColumn(
                        label: Text(loc.stockValue),
                        onSort: widget.onSort,
                        numeric: true),
                    DataColumn(label: Text(loc.status)),
                    DataColumn(label: Text(loc.actions)),
                  ],
                  showCheckboxColumn: false,
                  rows: sortedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    bool isLow = item.isLowStock;
                    bool isOut = item.isOutOfStock;
                    final isSelected = index == widget.focusedIndex;

                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          widget.onAdjustStock(item);
                        }
                      },
                      color:
                          WidgetStateProperty.resolveWith<Color?>((states) {
                        if (isSelected) {
                          return colorScheme.primaryContainer.withValues(alpha: 0.3);
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(Text(item.nameEnglish,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500))),
                        DataCell(Text(item.categoryName ?? '-')),
                        DataCell(Text(item.costPrice.formattedNoDecimal)),
                        DataCell(Text(item.salePrice.formattedNoDecimal)),
                        DataCell(Text(item.currentStock.toString())),
                        DataCell(Text(item.totalSalesValue.formattedNoDecimal)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spacingSmall,
                                vertical: AppTokens.spacingXSmall),
                            decoration: BoxDecoration(
                              color: isOut
                                  ? colorScheme.errorContainer
                                  : (isLow
                                      ? colorScheme.tertiaryContainer
                                      : colorScheme.primaryContainer),
                              borderRadius: BorderRadius.circular(
                                  AppTokens.extraSmallBorderRadius),
                            ),
                            child: Text(
                              isOut
                                  ? loc.outOfStock
                                  : (isLow ? loc.lowStock : loc.ok),
                              style: textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isOut
                                        ? colorScheme.onErrorContainer
                                        : (isLow
                                            ? colorScheme.onTertiaryContainer
                                            : colorScheme.onPrimaryContainer),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'adjust') {
                                widget.onAdjustStock(item);
                              } else if (value == 'purchase') {
                                widget.onQuickPurchase(context, item);
                              } else if (value == 'history') {
                                widget.onViewHistory(
                                  '${loc.recentActivities}: ${item.nameEnglish}',
                                  item,
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                  value: 'adjust',
                                  child: ListTile(
                                      leading: const Icon(Icons.tune),
                                      title: Text(loc.adjustStock))),
                              PopupMenuItem<String>(
                                  value: 'purchase',
                                  child: ListTile(
                                      leading:
                                          const Icon(Icons.add_shopping_cart),
                                      title: Text(loc.newPurchase))),
                              PopupMenuItem<String>(
                                  value: 'history',
                                  child: ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(loc.recentActivities))),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (!widget.hasReachedMax)
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMedium),
              child: TextButton(
                onPressed: widget.onLoadMore,
                child: Text(loc.loadMoreItems),
              ),
            ),
        ],
      ),
    );
  }
}
