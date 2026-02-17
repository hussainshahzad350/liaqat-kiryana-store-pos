import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/invoice_model.dart';
import '../../../core/repositories/receipt_repository.dart';

/// Utility class for handling receipt printing operations
class ReceiptPrinter {
  final ReceiptRepository _receiptRepository;

  ReceiptPrinter({ReceiptRepository? receiptRepository})
      : _receiptRepository = receiptRepository ?? ReceiptRepository();

  /// Prints a receipt for the given invoice
  /// 
  /// Shows appropriate snackbar messages for success/error
  /// Returns true if printing was successful, false otherwise
  Future<bool> printReceipt(
    Invoice invoice,
    BuildContext context,
    VoidCallback onPrintTracked,
  ) async {
    if (!context.mounted) return false;

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if invoice is cancelled
    if (invoice.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cannotPrintCancelled)),
      );
      return false;
    }

    try {
      // Generate and print receipt
      final receiptData = await _receiptRepository.generateReceiptData(invoice);
      await _receiptRepository.printReceipt(receiptData);

      // Track the print
      final invoiceId = invoice.id;
      if (invoiceId != null) {
        await _receiptRepository.trackPrint(invoiceId);
      }

      // Notify caller to refresh data
      onPrintTracked();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.receiptSentToPrinter} #${invoice.invoiceNumber}',
            ),
          ),
        );
      }

      return true;
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.printError}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return false;
    }
  }
}
