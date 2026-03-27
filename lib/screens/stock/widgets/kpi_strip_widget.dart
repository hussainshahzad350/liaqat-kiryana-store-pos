import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/res/app_tokens.dart';
import '../../../bloc/stock/stock_overview/stock_overview_bloc.dart';
import '../../../bloc/stock/stock_overview/stock_overview_state.dart';
import '../../../bloc/stock/stock_filter/stock_filter_bloc.dart';
import '../../../bloc/stock/stock_filter/stock_filter_state.dart';
import '../../../bloc/stock/stock_filter/stock_filter_event.dart';
import '../../../widgets/skeleton_loader.dart';

class KpiStripWidget extends StatelessWidget {
  const KpiStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<StockFilterBloc, StockFilterState>(
      builder: (context, filterState) {
        return BlocBuilder<StockOverviewBloc, StockOverviewState>(
          builder: (context, overviewState) {
            if (overviewState is StockOverviewLoading) {
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

            if (overviewState is StockOverviewLoaded) {
              final summary = overviewState.summary;
              final currentFilter = filterState.statusFilter;

              return Row(
                children: [
                  _KpiCard(
                    label: loc.lowStock,
                    value: '${summary.lowStockItemsCount}',
                    statusFilter: 'LOW',
                    accentColor: colorScheme.tertiary,
                    isActive: currentFilter == 'LOW',
                  ),
                  _KpiCard(
                    label: loc.outOfStock,
                    value: '${summary.outOfStockItemsCount}',
                    statusFilter: 'OUT',
                    accentColor: colorScheme.error,
                    isActive: currentFilter == 'OUT',
                  ),
                  _KpiCard(
                    label: loc.expiringSoon30Days,
                    value: '${summary.expiringSoonCount}',
                    statusFilter: 'SOON',
                    accentColor: colorScheme.secondary,
                    isActive: currentFilter == 'SOON',
                  ),
                  _KpiCard(
                    label: loc.expired,
                    value: '${summary.expiredOrNearExpiryCount}',
                    statusFilter: 'EXPIRED',
                    accentColor: colorScheme.errorContainer,
                    isActive: currentFilter == 'EXPIRED',
                  ),
                  _KpiCard(
                    label: loc.deadStock90Days,
                    value: '${summary.deadStockCount}',
                    statusFilter: 'DEAD',
                    accentColor: colorScheme.onSurfaceVariant,
                    isActive: currentFilter == 'DEAD',
                  ),
                  _KpiCard(
                    label: loc.totalCostValue,
                    value: summary.totalStockCost.formattedNoDecimal,
                    statusFilter: null,
                    accentColor: colorScheme.secondary,
                    isActive: false,
                  ),
                  _KpiCard(
                    label: loc.totalItems,
                    value: '${summary.totalItemsCount}',
                    statusFilter: null,
                    accentColor: colorScheme.primary,
                    isActive: false,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? statusFilter;
  final Color accentColor;
  final bool isActive;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.statusFilter,
    required this.accentColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Expanded(
      child: Card(
        elevation: AppTokens.cardElevation,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingXSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
          side: isActive
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : null,
        child: InkWell(
          onTap: statusFilter != null
              ? () {
                  context.read<StockFilterBloc>().add(SetStatusFilter(statusFilter!));
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: accentColor,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.spacingXSmall),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
