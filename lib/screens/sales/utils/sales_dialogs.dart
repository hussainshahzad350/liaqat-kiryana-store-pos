import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../models/invoice_model.dart';
import '../../../domain/entities/money.dart';
import '../dialogs/add_customer_dialog.dart';
import '../dialogs/credit_limit_warning_dialog.dart';
import '../dialogs/increase_limit_dialog.dart';
import '../dialogs/checkout_payment_dialog.dart';
import '../dialogs/post_sale_dialog.dart';
import '../dialogs/cancel_sale_dialog.dart';

/// Dialog routing only; SalesBloc and repositories retain validation/posting.
class SalesDialogs {
  SalesDialogs(this.context);
  final BuildContext context;
  // Quick Add Customer
  void addCustomer() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: const AddCustomerDialog(),
      ),
    ).then((_) {
      // Refresh logic handled by Bloc listener or AddCustomerDialog logic
    });
  }

  void checkout() {
    final state = context.read<SalesBloc>().state;
    if (state.cartItems.isEmpty) return;

    if (state.selectedCustomer == null || !state.shouldShowCreditWarning) {
      showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<SalesBloc>(),
          child: const CheckoutPaymentDialog(),
        ),
      );
      return;
    }

    final selected = state.selectedCustomer!;
    final Money creditLimit = Money(selected.creditLimit);
    final Money currentBalance = Money(selected.outstandingBalance);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: CreditLimitWarningDialog(
          creditLimit: creditLimit,
          currentBalance: currentBalance,
          billTotal: state.grandTotal,
          potentialBalance: state.potentialBalance,
          onContinueAnyway: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: context.read<SalesBloc>(),
                child: const CheckoutPaymentDialog(ignoreCreditLimit: true),
              ),
            );
          },
          onIncreaseLimit: () {
            final int? cid = selected.id;
            if (cid != null) {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<SalesBloc>(),
                  child: IncreaseLimitDialog(
                    customerId: cid,
                    currentLimit: creditLimit,
                    onLimitUpdated: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => BlocProvider.value(
                          value: context.read<SalesBloc>(),
                          child: const CheckoutPaymentDialog(
                              ignoreCreditLimit: true),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void postSale(Invoice invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: PostSaleDialog(invoice: invoice),
      ),
    );
  }

  Future<void> cancelSale(int id, String billNumber) async {
    final result = await showDialog(
      context: context,
      builder: (_) => const CancelSaleDialog(),
    );

    if (result != null && result is String && result.isNotEmpty) {
      if (context.mounted) {
        context.read<SalesBloc>().add(InvoiceCancelled(
              invoiceId: id,
              reason: result,
            ));
      }
    }
  }
}
