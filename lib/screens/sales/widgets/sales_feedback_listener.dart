import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_state.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/invoice_model.dart';

/// Translates bloc results into localized presentation feedback.
class SalesFeedbackListener extends StatefulWidget {
  const SalesFeedbackListener(
      {super.key,
      required this.customerSearchController,
      required this.onCompleted,
      required this.child});
  final TextEditingController customerSearchController;
  final ValueChanged<Invoice> onCompleted;
  final Widget child;
  @override
  State<SalesFeedbackListener> createState() => _SalesFeedbackListenerState();
}

class _SalesFeedbackListenerState extends State<SalesFeedbackListener> {
  int? _lastHandledQuickCustomerId;
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state.selectedCustomer == null &&
              widget.customerSearchController.text.isNotEmpty) {
            widget.customerSearchController.clear();
          }

          final quickAdded = state.quickAddedCustomer;
          if (quickAdded != null &&
              quickAdded.id != _lastHandledQuickCustomerId) {
            _lastHandledQuickCustomerId = quickAdded.id;
            final quickLocalizedName = RTLHelper.getLocalizedName(
              context: context,
              nameEnglish: quickAdded.nameEnglish,
              nameUrdu: quickAdded.nameUrdu,
            );
            widget.customerSearchController.text =
                "$quickLocalizedName (${quickAdded.contactPrimary ?? ''})";
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${loc.customerAdded}: '$quickLocalizedName'"),
                  backgroundColor: colorScheme.primary,
                ),
              );
            }
          }

          if (state.status == SalesStatus.success) {
            if (state.completedInvoice != null) {
              widget.onCompleted(state.completedInvoice!);
            } else if (state.successMessage != null) {
              final success = state.successMessage!;
              final message = success == 'Receipt sent to printer'
                  ? loc.receiptSentToPrinter
                  : success == 'Credit limit updated'
                      ? loc.creditLimitUpdated
                      : success;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              }
            }
          } else if (state.status == SalesStatus.error) {
            // Only show error if there's an error message
            // Some errors are transient and immediately reset (like stock validation)
            if (state.errorMessage != null && context.mounted) {
              final err =
                  ErrorHandler.getLocalizedMessage(state.errorMessage, loc);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err),
                  backgroundColor: colorScheme.error,
                  action: SnackBarAction(
                    label: loc.retry,
                    textColor: colorScheme.onError,
                    onPressed: () =>
                        context.read<SalesBloc>().add(SalesStarted()),
                  ),
                ),
              );
              context.read<SalesBloc>().add(ClearSalesError());
            }
          }
        },
        child: widget.child);
  }
}
