import 'package:flutter/material.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/unit_model.dart';
import 'base_unit_indicator.dart';
import '../utils/unit_converter.dart';

class UnitListItem extends StatelessWidget {
  final Unit unit;
  final Unit? baseUnit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UnitListItem({
    super.key,
    required this.unit,
    this.baseUnit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: unit.isSystem ? null : onEdit,
      hoverColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Container(
        height: AppTokens.buttonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingLarge,
          vertical: AppTokens.spacingSmall,
        ),
        child: Row(
          children: [
            // Icon / Indicator
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: AppTokens.spacingStandard),
              decoration: BoxDecoration(
                color: unit.isSystem
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius:
                    BorderRadius.circular(AppTokens.borderRadiusSmall),
              ),
              child: Icon(
                unit.isSystem ? Icons.lock : Icons.balance,
                size: 16,
                color: unit.isSystem
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimaryContainer,
              ),
            ),

            // Name and Tags
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  if (unit.isBase)
                    const BaseUnitIndicator()
                  else if (baseUnit != null)
                    Flexible(
                      child: Text(
                        '(${UnitConverter.getFormula(unit, baseUnit)})',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),

            // Code
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMedium,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius:
                      BorderRadius.circular(AppTokens.borderRadiusSmall),
                ),
                child: Text(
                  unit.code,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: unit.isSystem ? null : onEdit,
                  tooltip: unit.isSystem ? loc.systemUnit : loc.edit,
                  color: unit.isSystem
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: unit.isSystem ? null : onDelete,
                  tooltip: unit.isSystem ? loc.systemUnit : loc.delete,
                  color: unit.isSystem
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
