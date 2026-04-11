import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/res/app_tokens.dart';

/// Shows a warning that the customer cannot be deleted (has balance),
/// and offers to archive instead.
class CannotDeleteDialog extends StatelessWidget {
  final VoidCallback onArchive;

  const CannotDeleteDialog({super.key, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        padding: const EdgeInsets.all(AppTokens.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.warning, style: textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppTokens.spacingMedium),
            Text(loc.cannotDeleteBal, style: textTheme.bodyMedium),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.ok),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onArchive();
                  },
                  child: Text(loc.archiveNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple yes/no confirmation dialog for delete.
class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        padding: const EdgeInsets.all(AppTokens.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.confirm, style: textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppTokens.spacingMedium),
            Text(loc.confirmDeleteItem, style: textTheme.bodyMedium),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(loc.no),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(loc.yesDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
