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
import '../../bloc/stock/stock_ui/stock_ui_cubit.dart';
import '../../core/entity/stock_item_entity.dart';
import '../../core/entity/stock_activity_entity.dart';
import '../../services/pdf_export_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/res/app_tokens.dart';
import 'dialogs/adjust_stock_dialog.dart';
import 'dialogs/cancel_activity_dialog.dart';
import 'widgets/stock_table_widget.dart';
import 'widgets/activity_detail_panel_widget.dart';
import 'widgets/recent_activities_table_widget.dart';
import 'widgets/filter_panel_widget.dart';
import 'widgets/stock_table_skeleton_widget.dart';
import 'widgets/activity_table_skeleton_widget.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/app_shell.dart';
import 'widgets/kpi_strip_widget.dart';
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

  // Removed local fields — owned by StockUiCubit

  final PdfExportService _pdfExportService = PdfExportService();
  Timer? _searchDebounce;
  Widget? _sidePanelContent; // content stays local — Widget cannot live in BLoC

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

  void _navigateToPurchase(BuildContext context, StockItemEntity item) {
    AppShell.navigateTo(context, AppRoutes.purchase);
  }

  void _openCancelConfirmationPanel(StockActivityEntity activity) {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => CancelActivityDialog(
        onConfirm: () {
          if (!context.mounted) return;
          context.read<StockActivityBloc>().add(
                CancelStockActivity(
                  activity: activity,
                  reason: loc.cancel,
                ),
              );
        },
      ),
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
            context.read<StockActivityBloc>().add(const LoadStockActivities());
          },
          onSearch: () {
            // Search focus handling would require a way to reach FilterPanelWidget's focus node
            // For now we keep it simple or implement a focus manager
          },
          onClosePanel: () => context.read<StockUiCubit>().closeSidePanel(),
          onMoveUp: () => context.read<StockUiCubit>().moveFocusUp(),
          onMoveDown: () {
            final overviewState = context.read<StockOverviewBloc>().state;
            if (overviewState is StockOverviewLoaded) {
              context
                  .read<StockUiCubit>()
                  .moveFocusDown(overviewState.items.length);
            }
          },
          onActivate: () {
            final overviewState = context.read<StockOverviewBloc>().state;
            final uiState = context.read<StockUiCubit>().state;
            if (overviewState is StockOverviewLoaded &&
                uiState.focusedIndex < overviewState.items.length) {
              _openAdjustStockPanel(overviewState.items[uiState.focusedIndex]);
            }
          },
          onNewPurchase: () => AppShell.navigateTo(context, AppRoutes.purchase),
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
                if (!context.mounted) return;
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
          child: Focus(
            autofocus: true,
            child: BlocBuilder<StockActivityBloc, StockActivityState>(
              builder: (context, activityState) {
                final isProcessing = activityState is StockActivityProcessing;
                return Stack(
                  children: [
                    Column(
                      children: [
                        _buildToolbar(context, loc, colorScheme),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppTokens.spacingLarge),
                            child: Column(
                              children: [
                                const KpiStripWidget(),
                                const SizedBox(height: AppTokens.spacingLarge),
                                _buildFilterSection(),
                                const SizedBox(height: AppTokens.spacingLarge),
                                Expanded(
                                    child: _buildMainContentArea(
                                        context, loc, colorScheme)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isProcessing) const LoadingOverlay(),
                  ],
                );
              },
            ),
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
            onPressed: () => AppShell.navigateTo(context, AppRoutes.purchase),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(loc.newPurchase, style: textTheme.labelLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: AppTokens.spacingSmall),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.exportCsv)),
            ),
            child: Text(loc.exportCsv),
          ),
          const SizedBox(width: AppTokens.spacingXSmall),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.exportPdf)),
            ),
            child: Text(loc.exportPdf),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
        ],
      ),
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
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (layoutContext, constraints) {
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
                      builder: (overviewContext, state) {
                        if (state is StockOverviewLoading) {
                          return StockTableSkeletonWidget(
                              colorScheme: colorScheme);
                        }
                        if (state is StockOverviewError) {
                          return Center(
                            child: Text(
                              ErrorHandler.getLocalizedMessage(
                                  state.message, loc),
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.error),
                            ),
                          );
                        }
                        if (state is StockOverviewLoaded) {
                          return BlocBuilder<StockUiCubit, StockUiState>(
                            builder: (uiContext, uiState) => StockTableWidget(
                              items: state.items,
                              hasReachedMax: state.hasReachedMax,
                              sortColumnIndex: uiState.sortColumnIndex,
                              isAscending: uiState.isAscending,
                              focusedIndex: uiState.focusedIndex,
                              onAdjustStock: _openAdjustStockPanel,
                              onQuickPurchase: _navigateToPurchase,
                              onViewHistory: (title, item) {
                                _sidePanelContent =
                                    Center(child: Text(loc.noDataAvailable));
                                uiContext
                                    .read<StockUiCubit>()
                                    .openSidePanel(title);
                              },
                              onSort: (index, asc) => uiContext
                                  .read<StockUiCubit>()
                                  .setSort(index, asc),
                              onLoadMore: () => uiContext
                                  .read<StockOverviewBloc>()
                                  .add(LoadMoreStockOverview()),
                              selectedIds: uiState.selectedIds,
                              onToggleSelection: (id) => uiContext
                                  .read<StockUiCubit>()
                                  .toggleSelection(id),
                              onSelectAll: () => uiContext
                                  .read<StockUiCubit>()
                                  .selectAll(
                                      state.items.map((i) => i.id).toList()),
                              onClearSelection: () => uiContext
                                  .read<StockUiCubit>()
                                  .clearSelection(),
                              onBulkAdjustStock: uiState.selectedIds.isEmpty
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(loc.bulkAdjustStock)),
                                      );
                                    },
                              onBulkExportSelected: uiState.selectedIds.isEmpty
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(loc.bulkExportSelected)),
                                      );
                                    },
                              onBulkOrderSelected: uiState.selectedIds.isEmpty
                                  ? null
                                  : () => AppShell.navigateTo(
                                      context, AppRoutes.purchase),
                            ),
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
                      buildWhen: (previous, current) =>
                          current is StockActivityLoading ||
                          current is StockActivityLoaded ||
                          current is StockActivityError,
                      builder: (activityContext, state) {
                        if (state is StockActivityLoading) {
                          return ActivityTableSkeletonWidget(
                              colorScheme: colorScheme);
                        }
                        if (state is StockActivityLoaded) {
                          return RecentActivitiesTableWidget(
                            activities: state.activities,
                            hasReachedMax: state.hasReachedMax,
                            onActivityView: (title, activity) {
                              _sidePanelContent = ActivityDetailPanelWidget(
                                activity: activity,
                                onCancel: () =>
                                    _openCancelConfirmationPanel(activity),
                                pdfExportService: _pdfExportService,
                              );
                              activityContext
                                  .read<StockUiCubit>()
                                  .openSidePanel(title);
                            },
                            onLoadMore: () => activityContext
                                .read<StockActivityBloc>()
                                .add(const LoadMoreStockActivities()),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<StockUiCubit, StockUiState>(
              builder: (uiContext, uiState) {
                if (!uiState.showSidePanel) return const SizedBox.shrink();
                return Row(
                  children: [
                    const SizedBox(width: AppTokens.spacingMedium),
                    SizedBox(
                      width: sidePanelWidth,
                      child: Card(
                        elevation: AppTokens.cardElevation,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTokens.cardBorderRadius)),
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
                                        uiState.sidePanelTitle,
                                        style: Theme.of(uiContext)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => uiContext
                                          .read<StockUiCubit>()
                                          .closeSidePanel(),
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
                );
              },
            ),
          ],
        );
      },
    );
  }
}
