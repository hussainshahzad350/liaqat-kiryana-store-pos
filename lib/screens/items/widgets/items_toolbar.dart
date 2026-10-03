import 'package:flutter/material.dart';

import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class ItemsToolbar extends StatelessWidget {
  const ItemsToolbar({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onAddItem,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: textTheme.bodyLarge,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                labelText: localizations.searchItem,
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: IconButton(
                  icon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onSearch,
                ),
                border: _border(colorScheme.outline),
                enabledBorder: _border(colorScheme.outline),
                focusedBorder: _border(colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onClearSearch,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add, size: AppTokens.iconSizeLarge),
            label: Text(localizations.addItem),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(0, AppTokens.buttonHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              ),
              textStyle: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
      borderSide: BorderSide(color: color),
    );
  }
}
