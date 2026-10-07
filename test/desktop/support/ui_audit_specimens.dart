import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_event.dart';
import 'package:liaqat_store/core/utils/error_handler.dart';
import 'package:liaqat_store/core/res/app_tokens.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import '../../support/receipt_fixture.dart' as fixture;

// Exact production constructor specimens; dynamic inputs are labeled audit data.
List<(String, SnackBar)> feedbackSpecimens(BuildContext context,
    {bool isError = false}) {
  final loc = AppLocalizations.of(context)!;
  final localizations = loc;
  final colorScheme = Theme.of(context).colorScheme;
  final e = StateError('AUDIT_SAMPLE_ERROR');
  final error = e;
  final msg = loc.unknownError;
  final color = colorScheme.error;
  final successColor = colorScheme.primary;
  final errorColor = colorScheme.error;
  final successMsg = loc.invoiceCancelledSuccess;
  final errorMsg = loc.errorMessage(e.toString());
  final err = loc.unknownError;
  final message = loc.invoiceCancelledSuccess;
  final quickLocalizedName =
      loc.localeName == 'ur' ? 'ٹیسٹ گاہک' : 'Audit Customer';
  final localizedMessage = isError ? loc.unknownError : loc.preferencesSaved;
  final validationError = loc.invalidAmount;
  const path = r'C:\Audit\receipts\Invoice_AUDIT_001.pdf';
  final invoice = fixture.invoice();
  return [
    (
      'feedback-01',
      SnackBar(
        content: Text(ErrorHandler.getLocalizedMessage(
            error.toString(), AppLocalizations.of(context)!)),
        backgroundColor: Theme.of(context).colorScheme.error,
      )
    ),
    (
      'feedback-02',
      SnackBar(
          content: Text(loc.invalidAmount), backgroundColor: colorScheme.error)
    ),
    (
      'feedback-03',
      SnackBar(
          content: Text("Error saving: $e"), backgroundColor: colorScheme.error)
    ),
    (
      'feedback-04',
      SnackBar(
          content: Text(loc.descriptionRequired),
          backgroundColor: colorScheme.error)
    ),
    (
      'feedback-05',
      SnackBar(
          content: Text(loc.invalidAmount), backgroundColor: colorScheme.error)
    ),
    (
      'feedback-06',
      SnackBar(
          content: Text(loc.unknownError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-07',
      SnackBar(
          content: Text(loc.categoryExistsError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-08',
      SnackBar(
          content: Text(loc.unknownError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-09',
      SnackBar(
          content: Text(loc.departmentExistsError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-10',
      SnackBar(
          content: Text(loc.unknownError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-11',
      SnackBar(
          content: Text(loc.subcategoryExistsError),
          backgroundColor: Theme.of(context).colorScheme.error)
    ),
    (
      'feedback-12',
      SnackBar(
        content: Text(loc.itemDeleted),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-13',
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-14', SnackBar(content: Text(msg), backgroundColor: color)),
    (
      'feedback-15',
      SnackBar(
        content: Text(loc.invalidAmount),
        backgroundColor: colorScheme.error,
      )
    ),
    (
      'feedback-16',
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-17', SnackBar(content: Text(loc.savedToPath(path)))),
    (
      'feedback-18',
      SnackBar(
        content: Text(successMsg),
        backgroundColor: successColor,
      )
    ),
    (
      'feedback-19',
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: errorColor,
      )
    ),
    (
      'feedback-20',
      SnackBar(
          content: Text(localizations.fieldRequired(localizations.englishName)))
    ),
    (
      'feedback-21',
      SnackBar(
          content: Text(AppLocalizations.of(context)!.saveChangesSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary)
    ),
    (
      'feedback-22',
      SnackBar(
          content: Text(AppLocalizations.of(context)!.saveChangesSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary)
    ),
    (
      'feedback-23',
      SnackBar(
          content: Text(localizations.itemDeleted),
          backgroundColor: colorScheme.primary)
    ),
    (
      'feedback-24',
      SnackBar(
          content: Text('${localizations.error}: $e'),
          backgroundColor: colorScheme.error)
    ),
    (
      'feedback-25',
      SnackBar(
        content: Text(loc.purchaseSavedSuccess),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-26',
      SnackBar(
        content: Text(msg),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-27', SnackBar(content: Text(loc.nameRequired))),
    ('feedback-28', SnackBar(content: Text(loc.urduNameRequired))),
    ('feedback-29', SnackBar(content: Text(loc.phoneRequired))),
    ('feedback-30', SnackBar(content: Text(loc.addressRequired))),
    ('feedback-31', SnackBar(content: Text(loc.creditLimitRequired))),
    (
      'feedback-32',
      SnackBar(
          content: Text(loc.invalidAmount), backgroundColor: colorScheme.error)
    ),
    (
      'feedback-33',
      SnackBar(
        content: Text(loc.creditLimitUpdated),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-34',
      SnackBar(
        content: Text(loc.error),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-35', SnackBar(content: Text(loc.invalidLimit))),
    ('feedback-36', SnackBar(content: Text(loc.cannotPrintCancelled))),
    (
      'feedback-37',
      SnackBar(
          content:
              Text('${loc.receiptSentToPrinter} #${invoice.invoiceNumber}'))
    ),
    (
      'feedback-38',
      SnackBar(
          content: Text('${loc.printError}: $e'),
          backgroundColor: colorScheme.error)
    ),
    (
      'feedback-39',
      SnackBar(
        content: Text(loc.cannotSaveCancelledInvoiceAsPdf),
        backgroundColor: errorColor,
      )
    ),
    ('feedback-40', SnackBar(content: Text(loc.receiptSavedTo(path)))),
    (
      'feedback-41',
      SnackBar(content: Text(errorMsg), backgroundColor: errorColor)
    ),
    (
      'feedback-42',
      SnackBar(
        content: Text(AppLocalizations.of(context)!.editFeatureComingSoon),
        backgroundColor: colorScheme.primary,
      )
    ),
    ('feedback-43', SnackBar(content: Text(loc.cannotPrintCancelled))),
    (
      'feedback-44',
      SnackBar(
        content: Text(
          '${loc.receiptSentToPrinter} #${invoice.invoiceNumber}',
        ),
      )
    ),
    (
      'feedback-45',
      SnackBar(
        content: Text('${loc.printError}: $e'),
        backgroundColor: colorScheme.error,
      )
    ),
    (
      'feedback-46',
      SnackBar(
        content: Text("${loc.customerAdded}: '$quickLocalizedName'"),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-47',
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-48',
      SnackBar(
        content: Text(err),
        backgroundColor: colorScheme.error,
        action: SnackBarAction(
          label: loc.retry,
          textColor: colorScheme.onError,
          onPressed: () => context.read<SalesBloc>().add(SalesStarted()),
        ),
      )
    ),
    ('feedback-49', SnackBar(content: Text(loc.functionalityComingSoon))),
    (
      'feedback-50',
      SnackBar(
        content: Text(loc.pinChanged),
        backgroundColor: Theme.of(context).colorScheme.primary,
      )
    ),
    (
      'feedback-51',
      SnackBar(
        content: Text(localizedMessage),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      )
    ),
    (
      'feedback-52',
      SnackBar(
          content: Text(loc.unknownError), backgroundColor: colorScheme.error)
    ),
    (
      'feedback-53',
      SnackBar(
          content: Text(loc.saveChangesSuccess),
          backgroundColor: colorScheme.primary)
    ),
    (
      'feedback-54',
      SnackBar(
        content:
            Text(ErrorHandler.getLocalizedMessage('AUDIT_SAMPLE_MESSAGE', loc)),
        backgroundColor: colorScheme.primary,
      )
    ),
    (
      'feedback-55',
      SnackBar(
        content:
            Text(ErrorHandler.getLocalizedMessage('AUDIT_SAMPLE_MESSAGE', loc)),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-56', SnackBar(content: Text(loc.exportCsv))),
    ('feedback-57', SnackBar(content: Text(loc.exportPdf))),
    ('feedback-58', SnackBar(content: Text(loc.bulkAdjustStock))),
    ('feedback-59', SnackBar(content: Text(loc.bulkExportSelected))),
    ('feedback-60', SnackBar(content: Text(loc.saveAsPdf))),
    (
      'feedback-61',
      SnackBar(
          content: Text(loc.errorWithDetails(e.toString())),
          backgroundColor: colorScheme.error)
    ),
    (
      'feedback-62',
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-63', SnackBar(content: Text(msg), backgroundColor: color)),
    (
      'feedback-64',
      SnackBar(
        content: Text(loc.invalidAmount),
        backgroundColor: colorScheme.error,
      )
    ),
    (
      'feedback-65',
      SnackBar(
        content: Text('${loc.error}: $e'),
        backgroundColor: colorScheme.error,
      )
    ),
    ('feedback-66', SnackBar(content: Text(loc.savedToPath(path)))),
    (
      'feedback-67',
      SnackBar(
        content: Text(validationError),
        backgroundColor: Theme.of(context).colorScheme.error,
      )
    ),
    (
      'feedback-68',
      SnackBar(
        content: Text(validationError),
        backgroundColor: Theme.of(context).colorScheme.error,
      )
    ),
  ];
}

List<(String, Widget)> inlineDialogSpecimens(BuildContext context) {
  final ctx = context;
  final loc = AppLocalizations.of(context)!;
  final localizations = loc;
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  const code = 'AUDIT-XXXX-XXXX';
  return [
    (
      'inline-01',
      AlertDialog(
        title: Text(loc.recoveryCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.recoveryCodeInstructions),
            const SizedBox(height: AppTokens.spacingLarge),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingMedium,
                horizontal: AppTokens.spacingLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              ),
              child: const SelectableText(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(loc.copyCode),
              onPressed: () =>
                  Clipboard.setData(const ClipboardData(text: code)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.save),
          ),
        ],
      )
    ),
    (
      'inline-02',
      AlertDialog(
        title: Text(loc.confirmDeleteTitle),
        content: Text(loc.confirmDeleteMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(loc.no)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.yesDelete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onError)),
          ),
        ],
      )
    ),
    (
      'inline-03',
      Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius)),
        child: Container(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
          padding: const EdgeInsets.all(AppTokens.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(loc.confirmCancellationTitle, style: textTheme.titleLarge),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
              const Divider(),
              const SizedBox(height: AppTokens.spacingMedium),
              Text(loc.confirmCancelInvoiceMessage,
                  style: textTheme.bodyMedium),
              const SizedBox(height: AppTokens.spacingLarge),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(loc.no)),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: Text(loc.yesCancelButton),
                ),
              ]),
            ],
          ),
        ),
      )
    ),
    (
      'inline-04',
      AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(localizations.confirm),
        content: Text(localizations.confirmDeleteItem),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.no,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError),
            child: Text(localizations.yesDelete),
          ),
        ],
      )
    ),
    (
      'inline-05',
      AlertDialog(
        title: Text(loc.restoreBackup),
        content: Text(loc.restoreConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child:
                Text(loc.restore, style: const TextStyle(color: Colors.white)),
          ),
        ],
      )
    ),
    (
      'inline-06',
      AlertDialog(
        title: Text(loc.deleteBackup),
        content: Text(loc.deleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child:
                Text(loc.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      )
    ),
    (
      'inline-07',
      AlertDialog(
        title: Text(loc.recoveryCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.recoveryCodeInstructions),
            const SizedBox(height: AppTokens.spacingLarge),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingMedium,
                horizontal: AppTokens.spacingLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              ),
              child: const SelectableText(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(loc.copyCode),
              onPressed: () =>
                  Clipboard.setData(const ClipboardData(text: code)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.save),
          ),
        ],
      )
    ),
    (
      'inline-08',
      AlertDialog(
        title: Text('Confirm Delete',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(
            'Are you sure you want to completely delete this supplier?',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      )
    ),
  ];
}
