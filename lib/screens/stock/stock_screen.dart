import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/error_handler.dart';
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
  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  int _sortColumnIndex = 0;
  bool _isAscending = true;
  int _focusedIndex = 0;

  final PdfExportService _pdfExportService = PdfExportService();
  Timer? _searchDebounce;

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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AdjustStockDialog(
        item: item,
        onSave: (adjustment, reason) {
          Navigator.of(dialogContext).pop();
          if (!context.mounted) return;
          context.read<StockActivityBloc>().add(AdjustStock(
                productId: item.id,
                quantityChange: adjustment,
                reason: reason,
                reference: AppLocalizations.of(context)!.adjustStock,
              ));
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _showQuickPurchaseDialog(BuildContext context, StockItemEntity item) {
    Navigator.pushNamed(context, AppRoutes.purchase);
  }

  void _openCancelConfirmationPanel(StockActivityEntity activity) {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 380, maxWidth: 480),
            padding: const EdgeInsets.all(AppTokens.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.confirmation, style: textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: AppTokens.spacingLarge),
                Text(loc.confirmCancelInvoiceMessage,
                    style: textTheme.bodyLarge),
                const SizedBox(height: AppTokens.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(loc.no),
                    ),
                    const SizedBox(width: AppTokens.spacingMedium),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<StockActivityBloc>().add(
                              CancelStockActivity(
                                activity: activity,
                                reason: loc.cancel,
                              ),
                            );
                      },
                      child: Text(loc.yes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: StockShortcuts.shortcuts,
      child: Actions(
        actions: StockShortcuts.createActions(
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
                    SnackBar(
                      content: Text(
                          ErrorHandler.getLocalizedMessage(state.message, loc)),
                      backgroundColor: colorScheme.primary,
                    ),
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
                      content: Text(
                          ErrorHandler.getLocalizedMessage(state.message, loc)),
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

  Widget _buildToolbar(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMedium,
          vertical: AppTokens.spacingSmall),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.purchase),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(loc.newPurchase, style: textTheme.labelLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
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
        _buildKPICard(context, loc.totalItems, '${summary.totalItemsCount}',
            colorScheme.primary),
        _buildKPICard(
            context,
            loc.stockValue,
            summary.totalStockSalesValue.formattedNoDecimal,
            colorScheme.secondary),
        _buildKPICard(
            context,
            loc.totalCost,
            summary.totalStockCost.formattedNoDecimal,
            colorScheme.onSurfaceVariant),
        _buildKPICard(context, loc.lowStock, '${summary.lowStockItemsCount}',
            colorScheme.tertiary),
        _buildKPICard(context, loc.outOfStock,
            '${summary.outOfStockItemsCount}', colorScheme.error),
        _buildKPICard(
            context,
            loc.expired,
            '${summary.expiredOrNearExpiryCount}',
            colorScheme.onErrorContainer),
      ],
    );
  }

  Widget _buildKPICard(
      BuildContext context, String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        elevation: AppTokens.cardElevation,
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSmall),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppTokens.spacingXSmall),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
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
          vertical: AppTokens.spacingSmall),
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
          onSearchChanged: (val) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 300), () {
              context.read<StockFilterBloc>().add(SetSearchQuery(val));
            });
          },
          onStatusFilterChanged: (status) =>
              context.read<StockFilterBloc>().add(SetStatusFilter(status)),
          onSupplierFilterChanged: (id) =>
              context.read<StockFilterBloc>().add(SetSupplierFilter(id)),
          onCategoryFilterChanged: (id) =>
              context.read<StockFilterBloc>().add(SetCategoryFilter(id)),
        );
      },
    );
  }

  Widget _buildMainContentArea(
      BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double sidePanelWidth = 420;
        if (constraints.maxWidth >= 2560) {
          sidePanelWidth = 560;
        } else if (constraints.maxWidth >= 1920) {
          sidePanelWidth = 480;
        } else if (constraints.maxWidth >= 1366) {
          sidePanelWidth = 420;
        } else {
          sidePanelWidth = 360;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<StockOverviewBloc, StockOverviewState>(
                      builder: (context, state) {
                        if (state is StockOverviewLoading) {
                          return StockTableSkeletonWidget(
                              colorScheme: colorScheme);
                        }
                        if (state is StockOverviewError) {
                          return Center(
                              child: Text(state.message,
                                  style: TextStyle(color: colorScheme.error)));
                        }
                        if (state is StockOverviewLoaded) {
                          return StockTableWidget(
                            items: state.items,
                            hasReachedMax: state.hasReachedMax,
                            sortColumnIndex: _sortColumnIndex,
                            isAscending: _isAscending,
                            focusedIndex: _focusedIndex,
                            onAdjustStock: _openAdjustStockPanel,
                            onQuickPurchase: _showQuickPurchaseDialog,
                            onViewHistory: (title, item) => _openSidePanel(
                                title,
                                Center(child: Text(loc.noDataAvailable))),
                            onSort: (index, asc) => setState(() {
                              _sortColumnIndex = index;
                              _isAscending = asc;
                            }),
                            onLoadMore: () => context
                                .read<StockOverviewBloc>()
                                .add(LoadMoreStockOverview()),
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
                        if (state is StockActivityLoading) {
                          return ActivityTableSkeletonWidget(
                              colorScheme: colorScheme);
                        }
                        if (state is StockActivityLoaded) {
                          return RecentActivitiesTableWidget(
                            activities: state.activities,
                            hasReachedMax: state.hasReachedMax,
                            onActivityView: (title, activity) {
                              _openSidePanel(
                                  title,
                                  ActivityDetailPanelWidget(
                                    activity: activity,
                                    onCancel: () =>
                                        _openCancelConfirmationPanel(activity),
                                    pdfExportService: _pdfExportService,
                                  ));
                            },
                            onLoadMore: () => context
                                .read<StockActivityBloc>()
                                .add(LoadMoreStockActivities()),
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
              SizedBox(
                width: sidePanelWidth,
                child: Card(
                  elevation: AppTokens.cardElevation,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.cardBorderRadius)),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardBorderRadius),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spacingMedium,
                              vertical: AppTokens
                                  .spacingSmall), // ✅ compact desktop header
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _sidePanelTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _closeSidePanel,
                                iconSize: AppTokens.iconSizeMedium,
                                tooltip: loc.close, // ✅ localized tooltip
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                            child: _sidePanelContent ??
                                Center(child: Text(loc.noDataAvailable))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
