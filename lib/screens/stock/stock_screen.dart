import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../core/res/app_tokens.dart';
import '../../widgets/skeleton_loader.dart';

// New Imports
import 'dialogs/adjust_stock_dialog.dart';
import 'widgets/stock_table_widget.dart';
import 'widgets/activity_detail_panel_widget.dart';
import 'widgets/recent_activities_table_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/stock_table_skeleton_widget.dart';
import 'widgets/activity_table_skeleton_widget.dart';
import 'utils/stock_shortcuts.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;
  int _focusedIndex = 0;

  final PdfExportService _pdfExportService = PdfExportService();
  
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
    if (!mounted) return;
    setState(() => _showSidePanel = false);
  }

  void _openAdjustStockPanel(StockItemEntity item) {
    final loc = AppLocalizations.of(context)!;
    _openSidePanel(
      '${loc.adjustStock}: ${item.nameEnglish}',
      AdjustStockDialog(
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
    Navigator.pushNamed(context, AppRoutes.purchase);
  }

  void _openCancelConfirmationPanel(StockActivityEntity activity) {
    final loc = AppLocalizations.of(context)!;
    _openSidePanel(
      loc.confirmation,
      Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.confirmCancelInvoiceMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _openSidePanel(
                        '${loc.activityType}: ${activity.referenceNumber}',
                        ActivityDetailPanelWidget(
                          activity: activity,
                          onCancel: () => _openCancelConfirmationPanel(activity),
                          pdfExportService: _pdfExportService,
                        ),
                      );
                    },
                    child: Text(loc.no),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
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
          ],
        ),
      ),
    );
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
      shortcuts: StockShortcuts.shortcuts,
      child: Actions(
        actions: StockShortcuts.createActions(
          context: context,
          onRefresh: () {
            context.read<StockOverviewBloc>().add(const LoadStockOverview());
            context.read<StockActivityBloc>().add(LoadStockActivities());
          },
          onSearch: () {
            // Search focus handling would require a way to reach FilterPanelWidget's focus node
            // For now we keep it simple or implement a focus manager
          },
          onClosePanel: () {
            if (_showSidePanel) _closeSidePanel();
          },
          onMoveUp: () {
             if (_focusedIndex > 0) setState(() => _focusedIndex--);
          },
          onMoveDown: () {
            // Need access to current items length for proper boundary check
          },
          onActivate: () {
            // Need access to current items for activation
          },
          onNewPurchase: () => Navigator.pushNamed(context, AppRoutes.purchase),
        ),
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
                    SnackBar(content: Text(_localizedActionMessage(loc, state.message))),
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
                      content: Text(_localizedActionMessage(loc, state.message)),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
          child: Column(
            children: [
              _buildToolbar(context, loc, colorScheme),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacingLarge),
                  child: Column(
                    children: [
                      _buildKPISection(loc, colorScheme),
                      const SizedBox(height: AppTokens.spacingLarge),
                      _buildFilterSection(),
                      const SizedBox(height: AppTokens.spacingLarge),
                      Expanded(child: _buildMainContentArea(context, loc, colorScheme)),
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

  Widget _buildToolbar(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMedium,
          vertical: AppTokens.spacingStandard),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.purchase),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(loc.newPurchase),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: AppTokens.spacingStandard),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.adjustStock)));
            },
            icon: const Icon(Icons.tune),
            label: Text(loc.adjustStock),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(AppLocalizations loc, ColorScheme colorScheme) {
    return BlocBuilder<StockOverviewBloc, StockOverviewState>(
      builder: (context, state) {
        if (state is StockOverviewLoaded) {
          return _buildKPIStrip(context, loc, colorScheme, state.summary);
        }
        return _buildKPISkeleton(colorScheme);
      },
    );
  }

  Widget _buildKPIStrip(BuildContext context, AppLocalizations loc,
      ColorScheme colorScheme, StockSummaryEntity summary) {
    return Row(
      children: [
        _buildKPICard(context, loc.totalItems, '${summary.totalItemsCount}', colorScheme.primary),
        _buildKPICard(context, loc.stockValue, summary.totalStockSalesValue.formattedNoDecimal, colorScheme.secondary),
        _buildKPICard(context, loc.totalCost, summary.totalStockCost.formattedNoDecimal, colorScheme.onSurfaceVariant),
        _buildKPICard(context, loc.lowStock, '${summary.lowStockItemsCount}', colorScheme.tertiary),
        _buildKPICard(context, loc.outOfStock, '${summary.outOfStockItemsCount}', colorScheme.error),
        _buildKPICard(context, loc.expired, '${summary.expiredOrNearExpiryCount}', colorScheme.onErrorContainer),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: AppTokens.cardElevation,
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppTokens.spacingXSmall),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMedium,
          vertical: AppTokens.spacingStandard),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: const Row(children: [
        Expanded(child: SkeletonLoader(height: AppTokens.kpiHeight))
      ]),
    );
  }

  Widget _buildFilterSection() {
    return BlocBuilder<StockFilterBloc, StockFilterState>(
      builder: (context, state) {
        return FilterPanelWidget(
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          selectedSupplierId: state.selectedSupplierId,
          selectedCategoryId: state.selectedCategoryId,
          availableSuppliers: state.availableSuppliers,
          availableCategories: state.availableCategories,
          onSearchChanged: (val) => context.read<StockFilterBloc>().add(SetSearchQuery(val)),
          onStatusFilterChanged: (status) => context.read<StockFilterBloc>().add(SetStatusFilter(status)),
          onSupplierFilterChanged: (id) => context.read<StockFilterBloc>().add(SetSupplierFilter(id)),
        );
      },
    );
  }

  Widget _buildMainContentArea(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _showSidePanel ? 6 : 10,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: BlocBuilder<StockOverviewBloc, StockOverviewState>(
                  builder: (context, state) {
                    if (state is StockOverviewLoading) return StockTableSkeletonWidget(colorScheme: colorScheme);
                    if (state is StockOverviewError) return Center(child: Text(state.message, style: TextStyle(color: colorScheme.error)));
                    if (state is StockOverviewLoaded) {
                      return StockTableWidget(
                        items: state.items,
                        hasReachedMax: state.hasReachedMax,
                        sortColumnIndex: _sortColumnIndex,
                        isAscending: _isAscending,
                        focusedIndex: _focusedIndex,
                        onAdjustStock: _openAdjustStockPanel,
                        onQuickPurchase: _showQuickPurchaseDialog,
                        onViewHistory: (title, item) => _openSidePanel(title, Center(child: Text(loc.noDataAvailable))),
                        onSort: (index, asc) => setState(() { _sortColumnIndex = index; _isAscending = asc; }),
                        onLoadMore: () => context.read<StockOverviewBloc>().add(LoadMoreStockOverview()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              Expanded(
                flex: 1,
                child: BlocBuilder<StockActivityBloc, StockActivityState>(
                  builder: (context, state) {
                    if (state is StockActivityLoading) return ActivityTableSkeletonWidget(colorScheme: colorScheme);
                    if (state is StockActivityLoaded) {
                      return RecentActivitiesTableWidget(
                        activities: state.activities,
                        hasReachedMax: state.hasReachedMax,
                        onActivityView: (title, activity) {
                          _openSidePanel(title, ActivityDetailPanelWidget(
                            activity: activity,
                            onCancel: () => _openCancelConfirmationPanel(activity),
                            pdfExportService: _pdfExportService,
                          ));
                        },
                        onLoadMore: () => context.read<StockActivityBloc>().add(LoadMoreStockActivities()),
                      );
                    }
                    // Handle action success/error by showing last known activities if needed or just letting it be
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showSidePanel) ...[
          const SizedBox(width: AppTokens.spacingMedium),
          Expanded(
            flex: 4,
            child: Card(
              elevation: AppTokens.cardElevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMedium, vertical: AppTokens.spacingStandard),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Expanded(child: Text(_sidePanelTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.close), onPressed: _closeSidePanel, iconSize: AppTokens.iconSizeMedium),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _sidePanelContent ?? Center(child: Text(loc.noDataAvailable))),
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
