import 'package:flutter/material.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../l10n/app_localizations.dart';

// This dialog just returns true/false or the reason string.
// Or it can return logic.
// In sales_screen.dart, _cancelSale returns Future<void> and calls BLoC.
// Here we can return the reason if confirmed, or null if cancelled.

class CancelSaleDialog extends StatefulWidget {
  const CancelSaleDialog({super.key});

  @override
  State<CancelSaleDialog> createState() => _CancelSaleDialogState();
}

class _CancelSaleDialogState extends State<CancelSaleDialog> {
  final reasonCtrl = TextEditingController();

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minWidth: DesktopDimensions.dialogWidth * 1.5,
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.cancelSaleTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesktopDimensions.spacingMedium),
            Text(loc.cancelSaleMessage,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: DesktopDimensions.spacingMedium),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: loc.cancelReasonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
                  child: Text(loc.cancelSale),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
