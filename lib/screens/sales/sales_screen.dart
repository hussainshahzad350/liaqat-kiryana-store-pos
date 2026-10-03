import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../core/res/app_layout.dart';
import '../../core/res/app_tokens.dart';
import '../../core/services/sales_kpi_service.dart';
import '../../core/utils/error_handler.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';
import '../../models/cart_item_model.dart';
import '../../domain/entities/money.dart';
import 'dialogs/add_customer_dialog.dart';
import 'dialogs/clear_cart_dialog.dart';
import 'dialogs/credit_limit_warning_dialog.dart';
import 'dialogs/increase_limit_dialog.dart';
import 'dialogs/checkout_payment_dialog.dart';
import 'dialogs/post_sale_dialog.dart';
import 'dialogs/cancel_sale_dialog.dart';
import 'dialogs/exit_confirmation_dialog.dart';
import 'widgets/sales_kpi_header.dart';
import 'widgets/sales_actions_toolbar.dart';
import 'widgets/sales_cart_panel.dart';
import 'widgets/sales_product_panel.dart';
import '../../widgets/loading_overlay.dart';
import 'utils/receipt_printer.dart';
import 'utils/sales_shortcuts.dart';
import '../../core/utils/rtl_helper.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int? _lastHandledQuickCustomerId;

  // --- Search & Filter ---
  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController customerSearchController =
      TextEditingController();

  // Debounce Timers
  Timer? _productSearchDebounce;
  Timer? _customerSearchDebounce;

  // --- Totals ---
  final TextEditingController discountController = TextEditingController();

  // --- Settings ---
  bool isSoundOn = true;

  final FocusNode _productSearchFocusNode = FocusNode();

  // --- State Accessors ---
  SalesState get _state => context.read<SalesBloc>().state;
  Customer? get selectedCustomerMap => _state.selectedCustomer;
  int? get selectedCustomerId => _state.selectedCustomer?.id;
  List<CartItem> get cartItems => _state.cartItems;
  Money get grandTotal => _state.grandTotal;
  Money get subtotal => _state.subtotal;
  Money get discount => _state.discount;
  Money get previousBalance => _state.previousBalance;
  List<Product> get filteredProducts => _state.filteredProducts;
  List<Invoice> get recentInvoices => _state.recentInvoices;
  List<Customer> get filteredCustomers => _state.filteredCustomers;
  bool get showCustomerList => _state.showCustomerList;

  void _refreshAllData() => context.read<SalesBloc>().add(SalesStarted());
  void _performClearCart() {
    context.read<SalesBloc>().add(CartCleared());
    customerSearchController.clear();
    discountController.clear();
  }

  void _calculateTotals() =>
      context.read<SalesBloc>().add(DiscountChanged(discountController.text));
  void _updateCartItem(int index, double quantity, Money price) {
    context
        .read<SalesBloc>()
        .add(CartItemUpdated(index: index, quantity: quantity, price: price));
  }

  final ReceiptRepository _receiptRepository = ReceiptRepository();
  late final ReceiptPrinter _receiptPrinter;

  @override
  void initState() {
    super.initState();
    _receiptPrinter = ReceiptPrinter(receiptRepository: _receiptRepository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void dispose() {
    productSearchController.dispose();
    customerSearchController.dispose();
    discountController.dispose();
    _productSearchFocusNode.dispose();
    _productSearchDebounce?.cancel();
    _customerSearchDebounce?.cancel();
    super.dispose();
  }

  void _loadRecentInvoices() {
    _refreshAllData();
  }

  Future<bool> _onWillPop() async {
    final state = context.read<SalesBloc>().state;
    if (state.status == SalesStatus.loading) return false;

    if (state.cartItems.isNotEmpty) {
      final bool? shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => const ExitConfirmationDialog(),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  // --- Item Search Logic ---
  void _filterProducts(String query) {
    _productSearchDebounce?.cancel();
    _productSearchDebounce = Timer(const Duration(milliseconds: 100), () {
      context.read<SalesBloc>().add(ProductSearchChanged(query));
    });
  }

  // --- Customer Search & Add Logic ---
  void _filterCustomers(String query) {
    _customerSearchDebounce?.cancel();

    _customerSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SalesBloc>().add(CustomerSearchChanged(query));
    });
  }

  void _showCustomerSuggestions() {
    if (selectedCustomerId == null &&
        customerSearchController.text.isEmpty &&
        filteredCustomers.isEmpty) {
      context.read<SalesBloc>().add(const CustomerSearchChanged(' '));
    }
  }

  // --- Customer Search & Add Logic ---
  void _selectCustomer(Customer? customer) {
    if (customer == null) {
      customerSearchController.clear();
    } else {
      final localizedName = RTLHelper.getLocalizedName(
        context: context,
        nameEnglish: customer.nameEnglish,
        nameUrdu: customer.nameUrdu,
      );
      customerSearchController.text = localizedName;
    }
    context.read<SalesBloc>().add(CustomerSelected(customer));
  }

  // Quick Add Customer
  void _showAddCustomerDialog() {
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

  // --- Cart Actions ---
  void _addToCart(Product product, {double quantity = 1.0}) {
    if (isSoundOn) {
      SystemSound.play(SystemSoundType.click);
    }
    context
        .read<SalesBloc>()
        .add(ProductAddedToCart(product, quantity: quantity));
  }

  void _removeCartItem(int index) {
    context.read<SalesBloc>().add(CartItemRemoved(index));
  }

  void _clearCart() {
    final state = context.read<SalesBloc>().state;
    if (state.cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: ClearCartDialog(onClear: _performClearCart),
      ),
    );
  }

  // ========================================
  // CHECKOUT DIALOG - USING REPOSITORY
  // ========================================

  void _showCheckoutDialog() {
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

  void _showPostSaleDialog(Invoice invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: PostSaleDialog(invoice: invoice),
      ),
    );
  }

  // ========================================
  // RECEIPT & EDIT ACTIONS
  // ========================================

  Future<void> _handlePrintReceipt(Invoice invoice) async {
    await _receiptPrinter.printReceipt(
      invoice,
      context,
      _loadRecentInvoices,
    );
    if (mounted) {
      context.read<SalesBloc>().add(ReceiptPrintRequested(invoice));
    }
  }

  void _handleEditInvoice(Invoice invoice) {
    if (invoice.isCancelled) {
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.editFeatureComingSoon),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  // ========================================
  // CANCEL SALE - USING REPOSITORY
  // ========================================

  Future<void> _cancelSale(int id, String billNumber) async {
    final result = await showDialog(
      context: context,
      builder: (_) => const CancelSaleDialog(),
    );

    if (result != null && result is String && result.isNotEmpty) {
      if (mounted) {
        context.read<SalesBloc>().add(InvoiceCancelled(
              invoiceId: id,
              reason: result,
            ));
      }
    }
  }

  // ========================================
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Shortcuts(
      shortcuts: SalesShortcuts.getShortcuts(),
      child: Actions(
        actions: SalesShortcuts.createActions(
          onCheckout: () {
            if (cartItems.isNotEmpty) _showCheckoutDialog();
          },
          onClearCart: () {
            if (cartItems.isNotEmpty) _clearCart();
          },
          onFocusSearch: () {
            _productSearchFocusNode.requestFocus();
          },
          onAddCustomer: _showAddCustomerDialog,
          onNewSale: () {
            // Ctrl+Shift+N: start a fresh sale
            _performClearCart();
            _refreshAllData();
          },
          onPrint: () {
            // Ctrl+P: print the most recent invoice if available
            final state = context.read<SalesBloc>().state;
            if (state.recentInvoices.isNotEmpty) {
              _handlePrintReceipt(state.recentInvoices.first);
            }
          },
        ),
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: false,
            onPopInvoked: (bool didPop) async {
              if (didPop) return;
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: BlocConsumer<SalesBloc, SalesState>(
              listener: (context, state) {
                if (state.selectedCustomer == null &&
                    customerSearchController.text.isNotEmpty) {
                  customerSearchController.clear();
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
                  customerSearchController.text =
                      "$quickLocalizedName (${quickAdded.contactPrimary ?? ''})";
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "${loc.customerAdded}: '$quickLocalizedName'"),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                }

                if (state.status == SalesStatus.success) {
                  if (state.completedInvoice != null) {
                    _showPostSaleDialog(state.completedInvoice!);
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
                    final err = ErrorHandler.getLocalizedMessage(
                        state.errorMessage, loc);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                    context.read<SalesBloc>().add(ClearSalesError());
                  }
                }
              },
              builder: (context, state) {
                final salesKpiService = context.read<SalesKpiService>();
                return Stack(
                  children: [
                    Column(
                      children: [
                        SalesKpiHeader(service: salesKpiService),
                        SalesActionsToolbar(
                          onRefresh: _refreshAllData,
                          onClearCart: _clearCart,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppTokens.spacingMedium,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double rightPanelWidth;
                                if (constraints.maxWidth >= 2560) {
                                  rightPanelWidth = 600;
                                } else if (constraints.maxWidth >= 1920) {
                                  rightPanelWidth = 550;
                                } else if (constraints.maxWidth >= 1366) {
                                  rightPanelWidth = 500;
                                } else {
                                  rightPanelWidth = 450;
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: SalesProductPanel(
                                        searchController:
                                            productSearchController,
                                        searchFocusNode:
                                            _productSearchFocusNode,
                                        products: filteredProducts,
                                        recentInvoices: recentInvoices,
                                        onSearchChanged: _filterProducts,
                                        onProductSelected: (product) =>
                                            _addToCart(product),
                                        onPrintInvoice: (invoice) {
                                          _handlePrintReceipt(invoice);
                                        },
                                        onEditInvoice: _handleEditInvoice,
                                        onCancelInvoice: (id, billNumber) {
                                          _cancelSale(id, billNumber);
                                        },
                                      ),
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: colorScheme.outlineVariant,
                                    ),
                                    SizedBox(
                                      width: rightPanelWidth,
                                      child: SalesCartPanel(
                                        customerSearchController:
                                            customerSearchController,
                                        discountController: discountController,
                                        filteredCustomers: filteredCustomers,
                                        showCustomerList: showCustomerList,
                                        selectedCustomerId: selectedCustomerId,
                                        cartItems: cartItems,
                                        isRTL: isRTL,
                                        subtotal: subtotal,
                                        discount: discount,
                                        previousBalance: previousBalance,
                                        grandTotal: grandTotal,
                                        onCustomerSearchChanged:
                                            _filterCustomers,
                                        onCustomerSearchTap:
                                            _showCustomerSuggestions,
                                        onSelectCustomer: _selectCustomer,
                                        onAddCustomer: _showAddCustomerDialog,
                                        onRemoveCartItem: _removeCartItem,
                                        onUpdateCartItem: _updateCartItem,
                                        onCheckout: _showCheckoutDialog,
                                        onDiscountChanged: (_) =>
                                            _calculateTotals(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (state.status == SalesStatus.loading)
                      const LoadingOverlay(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
