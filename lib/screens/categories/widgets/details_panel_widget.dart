import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';

class DetailsPanelWidget extends StatelessWidget {
  final int selectionLevel;
  final Department? selectedDepartment;
  final Category? selectedCategory;
  final SubCategory? selectedSubCategory;
  final int detailsItemCount;
  final int detailsSubCount;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DetailsPanelWidget({
    super.key,
    required this.selectionLevel,
    this.selectedDepartment,
    this.selectedCategory,
    this.selectedSubCategory,
    required this.detailsItemCount,
    required this.detailsSubCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectionLevel == 0) {
      return Center(
          child: Text(loc.selectItemToManageInstruction,
              style: TextStyle(color: colorScheme.outline)));
    }

    String title = '';
    String subtitle = '';
    String? urduTitle;
    IconData icon = Icons.info_outline;

    final hasSelectionMismatch =
        (selectionLevel == 1 && selectedDepartment == null) ||
            (selectionLevel == 2 && selectedCategory == null) ||
            (selectionLevel == 3 && selectedSubCategory == null);

    assert(() {
      if (hasSelectionMismatch) {
        debugPrint(
            'DetailsPanelWidget state mismatch: selectionLevel=$selectionLevel, '
            'selectedDepartment=${selectedDepartment?.id}, '
            'selectedCategory=${selectedCategory?.id}, '
            'selectedSubCategory=${selectedSubCategory?.id}');
      }
      return true;
    }());

    if (selectionLevel == 1 && selectedDepartment != null) {
      title = selectedDepartment!.nameEn;
      urduTitle = selectedDepartment!.nameUr;
      subtitle = loc.departmentLabel;
      icon = Icons.business;
    } else if (selectionLevel == 1) {
      title = loc.selectDepartmentInstruction;
      subtitle = loc.selectItemToManageInstruction;
      urduTitle = null;
      icon = Icons.business;
    } else if (selectionLevel == 2 && selectedCategory != null) {
      title = selectedCategory!.nameEn;
      urduTitle = selectedCategory!.nameUr;
      subtitle = loc.category;
      icon = Icons.folder_open;
    } else if (selectionLevel == 2) {
      title = loc.selectItemToManageInstruction;
      subtitle = loc.category;
      urduTitle = null;
      icon = Icons.folder_open;
    } else if (selectionLevel == 3 && selectedSubCategory != null) {
      title = selectedSubCategory!.nameEn;
      urduTitle = selectedSubCategory!.nameUr;
      subtitle = loc.subCategory;
      icon = Icons.account_tree_outlined;
    } else if (selectionLevel == 3) {
      title = loc.selectItemToManageInstruction;
      subtitle = loc.subCategory;
      urduTitle = null;
      icon = Icons.account_tree_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.spacingStandard),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Text(
            loc.detailsHeader,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(icon, size: 40, color: colorScheme.primary),
                ),
                const SizedBox(height: AppTokens.spacingLarge),
                Text(title,
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                if (urduTitle != null && urduTitle.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.spacingSmall),
                  Text(urduTitle,
                      style: const TextStyle(
                          fontFamily: 'NooriNastaleeq',
                          fontSize: 20,
                          height: 1.2),
                      textAlign: TextAlign.center),
                ],
                Text(subtitle,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.outline)),
                const SizedBox(height: AppTokens.spacingXLarge),
                if (selectionLevel < 3) ...[
                  _buildStatRow(
                      context,
                      Icons.grid_view,
                      selectionLevel == 1
                          ? loc.categoriesSubcategoriesHeader
                          : loc.subcategories,
                      detailsSubCount.toString()),
                  const SizedBox(height: AppTokens.spacingMedium),
                  _buildStatRow(context, Icons.inventory_2_outlined,
                      loc.totalItems, detailsItemCount.toString()),
                  const SizedBox(height: AppTokens.spacingXLarge),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(loc.editAction),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTokens.spacingMedium),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(loc.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTokens.spacingMedium),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTokens.radius8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppTokens.spacingMedium),
          Expanded(
              child:
                  Text(label, style: textTheme.bodyLarge ?? const TextStyle())),
          Text(value,
              style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.primary)),
        ],
      ),
    );
  }
}
