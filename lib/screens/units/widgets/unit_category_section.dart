import 'package:flutter/material.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/unit_model.dart';
import 'unit_list_item.dart';

class UnitCategorySection extends StatelessWidget {
  final UnitCategory category;
  final List<Unit> units;
  final Unit? baseUnit;
  final Function(Unit) onEdit;
  final Function(Unit) onDelete;

  const UnitCategorySection({
    super.key,
    required this.category,
    required this.units,
    this.baseUnit,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'weight': return Icons.scale;
      case 'volume': return Icons.water_drop;
      case 'length': return Icons.straighten;
      case 'count': return Icons.numbers;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingMedium),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        key: PageStorageKey(category.id),
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(AppTokens.spacingSmall),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(_getCategoryIcon(category.name), color: colorScheme.primary, size: 20),
        ),
        title: Text(
          category.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: baseUnit != null
          ? Text(AppLocalizations.of(context)!.baseUnitSubtitle(baseUnit!.name, baseUnit!.code), style: textTheme.bodySmall)
          : Text(AppLocalizations.of(context)!.noBaseUnitSet, style: textTheme.bodySmall?.copyWith(color: colorScheme.error)),
        childrenPadding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSmall),
        children: units.isEmpty 
          ? [Padding(
              padding: const EdgeInsets.all(AppTokens.spacingLarge),
              child: Text(AppLocalizations.of(context)!.noUnitsInCategory, style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            )]
          : units.map((u) => UnitListItem(
              unit: u, 
              baseUnit: baseUnit,
              onEdit: () => onEdit(u),
              onDelete: () => onDelete(u),
            )).toList(),
      ),
    );
  }
}
