import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../bloc/stock/stock_overview/stock_overview_bloc.dart';
import '../../bloc/stock/stock_overview/stock_overview_state.dart';
import '../../bloc/stock/stock_overview/stock_overview_event.dart';
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
import '../../core/constants/desktop_dimensions.dart';

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
  List<StockActivityEntity> _lastLoadedActivities = const [];
  bool _lastActivitiesReachedMax = true;

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
    if (!mounted) return;
    setState(() => _showSidePanel = false);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _tableFocusNode.dispose();
    super.dispose();
  }

  void _openAdjustStockPanel(StockItemEntity item) {
    final loc = AppLocalizations.of(context)!;
    _openSidePanel(
      '${loc.adjustStock}: ${item.nameEnglish}',
      _StockAdjustmentForm(
        item: item,
        onSave: (adjustment, reason) {
          context.read<StockActivityBloc>().add(AdjustStock(
                productId: item.id,
                quantityChange: adjustment,
                reason: reason,
                reference: loc.adjustStock,
              ));
          _closeSidePanel();
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
    final loc = AppLocalizations.of(context)!;
    _openSidePanel(
      loc.confirmation,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              loc.confirmCancelInvoiceMessage,
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
                        '${loc.activityType}: ${activity.referenceNumber}',
                        _buildActivityDetailPanel(context, activity),
                      );
                    },
                    child: Text(loc.no),
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () {
                      context.read<StockActivityBloc>().add(CancelStockActivity(
                            activity: activity,
                            reason: loc.cancel,
                          ));
                      _closeSidePanel();
                    },
                    child: Text(loc.cancel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetailPanel(
      BuildContext context, StockActivityEntity activity) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isCancelled = activity.status == 'CANCELLED';

    return Column(
      children: [
        // Receipt Header
        Container(
          padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
          color: colorScheme.surface,
          child: Column(
            children: [
              Icon(
                _getActivityIcon(activity.type),
                size: DesktopDimensions.iconSizeXXLarge,
                color: isCancelled
                    ? colorScheme.onSurface.withOpacity(0.5)
                    : colorScheme.primary,
              ),
              const SizedBox(height: DesktopDimensions.spacingSmall),
              Text(
                activity.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: DesktopDimensions.headingSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                activity.referenceNumber,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: DesktopDimensions.spacingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingSmall,
                    vertical: DesktopDimensions.spacingXSmall),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.extraSmallBorderRadius),
                ),
                child: Text(
                  activity.status,
                  style: TextStyle(
                    color: isCancelled
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
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
            padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
            children: [
              _buildDetailRow(loc.date,
                  DateFormat('yyyy-MM-dd').format(activity.timestamp)),
              _buildDetailRow(
                  loc.time, DateFormat('hh:mm a').format(activity.timestamp)),
              _buildDetailRow(loc.customer, activity.user),
              const Divider(),
              _buildDetailRow(loc.description, activity.description),
              if (activity.quantityChange != 0)
                _buildDetailRow(loc.quantity,
                    '${activity.quantityChange > 0 ? '+' : ''}${activity.quantityChange}'),
              if (activity.financialImpact != null)
                _buildDetailRow(
                    loc.amount, activity.financialImpact!.formatted),
            ],
          ),
        ),

        // Actions Footer
        Container(
          padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isCancelled &&
                  (activity.type == ActivityType.purchase ||
                      activity.type == ActivityType.sale))
                OutlinedButton.icon(
                  onPressed: () => _openCancelConfirmationPanel(activity),
                  icon: const Icon(Icons.cancel),
                  label: Text(loc.cancel),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error),
                ),
              const SizedBox(height: DesktopDimensions.spacingSmall),
              ElevatedButton.icon(
                onPressed: () async {
                  final locale = Localizations.localeOf(context);
                  try {
                    await _pdfExportService.exportActivityPdf(activity,
                        languageCode: locale.languageCode);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.saveAsPdf)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${loc.error}: $e'),
                          backgroundColor: colorScheme.error),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(loc.saveAsPdf),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: DesktopDimensions.spacingXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.purchase:
        return Icons.shopping_cart;
      case ActivityType.sale:
        return Icons.sell;
      case ActivityType.adjustment:
        return Icons.tune;
      case ActivityType.returnIn:
        return Icons.keyboard_return;
      case ActivityType.returnOut:
        return Icons.outbound;
    }
  }

  String _localizedActionMessage(AppLocalizations loc, String message) {
    switch (message) {
      case 'Stock adjustment submitted':
        return loc.stockUpdated;
      case 'Transaction cancelled successfully':
        return loc.invoiceCancelledSuccess;
      default:
        return message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            ActivateSearchIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ClosePanelIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            MoveSelectionDownIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateSelectionIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            NewPurchaseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (_) {
            context.read<StockOverviewBloc>().add(const LoadStockOverview());
            context.read<StockActivityBloc>().add(LoadStockActivities());
            return null;
          }),
          ActivateSearchIntent:
              CallbackAction<ActivateSearchIntent>(onInvoke: (_) {
            _searchFocusNode.requestFocus();
            return null;
          }),
          ClosePanelIntent: CallbackAction<ClosePanelIntent>(onInvoke: (_) {
            if (_showSidePanel) _closeSidePanel();
            return null;
          }),
          MoveSelectionUpIntent:
              CallbackAction<MoveSelectionUpIntent>(onInvoke: (_) {
            if (_focusedIndex > 0) setState(() => _focusedIndex--);
            return null;
          }),
          MoveSelectionDownIntent:
              CallbackAction<MoveSelectionDownIntent>(onInvoke: (_) {
            if (_focusedIndex < _currentDisplayedItems.length - 1) {
              setState(() => _focusedIndex++);
            }
            return null;
          }),
          ActivateSelectionIntent:
              CallbackAction<ActivateSelectionIntent>(onInvoke: (_) {
            if (_currentDisplayedItems.isNotEmpty &&
                _focusedIndex >= 0 &&
                _focusedIndex < _currentDisplayedItems.length) {
              _openAdjustStockPanel(_currentDisplayedItems[_focusedIndex]);
            }
            return null;
          }),
          NewPurchaseIntent: CallbackAction<NewPurchaseIntent>(onInvoke: (_) {
            Navigator.pushNamed(context, AppRoutes.purchase);
            return null;
          }),
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<StockFilterBloc, StockFilterState>(
              listener: (context, filterState) {
                context.read<StockOverviewBloc>().add(LoadStockOverview(
                      query: filterState.searchQuery,
                      status: filterState.statusFilter,
                      supplierId: filterState.selectedSupplierId,
                      categoryId: filterState.selectedCategoryId,
                    ));
              },
            ),
            BlocListener<StockActivityBloc, StockActivityState>(
              listener: (context, state) {
                if (!mounted) return;
                if (state is StockActivityActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(_localizedActionMessage(loc, state.message))),
                  );

                  final filterState = context.read<StockFilterBloc>().state;
                  context.read<StockOverviewBloc>().add(LoadStockOverview(
                        query: filterState.searchQuery,
                        status: filterState.statusFilter,
                        supplierId: filterState.selectedSupplierId,
                        categoryId: filterState.selectedCategoryId,
                      ));
                } else if (state is StockActivityActionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(_localizedActionMessage(loc, state.message)),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
          child: Column(
            children: [
              // 1. Actions Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingMedium,
                    vertical: DesktopDimensions.spacingStandard),
                color: colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    ElevatedButton.icon(
                      onPressed: () {
                        _tableFocusNode.requestFocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.adjustStock)));
                      },
                      icon: const Icon(Icons.tune),
                      label: Text(loc.adjustStock),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
                  child: Column(
                    children: [
                      // 2. KPI Strip
                      BlocBuilder<StockOverviewBloc, StockOverviewState>(
                        builder: (context, state) {
                          if (state is StockOverviewLoaded) {
                            return _buildKPIStrip(
                                context, loc, colorScheme, state.summary);
                          }
                          return _buildKPISkeleton(colorScheme);
                        },
                      ),
                      const SizedBox(height: DesktopDimensions.spacingLarge),
                      // 3. Filters
                      _buildFilters(context, loc, colorScheme),
                      const SizedBox(height: DesktopDimensions.spacingLarge),
                      // 4. Main Content Area
                      Expanded(
                          child:
                              _buildMainContentArea(context, loc, colorScheme)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIStrip(BuildContext context, AppLocalizations loc,
      ColorScheme colorScheme, StockSummaryEntity summary) {
    return Row(
      children: [
        _buildKPICard(
            loc.totalItems, '${summary.totalItemsCount}', colorScheme.primary),
        _buildKPICard(
            loc.stockValue,
            summary.totalStockSalesValue.formattedNoDecimal,
            colorScheme.secondary),
        _buildKPICard(loc.totalCost, summary.totalStockCost.formattedNoDecimal,
            colorScheme.onSurfaceVariant),
        _buildKPICard(loc.lowStock, '${summary.lowStockItemsCount}',
            colorScheme.tertiary),
        _buildKPICard(loc.outOfStock, '${summary.outOfStockItemsCount}',
            colorScheme.error),
        _buildKPICard('Expired', '${summary.expiredOrNearExpiryCount}',
            colorScheme.onErrorContainer),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: DesktopDimensions.cardElevation,
        margin: const EdgeInsets.symmetric(
            horizontal: DesktopDimensions.spacingSmall),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: DesktopDimensions.spacingXSmall),
              Text(
                value,
                style: TextStyle(
                    fontSize: DesktopDimensions.headingSize,
                    fontWeight: FontWeight.bold,
                    color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      elevation: DesktopDimensions.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
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
                        onChanged: (val) => context
                            .read<StockFilterBloc>()
                            .add(SetSearchQuery(val)),
                        decoration: InputDecoration(
                          hintText: loc.searchStock,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingMedium),
                    Expanded(
                      child: DropdownButton<int>(
                        value: state.selectedCategoryId,
                        hint: Text(loc.categories),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: null, child: Text(loc.all)),
                          ...state.availableCategories
                              .map((c) => DropdownMenuItem(
                                    value: c['id'] as int,
                                    child: Text(c['name_english']),
                                  )),
                        ],
                        onChanged: (v) => context
                            .read<StockFilterBloc>()
                            .add(SetCategoryFilter(v)),
                      ),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingMedium),
                    Expanded(
                      child: DropdownButton<int>(
                        value: state.selectedSupplierId,
                        hint: Text(loc.selectSupplier),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: null, child: Text(loc.all)),
                          ...state.availableSuppliers
                              .map((s) => DropdownMenuItem(
                                    value: s['id'] as int,
                                    child: Text(s['name_english']),
                                  )),
                        ],
                        onChanged: (v) => context
                            .read<StockFilterBloc>()
                            .add(SetSupplierFilter(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                Row(
                  children: [
                    Wrap(
                      spacing: DesktopDimensions.spacingMedium,
                      children: [
                        FilterChip(
                          label: Text(loc.all),
                          selected: state.statusFilter == 'ALL',
                          onSelected: (v) => context
                              .read<StockFilterBloc>()
                              .add(SetStatusFilter('ALL')),
                        ),
                        FilterChip(
                          label: Text(loc.lowStock),
                          selected: state.statusFilter == 'LOW',
                          onSelected: (v) => context
                              .read<StockFilterBloc>()
                              .add(SetStatusFilter('LOW')),
                          backgroundColor:
                              colorScheme.tertiaryContainer.withOpacity(0.3),
                          selectedColor: colorScheme.tertiaryContainer,
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: state.statusFilter == 'LOW'
                                      ? colorScheme.tertiary
                                      : Colors.transparent)),
                        ),
                        FilterChip(
                          label: Text(loc.outOfStock),
                          selected: state.statusFilter == 'OUT',
                          onSelected: (v) => context
                              .read<StockFilterBloc>()
                              .add(SetStatusFilter('OUT')),
                          backgroundColor:
                              colorScheme.errorContainer.withOpacity(0.3),
                          selectedColor: colorScheme.errorContainer,
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: state.statusFilter == 'OUT'
                                      ? colorScheme.error
                                      : Colors.transparent)),
                        ),
                        FilterChip(
                          label: const Text('Expired'),
                          selected: state.statusFilter == 'EXPIRED',
                          onSelected: (v) => context
                              .read<StockFilterBloc>()
                              .add(SetStatusFilter('EXPIRED')),
                          backgroundColor:
                              colorScheme.onErrorContainer.withOpacity(0.3),
                          selectedColor: colorScheme.onErrorContainer,
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: state.statusFilter == 'EXPIRED'
                                      ? colorScheme.onError
                                      : Colors.transparent)),
                        ),
                        FilterChip(
                          label: const Text('Old Stock'),
                          selected: state.statusFilter == 'OLD',
                          onSelected: (v) => context
                              .read<StockFilterBloc>()
                              .add(SetStatusFilter('OLD')),
                          backgroundColor:
                              colorScheme.secondaryContainer.withOpacity(0.3),
                          selectedColor: colorScheme.secondaryContainer,
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: state.statusFilter == 'OLD'
                                      ? colorScheme.secondary
                                      : Colors.transparent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStockTable(
      BuildContext context,
      AppLocalizations loc,
      ColorScheme colorScheme,
      List<StockItemEntity> items,
      bool hasReachedMax) {
    void onSort(int columnIndex, bool ascending) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _isAscending = ascending;
      });
    }

    final sortedItems = List<StockItemEntity>.from(items);
    sortedItems.sort((a, b) {
      int result = 0;
      switch (_sortColumnIndex) {
        case 0:
          result = a.nameEnglish.compareTo(b.nameEnglish);
          break;
        case 1:
          result = (a.categoryName ?? '').compareTo(b.categoryName ?? '');
          break;
        case 2:
          result = a.costPrice.paisas.compareTo(b.costPrice.paisas);
          break;
        case 3:
          result = a.salePrice.paisas.compareTo(b.salePrice.paisas);
          break;
        case 4:
          result = a.currentStock.compareTo(b.currentStock);
          break;
        case 5:
          result = a.totalSalesValue.paisas.compareTo(b.totalSalesValue.paisas);
          break;
      }
      return _isAscending ? result : -result;
    });

    if (_focusedIndex >= sortedItems.length) {
      _focusedIndex = sortedItems.isEmpty ? 0 : sortedItems.length - 1;
    }
    _currentDisplayedItems = sortedItems;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesktopDimensions.cardBorderRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
            child: Text(
              loc.stockDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Focus(
                focusNode: _tableFocusNode,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _isAscending,
                  headingRowHeight: DesktopDimensions.tableHeaderHeight,
                  dataRowMinHeight: DesktopDimensions.tableDataRowHeight,
                  dataRowMaxHeight: DesktopDimensions.tableDataRowHeight,
                  headingRowColor:
                      MaterialStateProperty.all(colorScheme.primaryContainer),
                  headingTextStyle:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                  columns: [
                    DataColumn(label: Text(loc.item), onSort: onSort),
                    DataColumn(label: Text(loc.category), onSort: onSort),
                    DataColumn(
                        label: Text(loc.cost), onSort: onSort, numeric: true),
                    DataColumn(
                        label: Text(loc.price), onSort: onSort, numeric: true),
                    DataColumn(
                        label: Text(loc.quantity),
                        onSort: onSort,
                        numeric: true),
                    DataColumn(
                        label: Text(loc.stockValue),
                        onSort: onSort,
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
                    final isSelected = index == _focusedIndex;

                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          setState(() => _focusedIndex = index);
                          _openAdjustStockPanel(item);
                        }
                      },
                      color:
                          MaterialStateProperty.resolveWith<Color?>((states) {
                        if (isSelected) {
                          return colorScheme.primaryContainer.withOpacity(0.3);
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(Text(item.nameEnglish,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500))),
                        DataCell(Text(item.categoryName ?? '-')),
                        DataCell(Text(item.costPrice.formattedNoDecimal)),
                        DataCell(Text(item.salePrice.formattedNoDecimal)),
                        DataCell(Text(item.currentStock.toString())),
                        DataCell(Text(item.totalSalesValue.formattedNoDecimal)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: DesktopDimensions.spacingSmall,
                                vertical: DesktopDimensions.spacingXSmall),
                            decoration: BoxDecoration(
                              color: isOut
                                  ? colorScheme.errorContainer
                                  : (isLow
                                      ? colorScheme.tertiaryContainer
                                      : colorScheme.primaryContainer),
                              borderRadius: BorderRadius.circular(
                                  DesktopDimensions.extraSmallBorderRadius),
                            ),
                            child: Text(
                              isOut
                                  ? loc.outOfStock
                                  : (isLow ? loc.lowStock : loc.ok),
                              style: Theme.of(context)
                                  .textTheme
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
                                _openAdjustStockPanel(item);
                              } else if (value == 'purchase') {
                                _showQuickPurchaseDialog(context, item);
                              } else if (value == 'history') {
                                _openSidePanel(
                                  '${loc.recentActivities}: ${item.nameEnglish}',
                                  Center(child: Text(loc.noDataAvailable)),
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
          if (!hasReachedMax)
            Padding(
              padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
              child: TextButton(
                onPressed: () => context
                    .read<StockOverviewBloc>()
                    .add(LoadMoreStockOverview()),
                child: const Text('Load More Items'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockTableSkeleton(ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesktopDimensions.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(
                width: 200, height: DesktopDimensions.headingSize),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Expanded(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                itemBuilder: (_, __) => const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child:
                            SkeletonLoader(height: DesktopDimensions.bodySize)),
                    SizedBox(width: DesktopDimensions.spacingMedium),
                    Expanded(
                        flex: 1,
                        child:
                            SkeletonLoader(height: DesktopDimensions.bodySize)),
                    SizedBox(width: DesktopDimensions.spacingMedium),
                    Expanded(
                        flex: 1,
                        child:
                            SkeletonLoader(height: DesktopDimensions.bodySize)),
                    SizedBox(width: DesktopDimensions.spacingMedium),
                    Expanded(
                        flex: 1,
                        child:
                            SkeletonLoader(height: DesktopDimensions.bodySize)),
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
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(DesktopDimensions.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(
                width: 150, height: DesktopDimensions.headingSize),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesktopDimensions.spacingStandard),
                itemBuilder: (_, __) => const SkeletonLoader(
                    height: DesktopDimensions.bodySize * 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingMedium,
          vertical: DesktopDimensions.spacingStandard),
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: const Row(children: [
        Expanded(child: SkeletonLoader(height: DesktopDimensions.kpiHeight))
      ]),
    );
  }

  Widget _buildRecentActivities(
      BuildContext context,
      AppLocalizations loc,
      ColorScheme colorScheme,
      List<StockActivityEntity> activities,
      bool hasReachedMax) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(DesktopDimensions.cardBorderRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
            child: Row(
              children: [
                const Icon(Icons.history,
                    size: DesktopDimensions.iconSizeSmallMedium),
                const SizedBox(width: DesktopDimensions.spacingSmall),
                Text(
                  loc.recentActivities,
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: DesktopDimensions.tableHeaderHeight,
                dataRowHeight: DesktopDimensions.tableDataRowHeight,
                columns: [
                  DataColumn(label: Text('${loc.date} & ${loc.time}')),
                  DataColumn(label: Text(loc.activityType)),
                  DataColumn(label: Text(loc.description)),
                  DataColumn(label: Text(loc.quantity)),
                  DataColumn(label: Text(loc.customer)),
                  DataColumn(label: Text(loc.status)),
                  DataColumn(label: Text(loc.action)),
                ],
                rows: activities.map((act) {
                  Color typeColor = colorScheme.onSurfaceVariant;
                  if (act.type == ActivityType.sale) {
                    typeColor = colorScheme.primary;
                  }
                  if (act.type == ActivityType.adjustment) {
                    typeColor = colorScheme.tertiary;
                  }
                  if (act.type == ActivityType.purchase) {
                    typeColor = colorScheme.secondary;
                  }

                  final qty = act.quantityChange;
                  final qtyColor = qty > 0
                      ? colorScheme.secondary
                      : (qty < 0 ? colorScheme.error : colorScheme.onSurface);
                  final dateStr = act.timestamp
                      .toString()
                      .substring(0, 16)
                      .replaceFirst('T', ' ');

                  return DataRow(
                    cells: [
                      DataCell(Text(dateStr, style: textTheme.bodySmall)),
                      DataCell(Row(
                        children: [
                          Icon(Icons.circle,
                              size: DesktopDimensions.iconSizeXXXSmall,
                              color: typeColor),
                          const SizedBox(width: DesktopDimensions.spacingSmall),
                          Text(act.type.name.toUpperCase(),
                              style: textTheme.bodySmall),
                        ],
                      )),
                      DataCell(Text(act.referenceNumber,
                          style: textTheme.bodySmall)),
                      DataCell(Text(
                        qty > 0 ? '+$qty' : '$qty',
                        style: textTheme.bodySmall?.copyWith(
                            color: qtyColor, fontWeight: FontWeight.bold),
                      )),
                      DataCell(Text(act.user, style: textTheme.bodySmall)),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesktopDimensions.spacingSmall,
                            vertical: DesktopDimensions.spacingXSmall),
                        decoration: BoxDecoration(
                          color: act.status == 'CANCELLED'
                              ? colorScheme.errorContainer.withOpacity(0.5)
                              : colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.extraSmallBorderRadius),
                        ),
                        child: Text(
                          act.status,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: act.status == 'CANCELLED'
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility,
                              size: DesktopDimensions.iconSizeSmallMedium),
                          onPressed: () {
                            _openSidePanel(
                              '${loc.activityType}: ${act.referenceNumber}',
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
              padding: const EdgeInsets.all(DesktopDimensions.spacingSmall),
              child: TextButton(
                onPressed: () {
                  context
                      .read<StockActivityBloc>()
                      .add(LoadMoreStockActivities());
                },
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContentArea(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Row(
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
                child: Card(
                  elevation: DesktopDimensions.cardElevation,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius)),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(DesktopDimensions.cardPadding),
                    child: BlocBuilder<StockOverviewBloc, StockOverviewState>(
                      builder: (context, state) {
                        if (state is StockOverviewLoading) {
                          return _buildStockTableSkeleton(colorScheme);
                        }
                        if (state is StockOverviewError) {
                          return Center(
                              child: Text(state.message,
                                  style: TextStyle(color: colorScheme.error)));
                        }
                        if (state is StockOverviewLoaded) {
                          final hasReachedMax = state.hasReachedMax;
                          return _buildStockTable(context, loc, colorScheme,
                              state.items, hasReachedMax);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              // Recent Activities (Audit Layer)
              Expanded(
                flex: 1,
                child: Card(
                  elevation: DesktopDimensions.cardElevation,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius)),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(DesktopDimensions.cardPadding),
                    child: BlocBuilder<StockActivityBloc, StockActivityState>(
                      builder: (context, state) {
                        if (state is StockActivityLoading) {
                          return _buildActivitySkeleton(colorScheme);
                        }
                        if (state is StockActivityError) {
                          return Center(child: Text(state.message));
                        }
                        if (state is StockActivityLoaded) {
                          _lastLoadedActivities = state.activities;
                          _lastActivitiesReachedMax = state.hasReachedMax;
                          return _buildRecentActivities(
                              context,
                              loc,
                              colorScheme,
                              state.activities,
                              state.hasReachedMax);
                        }
                        if (state is StockActivityActionSuccess ||
                            state is StockActivityActionError) {
                          return _buildRecentActivities(
                            context,
                            loc,
                            colorScheme,
                            _lastLoadedActivities,
                            _lastActivitiesReachedMax,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right: Side Detail Panel
        if (_showSidePanel) ...[
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Expanded(
            flex: 4,
            child: Card(
              elevation: DesktopDimensions.cardElevation,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.cardBorderRadius)),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(DesktopDimensions.cardBorderRadius),
                child: Column(
                  children: [
                    // Panel Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesktopDimensions.spacingMedium,
                          vertical: DesktopDimensions.spacingStandard),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sidePanelTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _closeSidePanel,
                            iconSize: DesktopDimensions.iconSizeMedium,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Panel Content
                    Expanded(
                      child: _sidePanelContent ??
                          Center(child: Text(loc.noDataAvailable)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ActivateSearchIntent extends Intent {
  const ActivateSearchIntent();
}

class ClosePanelIntent extends Intent {
  const ClosePanelIntent();
}

class MoveSelectionUpIntent extends Intent {
  const MoveSelectionUpIntent();
}

class MoveSelectionDownIntent extends Intent {
  const MoveSelectionDownIntent();
}

class ActivateSelectionIntent extends Intent {
  const ActivateSelectionIntent();
}

class NewPurchaseIntent extends Intent {
  const NewPurchaseIntent();
}

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
      text: widget.item.currentStock
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.00$'), ''),
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
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                '${loc.stock}: ${widget.item.currentStock} ${widget.item.unit}'),
            const SizedBox(height: DesktopDimensions.spacingMedium),
            TextFormField(
              controller: _quantityCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.quantity,
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return loc.required;
                if (double.tryParse(value) == null) return loc.invalidAmount;
                return null;
              },
            ),
            const SizedBox(height: DesktopDimensions.spacingMedium),
            TextFormField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: loc.description,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? loc.required : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text(loc.cancel),
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(loc.save),
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
