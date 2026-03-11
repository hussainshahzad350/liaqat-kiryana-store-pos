import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/res/app_tokens.dart';
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
    if (invoice.isCancelled) {
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
                BorderRadius.circular(AppTokens.dialogBorderRadius)),
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: AppTokens.dialogWidth),
          padding: const EdgeInsets.all(AppTokens.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  color: colorScheme.primary,
                  size: AppTokens.aboutIconSize),
              const SizedBox(height: AppTokens.spacingMedium),
              Text(loc.saleCompleted, style: textTheme.titleLarge),
              Text('${loc.bill} #${widget.invoice.invoiceNumber}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppTokens.spacingXLarge),
              // Print Receipt button
              SizedBox(
                width: double.infinity,
                height: AppTokens.buttonHeight * 1.3,
                child: OutlinedButton.icon(
                  onPressed: () => _handlePrintReceipt(widget.invoice),
                  icon: const Icon(Icons.print),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.printReceipt),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingStandard),
              // Save as PDF button
              SizedBox(
                width: double.infinity,
                height: AppTokens.buttonHeight * 1.3,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final errorColor = colorScheme.error;

                    if (widget.invoice.isCancelled) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Cannot save cancelled invoice as PDF'),
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
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.saveAsPdf),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              // Start New Sale button — FittedBox prevents Urdu text from being clipped
              SizedBox(
                width: double.infinity,
                height: AppTokens.buttonHeight * 1.5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _performClearCart();
                    _refreshAllData();
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.startNewSale),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(180, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
