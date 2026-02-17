import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/invoice_model.dart';
import '../../../core/repositories/receipt_repository.dart';

class PostSaleDialog extends StatefulWidget {
  final Invoice invoice;

  const PostSaleDialog({
    super.key,
    required this.invoice,
  });

  @override
  State<PostSaleDialog> createState() => _PostSaleDialogState();
}

class _PostSaleDialogState extends State<PostSaleDialog> {
  final ReceiptRepository _receiptRepository = ReceiptRepository();

  Future<void> _handlePrintReceipt(Invoice invoice) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (invoice.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cannotPrintCancelled)),
      );
      return;
    }

    try {
      final receiptData = await _receiptRepository.generateReceiptData(invoice);
      await _receiptRepository.printReceipt(receiptData);
      final invoiceId = invoice.id;
      if (invoiceId != null) {
        await _receiptRepository.trackPrint(invoiceId);
      }
      // _loadRecentInvoices(); // Handled by SalesScreen or BLoC refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${loc.receiptSentToPrinter} #${invoice.invoiceNumber}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.printError}: $e'),
              backgroundColor: colorScheme.error),
        );
      }
    }
    if (mounted) {
      context.read<SalesBloc>().add(ReceiptPrintRequested(invoice));
    }
  }

  void _performClearCart() {
    // This dialog is shown after success, so we might want to clear cart if not already cleared?
    // In SalesScreen, _showPostSaleDialog is called after SalesStatus.success.
    // Usually BLoC might have already cleared cart or we trigger it here for new sale.
    context.read<SalesBloc>().add(CartCleared());
  }

  void _refreshAllData() {
    context.read<SalesBloc>().add(SalesStarted());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: DesktopDimensions.dialogWidth),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  color: colorScheme.primary,
                  size: DesktopDimensions.aboutIconSize),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Text(loc.saleCompleted, style: textTheme.titleLarge),
              Text('${loc.bill} #${widget.invoice.invoiceNumber}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: DesktopDimensions.spacingXLarge),
              SizedBox(
                width: double.infinity,
                height: DesktopDimensions.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => _handlePrintReceipt(widget.invoice),
                  icon: const Icon(Icons.print),
                  label: Text(loc.printReceipt),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              SizedBox(
                width: double.infinity,
                height: DesktopDimensions.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Capture theme values before async call
                    final errorColor = colorScheme.error;

                    if (widget.invoice.status == 'CANCELLED') {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Cannot save cancelled invoice as PDF'),
                            backgroundColor: errorColor,
                          ),
                        );
                      }
                      return;
                    }

                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      final path = await _receiptRepository
                          .saveReceiptAsPDF(widget.invoice);
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Receipt saved to: $path')),
                        );
                      }
                    } catch (e) {
                      final errorMsg = 'Error saving PDF: $e';
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: errorColor),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(loc.saveAsPdf),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingLarge),
              SizedBox(
                width: double.infinity,
                height: DesktopDimensions.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _performClearCart();
                    _refreshAllData();
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(loc.startNewSale.toUpperCase()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    textStyle: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
