import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/currency_utils.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_bloc.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_state.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_event.dart';
import '../../bloc/stock/stock_filter/stock_filter_bloc.dart';
import '../../bloc/stock/stock_filter/stock_filter_state.dart';
import '../../bloc/stock/stock_filter/stock_filter_event.dart';
import '../../bloc/stock/stock_activity/stock_activity_bloc.dart';
import '../../bloc/stock/stock_activity/stock_activity_state.dart';
import '../../core/entity/stock_item_entity.dart';
import '../../core/entity/stock_summary_entity.dart';
import '../../core/entity/stock_activity_entity.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Side Panel State
  bool _showSidePanel = false;
  String _sidePanelTitle = '';
  Widget? _sidePanelContent;

  void _openSidePanel(String title, Widget content) {
    setState(() {
      _showSidePanel = true;
      _sidePanelTitle = title;
      _sidePanelContent = content;
    });
  }

  void _closeSidePanel() {
    setState(() => _showSidePanel = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // Coordinate Filter changes to Overview updates
      body: BlocListener<StockFilterBloc, StockFilterState>(
        listener: (context, filterState) {
          context.read<StockOverviewBloc>().add(LoadStockOverview(
                query: filterState.searchQuery,
                status: filterState.statusFilter,
                supplierId: filterState.selectedSupplierId,
                categoryId: filterState.selectedCategoryId,
              ));
        },
        child: Column(
          children: [
            // 1. Header & Actions (Uses FilterBloc for search state)
            _buildHeader(context, loc, colorScheme),

            // 2. KPI Strip (Uses OverviewBloc)
            BlocBuilder<StockOverviewBloc, StockOverviewState>(
              builder: (context, state) {
                if (state is StockOverviewLoaded) {
                  return _buildKPIStrip(context, loc, colorScheme, state.summary);
                }
                return const SizedBox(height: 80, child: Center(child: LinearProgressIndicator()));
              },
            ),

            // 3. Filters (Uses FilterBloc)
            _buildFilters(context, loc, colorScheme),

            // 4. Main Content Area (Split View)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Tables (Stock + Activities)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Stock Table (The Heart)
                        Expanded(
                          flex: 2,
                          child: BlocBuilder<StockOverviewBloc, StockOverviewState>(
                            builder: (context, state) {
                              if (state is StockOverviewLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (state is StockOverviewError) {
                                return Center(child: Text(state.message, style: TextStyle(color: colorScheme.error)));
                              }
                              if (state is StockOverviewLoaded) {
                                return _buildStockTable(context, loc, colorScheme, state.items);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        // Recent Activities (Audit Layer)
                        Expanded(
                          flex: 1,
                          child: BlocBuilder<StockActivityBloc, StockActivityState>(
                            builder: (context, state) {
                              if (state is StockActivityLoading) {
                                return const Center(child: LinearProgressIndicator());
                              }
                              if (state is StockActivityError) {
                                return Center(child: Text(state.message));
                              }
                              if (state is StockActivityLoaded) {
                                return _buildRecentActivities(context, loc, colorScheme, state.activities);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right: Side Detail Panel
                  if (_showSidePanel)
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
                        color: colorScheme.surface,
                      ),
                      child: Column(
                        children: [
                          // Panel Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            child: Row(
                              children: [
                                Text(
                                  _sidePanelTitle,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _closeSidePanel,
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Panel Content
                          Expanded(
                            child: _sidePanelContent ?? const Center(child: Text('No details')),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primary,
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: colorScheme.onPrimary, size: 28),
          const SizedBox(width: 12),
          Text(
            loc.stockManagement, // "Inventory System"
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const Spacer(),
          // Actions
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement New Purchase Dialog
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(loc.newPurchase),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement Stock Adjustment Dialog
            },
            icon: const Icon(Icons.tune),
            label: Text(loc.adjustStock),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIStrip(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, StockSummaryEntity summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          _buildKPICard(loc.totalItems, '${summary.totalItemsCount}', Colors.blue),
          _buildKPICard(loc.stockValue, CurrencyUtils.formatNoDecimal(summary.totalStockSalesValue), Colors.green),
          _buildKPICard('Total Cost', CurrencyUtils.formatNoDecimal(summary.totalStockCost), Colors.grey),
          _buildKPICard('Low Stock', '${summary.lowStockItemsCount}', Colors.orange),
          _buildKPICard('Out of Stock', '${summary.outOfStockItemsCount}', Colors.red),
          _buildKPICard('Expired', '${summary.expiredOrNearExpiryCount}', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BlocBuilder<StockFilterBloc, StockFilterState>(
        builder: (context, state) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) => context.read<StockFilterBloc>().add(SetSearchQuery(val)),
                      decoration: InputDecoration(
                        hintText: loc.searchStock,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: state.selectedCategoryId,
                      hint: Text(loc.categories),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(loc.all)),
                        ...state.availableCategories.map((c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text(c['name_english']),
                            )),
                      ],
                      onChanged: (v) => context.read<StockFilterBloc>().add(SetCategoryFilter(v)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: state.selectedSupplierId,
                      hint: Text(loc.selectSupplier),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(loc.all)),
                        ...state.availableSuppliers.map((s) => DropdownMenuItem(
                              value: s['id'] as int,
                              child: Text(s['name_english']),
                            )),
                      ],
                      onChanged: (v) => context.read<StockFilterBloc>().add(SetSupplierFilter(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Items'),
                        selected: state.statusFilter == 'ALL',
                        onSelected: (v) => context.read<StockFilterBloc>().add(SetStatusFilter('ALL')),
                      ),
                      FilterChip(
                        label: const Text('Low Stock'),
                        selected: state.statusFilter == 'LOW',
                        onSelected: (v) => context.read<StockFilterBloc>().add(SetStatusFilter('LOW')),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        selectedColor: Colors.orange.withOpacity(0.3),
                      ),
                      FilterChip(
                        label: const Text('Out of Stock'),
                        selected: state.statusFilter == 'OUT',
                        onSelected: (v) => context.read<StockFilterBloc>().add(SetStatusFilter('OUT')),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        selectedColor: Colors.red.withOpacity(0.3),
                      ),
                      FilterChip(
                        label: const Text('Expired'),
                        selected: state.statusFilter == 'EXPIRED',
                        onSelected: (v) => context.read<StockFilterBloc>().add(SetStatusFilter('EXPIRED')),
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        selectedColor: Colors.purple.withOpacity(0.3),
                      ),
                      FilterChip(
                        label: const Text('Old Stock'),
                        selected: state.statusFilter == 'OLD',
                        onSelected: (v) => context.read<StockFilterBloc>().add(SetStatusFilter('OLD')),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        selectedColor: Colors.grey.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockTable(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, List<StockItemEntity> items) {
    
    // Sorting logic
    void onSort(int columnIndex, bool ascending) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _isAscending = ascending;
      });
    }

    items.sort((a, b) {
      int result = 0;
      switch (_sortColumnIndex) {
        case 0: // Item Name
          result = a.nameEnglish.compareTo(b.nameEnglish);
          break;
        case 1: // Category
          result = (a.categoryName ?? '').compareTo(b.categoryName ?? '');
          break;
        case 2: // Buy Price
          result = a.costPrice.paisas.compareTo(b.costPrice.paisas);
          break;
        case 3: // Sale Price
          result = a.salePrice.paisas.compareTo(b.salePrice.paisas);
          break;
        case 4: // Quantity
          result = a.currentStock.compareTo(b.currentStock);
          break;
        case 5: // Stock Value
          result = a.totalSalesValue.paisas.compareTo(b.totalSalesValue.paisas);
          break;
      }
      return _isAscending ? result : -result;
    });

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Current Inventory State',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _isAscending,
                headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
                columns: [
                  DataColumn(label: Text(loc.item), onSort: onSort),
                  DataColumn(label: Text(loc.category), onSort: onSort),
                  DataColumn(label: const Text('Cost'), onSort: onSort, numeric: true), // Buy Price
                  DataColumn(label: Text(loc.price), onSort: onSort, numeric: true), // Sale Price
                  DataColumn(label: Text(loc.quantity), onSort: onSort, numeric: true),
                  DataColumn(label: const Text('Value'), onSort: onSort, numeric: true), // Total Worth
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: items.map((item) {
                  bool isLow = item.isLowStock;
                  bool isOut = item.isOutOfStock;

                  return DataRow(
                    cells: [
                      DataCell(Text(item.nameEnglish, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(item.categoryName ?? '-')),
                      DataCell(Text(CurrencyUtils.formatNoDecimal(item.costPrice))),
                      DataCell(Text(CurrencyUtils.formatNoDecimal(item.salePrice))),
                      DataCell(Text(item.currentStock.toString())),
                      DataCell(Text(CurrencyUtils.formatNoDecimal(item.totalSalesValue))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOut ? Colors.red[100] : (isLow ? Colors.orange[100] : Colors.green[100]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOut ? 'OUT' : (isLow ? 'LOW' : 'OK'),
                            style: TextStyle(
                              color: isOut ? Colors.red[900] : (isLow ? Colors.orange[900] : Colors.green[900]),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.history, size: 20),
                          onPressed: () {
                            _openSidePanel(
                              'Item History: ${item.nameEnglish}',
                              Center(child: Text('History for ${item.nameEnglish} will appear here.')),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, List<StockActivityEntity> activities) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Bottom margin only
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Recent Inventory Activities (Audit Log)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 40,
                dataRowHeight: 48,
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Ref')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: activities.map((act) {
                  Color typeColor = Colors.grey;
                  if (act.type == ActivityType.sale) typeColor = Colors.blue;
                  if (act.type == ActivityType.adjustment) typeColor = Colors.orange;
                  if (act.type == ActivityType.purchase) typeColor = Colors.green;

                  return DataRow(
                    cells: [
                      DataCell(Text(act.timestamp.toString().substring(11, 16))), // HH:mm
                      DataCell(Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: typeColor),
                          const SizedBox(width: 8),
                          Text(act.type.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ],
                      )),
                      DataCell(Text(act.description, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(act.referenceNumber)),
                      DataCell(Text(act.status, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 18),
                          onPressed: () {
                            _openSidePanel(
                              'Activity: ${act.referenceNumber}',
                              Center(child: Text('Audit details for ${act.id}')),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}