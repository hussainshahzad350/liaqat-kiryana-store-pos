import 'package:flutter/material.dart';

import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Presentation-only actions displayed above the sales workspace.
class SalesActionsToolbar extends StatelessWidget {
  const SalesActionsToolbar({
    super.key,
    required this.onRefresh,
    required this.onClearCart,
  });

  final VoidCallback onRefresh;
  final VoidCallback onClearCart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              size: AppTokens.kpiIconSize,
            ),
            color: colorScheme.primary,
            onPressed: onRefresh,
            tooltip: loc.refresh,
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep,
              size: AppTokens.kpiIconSize,
            ),
            color: colorScheme.error,
            onPressed: onClearCart,
            tooltip: loc.clearCartTitle,
          ),
        ],
      ),
    );
  }
}
