import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';

class ClearCartDialog extends StatelessWidget {
  final VoidCallback onClear;

  const ClearCartDialog({
    super.key,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppTokens.dialogBorderRadius)),
      child: Container(
        constraints: RTLHelper.getDialogConstraints(
          context: context,
          size: DialogSize.small,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.dialogPadding,
          vertical: RTLHelper.isRTL(context) 
              ? AppTokens.dialogPadding + 12
              : AppTokens.dialogPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.clearCartTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.clearCartMsg,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError),
                  onPressed: () {
                    Navigator.pop(context);
                    onClear();
                  },
                  child: Text(loc.clearAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
