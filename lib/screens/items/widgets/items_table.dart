import 'package:flutter/material.dart';

import '../../../core/res/app_tokens.dart';
import '../../../widgets/app_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/product_model.dart';

class ItemsTable extends StatelessWidget {
  const ItemsTable({
    super.key,
    required this.items,
    required this.categoryNames,
    required this.subCategoryNames,
    required this.scrollController,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.onEditItem,
    required this.onDeleteItem,
    this.errorMessage,
    this.onRetry,
  });

  final List<Product> items;
  final Map<int, String> categoryNames;
  final Map<int, String> subCategoryNames;
  final ScrollController scrollController;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final ValueChanged<Product> onEditItem;
  final ValueChanged<int> onDeleteItem;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isInitialLoading) {
      return AppStateView.loading(message: localizations.loading);
    }
    if (items.isEmpty && errorMessage != null) {
      return AppStateView.error(
          message: errorMessage!,
          actionLabel: localizations.retry,
          onRetry: onRetry);
    }
    if (items.isEmpty) {
      return AppStateView.empty(message: localizations.noItemsFound);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null)
              MaterialBanner(content: Text(errorMessage!), actions: [
                TextButton(onPressed: onRetry, child: Text(localizations.retry))
              ]),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight:
                      Directionality.of(context) == TextDirection.rtl
                          ? 64
                          : AppTokens.controlMinHeight,
                  dataRowMinHeight: AppTokens.controlMinHeight,
                  dataRowMaxHeight: double.infinity,
                  columnSpacing: AppTokens.spacingMedium,
                  horizontalMargin: AppTokens.spacingMedium,
                  headingRowColor:
                      WidgetStateProperty.all(colorScheme.primaryContainer),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.hovered)
                        ? colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.2)
                        : null,
                  ),
                  columns: [
                    _column(localizations.englishName, textTheme, colorScheme),
                    _column(localizations.urduName, textTheme, colorScheme),
                    _column(localizations.category, textTheme, colorScheme),
                    _column(localizations.subCategory, textTheme, colorScheme),
                    _column(localizations.brand, textTheme, colorScheme),
                    _column(localizations.unit, textTheme, colorScheme),
                    _column(localizations.packingType, textTheme, colorScheme),
                    _column(localizations.actions, textTheme, colorScheme),
                  ],
                  rows: items.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          item.nameEnglish,
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Text(
                          item.nameUrdu ?? '-',
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'NooriNastaleeq',
                          ),
                        )),
                        DataCell(Text(
                          categoryNames[item.categoryId] ?? '-',
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Text(
                          subCategoryNames[item.subCategoryId] ?? '-',
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Text(
                          item.brand ?? '-',
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Text(
                          item.unitType ?? '-',
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Text(
                          item.packingType ?? '-',
                          style: textTheme.bodyMedium,
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: colorScheme.secondary,
                                size: AppTokens.iconSizeMedium,
                              ),
                              onPressed: () => onEditItem(item),
                              tooltip: localizations.editItem,
                            ),
                            const SizedBox(width: AppTokens.spacingSmall),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                                size: AppTokens.iconSizeMedium,
                              ),
                              onPressed: () => onDeleteItem(item.id!),
                              tooltip: localizations.deleteItem,
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(AppTokens.spacingMedium),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!hasNextPage)
              Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMedium),
                child: Center(
                  child: Text(
                    localizations.endOfList,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataColumn _column(
    String label,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return DataColumn(
      label: Text(
        label,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
