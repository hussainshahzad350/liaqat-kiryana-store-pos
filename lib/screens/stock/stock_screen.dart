import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_bloc.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_state.dart';
import '../../bloc/stock/stock_overveiw/stock_overview_event.dart';
import '../../bloc/stock/stock_filter/stock_filter_bloc.dart';
import '../../bloc/stock/stock_filter/stock_filter_state.dart';
import '../../bloc/stock/stock_filter/stock_filter_event.dart';
import '../../bloc/stock/stock_activity/stock_activity_bloc.dart';
import '../../bloc/stock/stock_activity/stock_activity_state.dart';
import '../../bloc/stock/stock_activity/stock_activity_event.dart';
import '../../core/entity/stock_item_entity.dart';
import '../../core/entity/stock_summary_entity.dart';
import '../../core/entity/stock_activity_entity.dart';
import '../../services/pdf_export_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/skeleton_loader.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  final FocusNode _tableFocusNode = FocusNode();
  int _focusedIndex = 0;
  List<StockItemEntity> _currentDisplayedItems = [];

  final PdfExportService _pdfExportService = PdfExportService();
  // Side Panel State
  bool _showSidePanel = false;
  String _sidePanelTitle = '';
  Widget? _sidePanelContent;

  final FocusNode _searchFocusNode = FocusNode();

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
  void dispose() {
    _searchFocusNode.dispose();
    _tableFocusNode.dispose();
    super.dispose();
  }

  void _openAdjustStockPanel(StockItemEntity item) {
    _openSidePanel(
      'Adjust Stock: ${item.nameEnglish}',
      _StockAdjustmentForm(
        item: item,
        onSave: (adjustment, reason) {
          context.read<StockActivityBloc>().add(AdjustStock(
            productId: item.id,
            quantityChange: adjustment,
            reason: reason,
            reference: 'Manual Adjustment',
          ));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock adjustment submitted for "${item.nameEnglish}"')));
          _closeSidePanel();
          
          // Refresh data
          final filterState = context.read<StockFilterBloc>().state;
          context.read<StockOverviewBloc>().add(LoadStockOverview(
            query: filterState.searchQuery,
            status: filterState.statusFilter,
            supplierId: filterState.selectedSupplierId,
            categoryId: filterState.selectedCategoryId,
          ));
          context.read<StockActivityBloc>().add(LoadStockActivities());
        },
        onCancel: _closeSidePanel,
      ),
    );
  }

  void _showQuickPurchaseDialog(BuildContext context, StockItemEntity item) {
    // Navigate to Purchase Screen (could pass arguments to prefill)
    Navigator.pushNamed(context, AppRoutes.purchase);
  }

  void _openCancelConfirmationPanel(StockActivityEntity activity) {
    _openSidePanel(
      'Confirm Cancellation',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Are you sure you want to cancel ${activity.referenceNumber}? This will reverse stock changes.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _openSidePanel(
                        'Activity: ${activity.referenceNumber}',
                        _buildActivityDetailPanel(context, activity),
                      );
                    },
                    child: const Text('No, Keep it'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () {
                      context.read<StockActivityBloc>().add(CancelStockActivity(
                        activity: activity,
                        reason: 'Manual Cancellation from Stock Screen',
                      ));
                      _closeSidePanel();
                    },
                    child: const Text('Yes, Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetailPanel(BuildContext context, StockActivityEntity activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCancelled = activity.status == 'CANCELLED';

    return Column(
      children: [
        // Receipt Header
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surface,
          child: Column(
            children: [
              Icon(
                _getActivityIcon(activity.type),
                size: 48,
                color: isCancelled ? Colors.grey : colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                activity.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                activity.referenceNumber,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? colorScheme.errorContainer : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activity.status,
                  style: TextStyle(
                    color: isCancelled ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Details List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDetailRow('Date', DateFormat('yyyy-MM-dd').format(activity.timestamp)),
              _buildDetailRow('Time', DateFormat('hh:mm a').format(activity.timestamp)),
              _buildDetailRow('User', activity.user),
              const Divider(),
              _buildDetailRow('Description', activity.description),
              if (activity.quantityChange != 0)
                _buildDetailRow('Quantity Change', '${activity.quantityChange > 0 ? '+' : ''}${activity.quantityChange}'),
                if (activity.financialImpact != null)
                _buildDetailRow('Financial Impact', activity.financialImpact!.formatted),
            ],
          ),
        ),

        // Actions Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isCancelled && (activity.type == ActivityType.purchase || activity.type == ActivityType.sale))
                OutlinedButton.icon(
                  onPressed: () => _openCancelConfirmationPanel(activity),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Transaction'),
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final locale = Localizations.localeOf(context);
                  try {
                    await _pdfExportService.exportActivityPdf(activity, languageCode: locale.languageCode);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF export completed.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF export failed: $e'), backgroundColor: colorScheme.error),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.purchase: return Icons.shopping_cart;
      case ActivityType.sale: return Icons.sell;
      case ActivityType.adjustment: return Icons.tune;
      case ActivityType.returnIn: return Icons.keyboard_return;
      case ActivityType.returnOut: return Icons.outbound;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): ActivateSearchIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ClosePanelIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateSelectionIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true): NewPurchaseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (_) {
            context.read<StockOverviewBloc>().add(const LoadStockOverview());
            context.read<StockActivityBloc>().add(LoadStockActivities());
            return null;
          }),
          ActivateSearchIntent: CallbackAction<ActivateSearchIntent>(onInvoke: (_) {
            _searchFocusNode.requestFocus();
            return null;
          }),
          ClosePanelIntent: CallbackAction<ClosePanelIntent>(onInvoke: (_) {
            if (_showSidePanel) _closeSidePanel();
            return null;
          }),
          MoveSelectionUpIntent: CallbackAction<MoveSelectionUpIntent>(onInvoke: (_) {
            if (_focusedIndex > 0) setState(() => _focusedIndex--);
            return null;
          }),
          MoveSelectionDownIntent: CallbackAction<MoveSelectionDownIntent>(onInvoke: (_) {
            if (_focusedIndex < _currentDisplayedItems.length - 1) setState(() => _focusedIndex++);
            return null;
          }),
          ActivateSelectionIntent: CallbackAction<ActivateSelectionIntent>(onInvoke: (_) {
            if (_currentDisplayedItems.isNotEmpty && _focusedIndex >= 0 && _focusedIndex < _currentDisplayedItems.length) {
              _openAdjustStockPanel(_currentDisplayedItems[_focusedIndex]);
            }
            return null;
          }),
          NewPurchaseIntent: CallbackAction<NewPurchaseIntent>(onInvoke: (_) {
            Navigator.pushNamed(context, AppRoutes.purchase);
            return null;
          }),
        },
        child: Scaffold(
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
                return _buildKPISkeleton(colorScheme);
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
                    flex: _showSidePanel ? 6 : 10,
                    child: Column(
                      children: [
                        // Stock Table (The Heart)
                        Expanded(
                          flex: 2,
                          child: BlocBuilder<StockOverviewBloc, StockOverviewState>(
                            builder: (context, state) {
                              if (state is StockOverviewLoading) {
                                return _buildStockTableSkeleton(colorScheme);
                              }
                              if (state is StockOverviewError) {
                                return Center(child: Text(state.message, style: TextStyle(color: colorScheme.error)));
                              }
                              if (state is StockOverviewLoaded) {
                                bool hasReachedMax = false;
                                try {
                                  hasReachedMax = (state as dynamic).hasReachedMax ?? false;
                                } catch (_) {
                                  // Handle case where getter throws due to null return
                                }
                                return _buildStockTable(context, loc, colorScheme, state.items, hasReachedMax);
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
                                return _buildActivitySkeleton(colorScheme);
                              }
                              if (state is StockActivityError) {
                                return Center(child: Text(state.message));
                              }
                              if (state is StockActivityLoaded) {
                                return _buildRecentActivities(context, loc, colorScheme, state.activities, state.hasReachedMax);
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
                    Expanded(
                      flex: 4,
                      child: Container(
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
                                Expanded(
                                  child: Text(
                                    _sidePanelTitle,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              Navigator.pushNamed(context, AppRoutes.purchase);
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
              // Focus table to allow keyboard nav to select item
              _tableFocusNode.requestFocus();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an item from the table and press Enter to adjust')));
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
          _buildKPICard(loc.stockValue, summary.totalStockSalesValue.formattedNoDecimal, Colors.green),
          _buildKPICard('Total Cost', summary.totalStockCost.formattedNoDecimal, Colors.grey),
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
                      focusNode: _searchFocusNode,
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

  Widget _buildStockTable(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, List<StockItemEntity> items, bool hasReachedMax) {
    
    // Sorting logic
    void onSort(int columnIndex, bool ascending) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _isAscending = ascending;
      });
    }

    // Create a copy to sort
    final sortedItems = List<StockItemEntity>.from(items);
    sortedItems.sort((a, b) {
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

    _currentDisplayedItems = sortedItems;

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
              child: Focus(
                focusNode: _tableFocusNode,
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
                showCheckboxColumn: false,
                rows: sortedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  bool isLow = item.isLowStock;
                  bool isOut = item.isOutOfStock;
                  final isSelected = index == _focusedIndex;

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (selected) {
                      if (selected == true) {
                        setState(() => _focusedIndex = index);
                        _openAdjustStockPanel(item);
                      }
                    },
                    color: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (isSelected) return colorScheme.primaryContainer.withOpacity(0.3);
                      return null;
                    }),
                    cells: [
                      DataCell(Text(item.nameEnglish, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(item.categoryName ?? '-')),
                      DataCell(Text(item.costPrice.formattedNoDecimal)),
                      DataCell(Text(item.salePrice.formattedNoDecimal)),
                      DataCell(Text(item.currentStock.toString())),
                      DataCell(Text(item.totalSalesValue.formattedNoDecimal)),
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
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'adjust') {
                              _openAdjustStockPanel(item);
                            } else if (value == 'purchase') {
                              _showQuickPurchaseDialog(context, item);
                            } else if (value == 'history') {
                              _openSidePanel(
                                'Item History: ${item.nameEnglish}',
                                const Center(child: Text('History feature coming soon.')),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(value: 'adjust', child: ListTile(leading: const Icon(Icons.tune), title: Text(loc.adjustStock))),
                            PopupMenuItem<String>(value: 'purchase', child: ListTile(leading: const Icon(Icons.add_shopping_cart), title: Text(loc.newPurchase))),
                            const PopupMenuItem<String>(value: 'history', child: ListTile(leading: Icon(Icons.history), title: Text('View History'))),
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
          if (!hasReachedMax)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => context.read<StockOverviewBloc>().add(LoadMoreStockOverview()),
                child: const Text('Load More Items'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockTableSkeleton(ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 200, height: 20),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, __) => const Row(
                  children: [
                    Expanded(flex: 2, child: SkeletonLoader(height: 16)),
                    SizedBox(width: 16),
                    Expanded(flex: 1, child: SkeletonLoader(height: 16)),
                    SizedBox(width: 16),
                    Expanded(flex: 1, child: SkeletonLoader(height: 16)),
                    SizedBox(width: 16),
                    Expanded(flex: 1, child: SkeletonLoader(height: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySkeleton(ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 150, height: 20),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const SkeletonLoader(height: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: const Row(children: [Expanded(child: SkeletonLoader(height: 60))]),
    );
  }

  Widget _buildRecentActivities(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, List<StockActivityEntity> activities, bool hasReachedMax) {
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
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Reference')),
                  DataColumn(label: Text('Qty Impact')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: activities.map((act) {
                  Color typeColor = Colors.grey;
                  if (act.type == ActivityType.sale) typeColor = Colors.blue;
                  if (act.type == ActivityType.adjustment) typeColor = Colors.orange;
                  if (act.type == ActivityType.purchase) typeColor = Colors.green;

                  final qty = act.quantityChange;
                  final qtyColor = qty > 0 ? Colors.green : (qty < 0 ? Colors.red : Colors.grey);
                  final dateStr = act.timestamp.toString().substring(0, 16).replaceFirst('T', ' ');

                  return DataRow(
                    cells: [
                      DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                      DataCell(Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: typeColor),
                          const SizedBox(width: 8),
                          Text(act.type.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ],
                      )),
                      DataCell(Text(act.referenceNumber, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                        qty > 0 ? '+$qty' : '$qty',
                        style: TextStyle(color: qtyColor, fontWeight: FontWeight.bold, fontSize: 12),
                      )),
                      DataCell(Text(act.user, style: const TextStyle(fontSize: 12))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: act.status == 'CANCELLED' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          act.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: act.status == 'CANCELLED' ? Colors.red : Colors.green,
                          ),
                        ),
                      )),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 18),
                          onPressed: () {
                            _openSidePanel(
                              'Activity: ${act.referenceNumber}',
                              _buildActivityDetailPanel(context, act),
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
          if (!hasReachedMax)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () {
                  context.read<StockActivityBloc>().add(LoadMoreStockActivities());
                },
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}
class ActivateSearchIntent extends Intent {
  const ActivateSearchIntent();
}
class ClosePanelIntent extends Intent { const ClosePanelIntent(); }
class MoveSelectionUpIntent extends Intent { const MoveSelectionUpIntent(); }
class MoveSelectionDownIntent extends Intent { const MoveSelectionDownIntent(); }
class ActivateSelectionIntent extends Intent { const ActivateSelectionIntent(); }
class NewPurchaseIntent extends Intent { const NewPurchaseIntent(); }

class _StockAdjustmentForm extends StatefulWidget {
  final StockItemEntity item;
  final Function(double, String) onSave;
  final VoidCallback onCancel;

  const _StockAdjustmentForm({
    required this.item,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_StockAdjustmentForm> createState() => _StockAdjustmentFormState();
}

class _StockAdjustmentFormState extends State<_StockAdjustmentForm> {
  late TextEditingController _quantityCtrl;
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: widget.item.currentStock.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
    );
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Current Stock: ${widget.item.currentStock} ${widget.item.unit}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Adjustment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newQty = double.parse(_quantityCtrl.text);
      final diff = newQty - widget.item.currentStock;
      if (diff != 0) {
        widget.onSave(diff, _reasonCtrl.text);
      } else {
        widget.onCancel();
      }
    }
  }
}