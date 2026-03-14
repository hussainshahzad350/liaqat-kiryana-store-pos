import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/entity/stock_activity_entity.dart';
import '../../../core/res/app_tokens.dart';

typedef OnActivityView = Function(String title, StockActivityEntity activity);

class RecentActivitiesTableWidget extends StatelessWidget {
  final List<StockActivityEntity> activities;
  final bool hasReachedMax;
  final OnActivityView onActivityView;
  final VoidCallback onLoadMore;

  const RecentActivitiesTableWidget({
    super.key,
    required this.activities,
    required this.hasReachedMax,
    required this.onActivityView,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              loc.recentActivities,
              style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: AppTokens.tableHeaderHeight,
                dataRowHeight: AppTokens.tableDataRowHeight,
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
                  final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(act.timestamp);

                  return DataRow(
                    cells: [
                      DataCell(Text(dateStr, style: textTheme.bodySmall)),
                      DataCell(Row(
                        children: [
                          Icon(Icons.circle,
                              size: AppTokens.iconSizeXXXSmall,
                              color: typeColor),
                          const SizedBox(width: AppTokens.spacingSmall),
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
                            horizontal: AppTokens.spacingSmall,
                            vertical: AppTokens.spacingXSmall),
                        decoration: BoxDecoration(
                          color: act.isCancelled
                              ? colorScheme.errorContainer.withValues(alpha: 0.5)
                              : colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(
                              AppTokens.extraSmallBorderRadius),
                        ),
                        child: Text(
                          act.status,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: act.isCancelled
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility,
                              size: AppTokens.iconSizeSmallMedium),
                          onPressed: () {
                            onActivityView(
                              '${loc.activityType}: ${act.referenceNumber}',
                              act,
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
              padding: const EdgeInsets.all(AppTokens.spacingSmall),
              child: TextButton(
                onPressed: onLoadMore,
                child: Text(loc.loadMore),
              ),
            ),
        ],
      ),
    );
  }
}
