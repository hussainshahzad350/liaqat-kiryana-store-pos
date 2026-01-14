// lib/screens/sales/sales_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sprintf/sprintf.dart';
import '../../bloc/sales/invoice_bloc.dart';
import '../../bloc/sales/invoice_event.dart';
import '../../bloc/sales/invoice_state.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../domain/entities/money.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cart_item_model.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import 'widgets/cart_item_row_widget.dart';
import 'widgets/customer_search_widget.dart';
import 'widgets-mobile/product_card_mobile.dart';
import 'widgets-mobile/product_grid_mobile.dart';
import 'widgets/product_card_widget.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final ReceiptRepository _receiptRepository = ReceiptRepository();
  final CustomersRepository _customersRepository = CustomersRepository();

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController customerSearchController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final FocusNode _productSearchFocusNode = FocusNode();

  Timer? _productSearchDebounce;

  bool isSoundOn = true;

  @override
  void dispose() {
    productSearchController.dispose();
    customerSearchController.dispose();
    discountController.dispose();
    _productSearchFocusNode.dispose();
    _productSearchDebounce?.cancel();
    super.dispose();
  }

  void _refreshAllData() => context.read<InvoiceBloc>().add(InvoiceStarted());
  void _performClearCart() {
    context.read<InvoiceBloc>().add(CartCleared());
    customerSearchController.clear();
    discountController.clear();
  }

  void _calculateTotals() =>
      context.read<InvoiceBloc>().add(DiscountChanged(discountController.text));
  void _updateCartItem(int index, double quantity, Money price) {
    context
        .read<InvoiceBloc>()
        .add(CartItemUpdated(index: index, quantity: quantity, price: price));
  }

  Future<bool> _onWillPop() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (context.read<InvoiceBloc>().state.cartItems.isNotEmpty) {
      final bool? shouldExit = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.unsavedTitle),
          content: Text(loc.unsavedMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError),
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.exit),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  void _filterProducts(String query) {
    _productSearchDebounce?.cancel();
    _productSearchDebounce = Timer(const Duration(milliseconds: 100), () {
      context.read<InvoiceBloc>().add(ProductSearchChanged(query));
    });
  }

  void _selectCustomer(Customer? customer) {
    if (customer == null) {
      customerSearchController.clear();
    } else {
      customerSearchController.text =
          "${customer.nameEnglish} (${customer.contactPrimary ?? ''})";
    }
    context.read<InvoiceBloc>().add(CustomerSelected(customer));
  }

  void _showAddCustomerDialog() {
    final loc = AppLocalizations.of(context)!;
    final nameEngCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addNewCustomer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameEngCtrl,
                decoration: InputDecoration(labelText: loc.nameEnglish)),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: loc.phoneNum)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameEngCtrl.text.trim().isEmpty ||
                  phoneCtrl.text.trim().isEmpty) {
                return;
              }
              final newCustomer = Customer(
                nameEnglish: nameEngCtrl.text.trim(),
                contactPrimary: phoneCtrl.text.trim(),
                nameUrdu: '',
                address: '',
                creditLimit: 0,
              );
              final id = await _customersRepository.addCustomer(newCustomer);
              _selectCustomer(newCustomer.copyWith(id: id));
              Navigator.pop(context);
            },
            child: Text(loc.saveSelect),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product, {double quantity = 1.0}) {
    if (isSoundOn) SystemSound.play(SystemSoundType.click);
    context
        .read<InvoiceBloc>()
        .add(ProductAddedToCart(product, quantity: quantity));
  }

  void _removeCartItem(int index) {
    context.read<InvoiceBloc>().add(CartItemRemoved(index));
  }

  void _clearCart() {
    context.read<InvoiceBloc>().add(CartCleared());
  }

  void _showCheckoutDialog() {
    final state = context.read<InvoiceBloc>().state;
    if (state.cartItems.isEmpty) return;

    if (state.selectedCustomer != null) {
      final totalCredit = state.previousBalance + state.grandTotal;
      if (totalCredit.value > state.selectedCustomer!.creditLimit) {
        _showCreditLimitExceededDialog(state, totalCredit);
      } else {
        _showCheckoutPaymentDialog();
      }
    } else {
      _showCheckoutPaymentDialog();
    }
  }

  void _showCreditLimitExceededDialog(InvoiceState state, Money totalCredit) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.creditLimitExceeded,
            style: TextStyle(color: colorScheme.error)),
        content: Text(sprintf(loc.creditLimitExceededMsg, [
          state.selectedCustomer!.nameEnglish,
          state.selectedCustomer!.creditLimit.toString(),
          totalCredit.toString()
        ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCheckoutPaymentDialog();
            },
            child: Text(loc.continueAnyway),
          ),
        ],
      ),
    );
  }

  void _showCheckoutPaymentDialog() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final cashCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final creditCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.checkoutButton),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cashCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.cashInput),
              ),
              TextField(
                controller: bankCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Bank"),
              ),
              TextField(
                controller: creditCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Credit"),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)),
            ElevatedButton(
              onPressed: () {
                final cash = Money.fromRupeesString(cashCtrl.text);
                final bank = Money.fromRupeesString(bankCtrl.text);
                final credit = Money.fromRupeesString(creditCtrl.text);
                _processInvoice(cash, bank, credit);
                Navigator.pop(context);
              },
              child: Text(loc.savePrint),
            ),
          ],
        );
      },
    );
  }

  void _processInvoice(Money cash, Money bank, Money credit) {
    final String currentLanguage = Localizations.localeOf(context).languageCode;
    context.read<InvoiceBloc>().add(InvoiceProcessed(
          cash: cash,
          bank: bank,
          credit: credit,
          change: const Money(0),
          languageCode: currentLanguage,
        ));
  }

  void _showPostSaleDialog(Invoice invoice) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.saleCompleted),
        content: Text('Bill #${invoice.invoiceNumber}'),
        actions: [
          TextButton(
              onPressed: () => _handlePrintReceipt(invoice),
              child: const Text('Print Receipt')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCart();
              _refreshAllData();
            },
            child: const Text('Start New Sale'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrintReceipt(Invoice invoice) async {
    if (invoice.status == 'CANCELLED') return;
    try {
      final receiptData = await _receiptRepository.generateReceiptData(invoice);
      await _receiptRepository.trackPrint(invoice.id!);
      await _receiptRepository.printReceipt(receiptData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  void _handleEditInvoice(Invoice invoice) {
    if (invoice.status == 'CANCELLED') return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Edit feature coming soon')));
  }

  Future<void> _cancelInvoice(int id, String billNumber) async {
    final loc = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(loc.cancelSaleTitle),
        content: TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(labelText: loc.cancelReasonLabel)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(loc.cancelSale)),
        ],
      ),
    );

    if (confirm == true) {
      context
          .read<InvoiceBloc>()
          .add(InvoiceCancelled(invoiceId: id, reason: reasonCtrl.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state.status == InvoiceStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage ?? 'Success'),
            backgroundColor: Colors.green,
          ));
          if (state.successMessage == 'Invoice Completed') {
            final lastInvoice = state.recentInvoices.first;
            _showPostSaleDialog(lastInvoice);
          }
        } else if (state.status == InvoiceStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'An error occurred'),
            backgroundColor: colorScheme.error,
          ));
        }
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.f9): CheckoutIntent(),
          const SingleActivator(LogicalKeyboardKey.escape): ClearCartIntent(),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              FocusSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              AddCustomerIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            CheckoutIntent:
                CallbackAction<CheckoutIntent>(onInvoke: (_) {
              if (context.read<InvoiceBloc>().state.cartItems.isNotEmpty) {
                _showCheckoutDialog();
              }
              return null;
            }),
            ClearCartIntent:
                CallbackAction<ClearCartIntent>(onInvoke: (_) {
              if (context.read<InvoiceBloc>().state.cartItems.isNotEmpty) {
                _clearCart();
              }
              return null;
            }),
            FocusSearchIntent:
                CallbackAction<FocusSearchIntent>(onInvoke: (_) {
              _productSearchFocusNode.requestFocus();
              return null;
            }),
            AddCustomerIntent:
                CallbackAction<AddCustomerIntent>(onInvoke: (_) {
              _showAddCustomerDialog();
              return null;
            }),
          },
          child: Focus(
            autofocus: true,
            child: WillPopScope(
              onWillPop: _onWillPop,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(loc.posTitle),
                  actions: [
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshAllData),
                  ],
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return _buildMobileLayout(loc, colorScheme);
                    } else {
                      return _buildDesktopLayout(loc, colorScheme, isRTL);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      AppLocalizations loc, ColorScheme colorScheme, bool isRTL) {
    final state = context.watch<InvoiceBloc>().state;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: productSearchController,
                  focusNode: _productSearchFocusNode,
                  decoration: InputDecoration(
                      hintText: loc.searchItemHint,
                      prefixIcon: const Icon(Icons.search)),
                  onChanged: _filterProducts,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 2 / 2.5,
                  ),
                  itemCount: state.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = state.filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _addToCart(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 450,
          child: Column(
            children: [
              CustomerSearchWidget(
                controller: customerSearchController,
                onAddCustomer: _showAddCustomerDialog,
                onSelectCustomer: _selectCustomer,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = state.cartItems[index];
                    return CartItemRow(
                      item: item,
                      index: index,
                      isRTL: isRTL,
                      colorScheme: colorScheme,
                      onRemove: _removeCartItem,
                      onUpdate: _updateCartItem,
                    );
                  },
                ),
              ),
              _buildTotalsSection(loc, colorScheme, state),
              _buildRecentSalesSection(loc, colorScheme, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AppLocalizations loc, ColorScheme colorScheme) {
    final state = context.watch<InvoiceBloc>().state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: productSearchController,
            focusNode: _productSearchFocusNode,
            decoration: InputDecoration(
                hintText: loc.searchItemHint,
                prefixIcon: const Icon(Icons.search)),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: ProductGridMobile(
            products: state.filteredProducts,
            onProductTap: (product) => _addToCart(product),
          ),
        ),
        // A summary button to open the cart/checkout in a dialog or bottom sheet
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _showMobileCartDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.viewCart),
                Text(state.grandTotal.toString()),
              ],
            ),
          ),
        )
      ],
    );
  }

  void _showMobileCartDialog() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // We need a BlocProvider.value here because the BottomSheet is in a new route
        return BlocProvider.value(
          value: BlocProvider.of<InvoiceBloc>(this.context),
          child: Builder(builder: (context) {
            final state = context.watch<InvoiceBloc>().state;
            return DraggableScrollableSheet(
              expand: false,
              builder: (_, controller) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(loc.cartTitle,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Divider(),
                      CustomerSearchWidget(
                        controller: customerSearchController,
                        onAddCustomer: _showAddCustomerDialog,
                        onSelectCustomer: _selectCustomer,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: state.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = state.cartItems[index];
                            return CartItemRow(
                              item: item,
                              index: index,
                              isRTL: isRTL,
                              colorScheme: colorScheme,
                              onRemove: _removeCartItem,
                              onUpdate: _updateCartItem,
                            );
                          },
                        ),
                      ),
                      _buildTotalsSection(loc, colorScheme, state),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showCheckoutDialog,
                          child: Text(loc.checkoutButton),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildTotalsSection(
      AppLocalizations loc, ColorScheme colorScheme, InvoiceState state) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(loc.subtotal,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(state.subtotal.toString(),
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(loc.discount,
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                  width: 100,
                  child: TextField(
                    controller: discountController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) => _calculateTotals(),
                  )),
            ]),
            if (state.selectedCustomer != null) ...[
              const SizedBox(height: 8),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.previousBalance,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(state.previousBalance.toString(),
                        style: Theme.of(context).textTheme.titleMedium),
                  ]),
            ],
            const Divider(thickness: 1, height: 24),
            DefaultTextStyle(
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontWeight: FontWeight.bold),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.grandTotal),
                    Text(state.grandTotal.toString()),
                  ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed:
                    state.cartItems.isEmpty ? null : _showCheckoutDialog,
                child: Text(loc.checkoutButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesSection(
      AppLocalizations loc, ColorScheme colorScheme, InvoiceState state) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(loc.recentSales,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.recentInvoices.length,
              itemBuilder: (context, index) {
                final invoice = state.recentInvoices[index];
                final bool isCancelled = invoice.status == 'CANCELLED';
                return ListTile(
                  title: Text(invoice.customerName ?? loc.walkInCustomer),
                  subtitle: Text(invoice.invoiceNumber),
                  trailing: Text(Money(invoice.grandTotal).toString(),
                      style: TextStyle(
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                  onTap: () => _showInvoiceActionsDialog(invoice),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceActionsDialog(Invoice invoice) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${loc.invoice} #${invoice.invoiceNumber}'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _handlePrintReceipt(invoice);
            },
            child: ListTile(
                leading: const Icon(Icons.print), title: Text(loc.print)),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _handleEditInvoice(invoice);
            },
            child: ListTile(
                leading: const Icon(Icons.edit), title: Text(loc.edit)),
          ),
          if (invoice.status != 'CANCELLED')
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _cancelInvoice(invoice.id!, invoice.invoiceNumber);
              },
              child: ListTile(
                  leading: Icon(Icons.cancel,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(loc.cancelSale,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error))),
            ),
        ],
      ),
    );
  }
}

class CheckoutIntent extends Intent {
  const CheckoutIntent();
}

class ClearCartIntent extends Intent {
  const ClearCartIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class AddCustomerIntent extends Intent {
  const AddCustomerIntent();
}
