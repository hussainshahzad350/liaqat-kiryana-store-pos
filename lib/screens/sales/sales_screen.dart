// lib/screens/sales/sales_screen.dart
// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../core/constants/desktop_dimensions.dart';
import '../../core/res/app_dimensions.dart';
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
import 'widgets/product_card.dart';
import 'widgets/recent_sales_section.dart';
import 'widgets/customer_section.dart';
import 'widgets/sales_totals_section.dart';
import 'widgets/cart_item_row.dart';
import 'widgets/loading_overlay.dart';
import 'utils/receipt_printer.dart';
import 'utils/sales_shortcuts.dart';

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

    _customerSearchDebounce =
        Timer(const Duration(milliseconds: 300), () async {
      context.read<SalesBloc>().add(CustomerSearchChanged(query));
    });
  }

  // --- Customer Search & Add Logic ---
  void _selectCustomer(Customer? customer) {
    if (customer == null) {
      customerSearchController.clear();
    } else {
      customerSearchController.text =
          "${customer.nameEnglish} (${customer.contactPrimary ?? ''})";
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
    if (invoice.status == 'CANCELLED') {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.editFeatureComingSoon)),
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
        ),
        child: Focus(
          autofocus: true,
          child: WillPopScope(
            onWillPop: _onWillPop,
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
                  customerSearchController.text =
                      "${quickAdded.nameEnglish} (${quickAdded.contactPrimary ?? ''})";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "${loc.customerAdded}: '${quickAdded.nameEnglish}'"),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                } else if (state.status == SalesStatus.error) {
                  final err =
                      state.errorMessage == 'Cannot print cancelled invoice'
                          ? loc.cannotPrintCancelled
                          : state.errorMessage == 'Phone already exists'
                              ? loc.phoneExistsError
                              : state.errorMessage == 'Phone number is required'
                                  ? loc.phoneRequired
                                  : state.errorMessage == 'Name is required'
                                      ? loc.nameRequired
                                      : state.errorMessage ??
                                          'An unknown error occurred';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        // Actions Toolbar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesktopDimensions.spacingMedium,
                              vertical: DesktopDimensions.spacingStandard),
                          color: colorScheme.surface,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    size: DesktopDimensions.kpiIconSize),
                                color: colorScheme.primary,
                                onPressed: _refreshAllData,
                                tooltip: 'Refresh',
                              ),
                              const SizedBox(
                                  width: DesktopDimensions.spacingMedium),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep,
                                    size: DesktopDimensions.kpiIconSize),
                                color: colorScheme.error,
                                onPressed: _clearCart,
                                tooltip: loc.clearCartTitle,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                DesktopDimensions.spacingMedium),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Responsive Right Panel Width
                                double rightPanelWidth = 500;
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // LEFT PANEL (Fluid)
                                    Expanded(
                                      child: Column(
                                        children: [
                                          // Item Search
                                          Card(
                                            elevation:
                                                DesktopDimensions.cardElevation,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        DesktopDimensions
                                                            .cardBorderRadius)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                  DesktopDimensions
                                                      .cardPadding),
                                              child: Focus(
                                                onFocusChange: (hasFocus) {
                                                  if (hasFocus) {
                                                    _productSearchFocusNode
                                                        .requestFocus();
                                                  }
                                                },
                                                child: TextField(
                                                  controller:
                                                      productSearchController,
                                                  focusNode:
                                                      _productSearchFocusNode,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        loc.searchItemHint,
                                                    isDense: true,
                                                    prefixIcon: Icon(
                                                        Icons.search,
                                                        color: colorScheme
                                                            .onSurfaceVariant),
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                DesktopDimensions
                                                                    .cardBorderRadius)),
                                                    filled: true,
                                                    fillColor: colorScheme
                                                        .surfaceVariant
                                                        .withOpacity(0.5),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            vertical: 14,
                                                            horizontal: 12),
                                                  ),
                                                  onChanged: _filterProducts,
                                                  onTap: () {
                                                    if (productSearchController
                                                        .text.isNotEmpty) {
                                                      _filterProducts(
                                                          productSearchController
                                                              .text);
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              height: DesktopDimensions
                                                  .spacingMedium),

                                          // Product Grid
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder:
                                                  (context, gridConstraints) {
                                                int crossAxisCount =
                                                    (gridConstraints.maxWidth /
                                                            180)
                                                        .floor();
                                                crossAxisCount =
                                                    crossAxisCount.clamp(4, 8);

                                                return GridView.builder(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal:
                                                          DesktopDimensions
                                                              .spacingMedium,
                                                      vertical: AppDimensions
                                                          .spacingSmall),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount:
                                                        crossAxisCount,
                                                    childAspectRatio: 16 / 9,
                                                    crossAxisSpacing:
                                                        DesktopDimensions
                                                            .spacingStandard,
                                                    mainAxisSpacing:
                                                        DesktopDimensions
                                                            .spacingStandard,
                                                  ),
                                                  itemCount:
                                                      filteredProducts.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final product =
                                                        filteredProducts[index];
                                                    return Focus(
                                                      child: Builder(
                                                          builder: (context) {
                                                        return ProductCard(
                                                            product: product,
                                                            isFocused: Focus.of(context).hasFocus,
                                                            onTap: () => _addToCart(product),
                                                        );
                                                      }),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),

                                          // Recent Sales
                                          RecentSalesSection(
                                            recentInvoices: recentInvoices,
                                            onPrint: _handlePrintReceipt,
                                            onEdit: _handleEditInvoice,
                                            onCancel: _cancelSale,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Vertical Divider
                                    VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: colorScheme.outlineVariant),

                                    // RIGHT PANEL (Fixed Width)
                                    SizedBox(
                                      width: rightPanelWidth,
                                      child: Container(
                                        color: colorScheme.surface,
                                        child: Column(
                                          children: [
                                            // Customer Section
                                            CustomerSection(
                                              searchController: customerSearchController,
                                              filteredCustomers: filteredCustomers,
                                              showCustomerList: showCustomerList,
                                              selectedCustomerId: selectedCustomerId,
                                              onSearchChanged: _filterCustomers,
                                              onSearchTap: () async {
                                                if (selectedCustomerId == null) {
                                                  if (customerSearchController.text.isEmpty &&
                                                      filteredCustomers.isEmpty) {
                                                    context
                                                        .read<SalesBloc>()
                                                        .add(const CustomerSearchChanged(' '));
                                                  }
                                                }
                                              },
                                              onSelectCustomer: _selectCustomer,
                                              onAddCustomer: _showAddCustomerDialog,
                                            ),
                                            Divider(
                                                height: 1,
                                                color:
                                                    colorScheme.outlineVariant),

                                            // Cart Header
                                            Container(
                                              height: 32,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          DesktopDimensions
                                                              .spacingMedium),
                                              color: colorScheme.surfaceVariant
                                                  .withOpacity(0.5),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                      flex: 4,
                                                      child: Text(loc.item,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              color: colorScheme
                                                                  .onSurfaceVariant))),
                                                  SizedBox(
                                                      width: 70,
                                                      child: Text(loc.price,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              color: colorScheme
                                                                  .onSurfaceVariant))),
                                                  const SizedBox(
                                                      width: AppDimensions
                                                          .spacingMedium),
                                                  SizedBox(
                                                      width: 60,
                                                      child: Text(loc.qty,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              color: colorScheme
                                                                  .onSurfaceVariant))),
                                                  const SizedBox(
                                                      width: AppDimensions
                                                          .spacingMedium),
                                                  SizedBox(
                                                      width: 70,
                                                      child: Text(loc.total,
                                                          textAlign:
                                                              TextAlign.end,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              color: colorScheme
                                                                  .onSurfaceVariant))),
                                                  const SizedBox(width: 32),
                                                ],
                                              ),
                                            ),
                                            Divider(
                                                height: 1,
                                                color:
                                                    colorScheme.outlineVariant),

                                            // Cart Items
                                            Expanded(
                                              child: cartItems.isEmpty
                                                  ? Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .shopping_cart_outlined,
                                                              size: 64,
                                                              color: colorScheme
                                                                  .outline
                                                                  .withOpacity(
                                                                      0.5)),
                                                          const SizedBox(
                                                              height: DesktopDimensions
                                                                  .spacingMedium),
                                                          Text(loc.cartEmpty,
                                                              style: TextStyle(
                                                                  color: colorScheme
                                                                      .onSurfaceVariant,
                                                                  fontSize:
                                                                      DesktopDimensions
                                                                          .bodySize)),
                                                        ],
                                                      ),
                                                    )
                                                  : ListView.separated(
                                                      itemCount:
                                                          cartItems.length,
                                                      separatorBuilder: (c,
                                                              i) =>
                                                          const Divider(
                                                              height: 1,
                                                              thickness: 0.5),
                                                      itemBuilder:
                                                          (context, index) {
                                                        final item =
                                                            cartItems[index];
                                                        return CartItemRow(
                                                          item: item,
                                                          index: index,
                                                          isRTL: isRTL,
                                                          colorScheme:
                                                              colorScheme,
                                                          onRemove:
                                                              _removeCartItem,
                                                          onUpdate:
                                                              _updateCartItem,
                                                        );
                                                      },
                                                    ),
                                            ),

                                            Divider(
                                                height: 1,
                                                color:
                                                    colorScheme.outlineVariant),

                                            // Totals Section
                                            SalesTotalsSection(
                                              discountController: discountController,
                                              subtotal: subtotal,
                                              discount: discount,
                                              previousBalance: previousBalance,
                                              grandTotal: grandTotal,
                                              isCheckoutEnabled: cartItems.isNotEmpty,
                                              onCheckout: _showCheckoutDialog,
                                              onDiscountChanged: (_) => setState(() => _calculateTotals()),
                                            ),
                                          ],
                                        ),
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
