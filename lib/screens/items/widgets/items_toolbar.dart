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
          ),
        ],
      ),
    );
  }
}
