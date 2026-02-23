import 'package:flutter/material.dart';
import '../../../core/constants/desktop_dimensions.dart';
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
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
      child: Container(
        constraints: RTLHelper.getDialogConstraints(
          context: context,
          size: DialogSize.small,
        ),
        padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
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
            const SizedBox(height: DesktopDimensions.spacingMedium),
            Text(loc.clearCartMsg,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
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
