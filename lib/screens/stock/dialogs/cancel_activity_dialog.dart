import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/res/app_tokens.dart';

class CancelActivityDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelActivityDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 380, maxWidth: 480),
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.confirmation, style: textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: AppTokens.spacingLarge),
            Text(loc.confirmCancelInvoiceMessage, style: textTheme.bodyLarge),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.no),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Text(loc.yes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
