import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../core/services/sales_kpi_service.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';
import '../../models/cart_item_model.dart';
import '../../domain/entities/money.dart';
import 'dialogs/clear_cart_dialog.dart';
import 'dialogs/exit_confirmation_dialog.dart';
import 'widgets/sales_cart_panel.dart';
import 'widgets/sales_product_panel.dart';
import 'utils/receipt_printer.dart';
import 'utils/sales_shortcuts.dart';
import 'utils/sales_dialogs.dart';
import 'widgets/sales_feedback_listener.dart';
import 'widgets/sales_workspace.dart';
import '../../core/theme/app_ui_theme.dart';
import '../../core/utils/rtl_helper.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  BuildContext? _presentationContext;
  SalesDialogs get _dialogs => SalesDialogs(_presentationContext ?? context);

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
  final FocusScopeNode _salesFocusScopeNode = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  // --- State Accessors ---
  SalesState get _state => context.read<SalesBloc>().state;

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
    _salesFocusScopeNode.dispose();
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
        context: _presentationContext ?? context,
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

  void _showAddCustomerDialog() => _dialogs.addCustomer();

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
      context: _presentationContext ?? context,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: ClearCartDialog(onClear: _performClearCart),
      ),
    );
  }

  // ========================================
  // CHECKOUT DIALOG - USING REPOSITORY
  // ========================================

  void _showCheckoutDialog() => _dialogs.checkout();
  void _showPostSaleDialog(Invoice invoice) => _dialogs.postSale(invoice);

  // ========================================
  // RECEIPT & EDIT ACTIONS
  // ========================================

  Future<void> _handlePrintReceipt(Invoice invoice) async {
    await _receiptPrinter.printReceipt(
      invoice,
      context,
      _loadRecentInvoices,
    );
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

  Future<void> _cancelSale(int id, String billNumber) =>
      _dialogs.cancelSale(id, billNumber);

  // ========================================
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) => Theme(
        data: AppUiTheme.fromTheme(Theme.of(context),
            isRTL: Directionality.of(context) == TextDirection.rtl),
        child: Builder(builder: _buildWorkspace),
      );

  Widget _buildWorkspace(BuildContext context) {
    _presentationContext = context;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
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
        child: FocusScope(
          node: _salesFocusScopeNode,
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
            child: SalesFeedbackListener(
              customerSearchController: customerSearchController,
              onCompleted: _showPostSaleDialog,
              child: BlocBuilder<SalesBloc, SalesState>(
                builder: (context, state) {
                  return SalesWorkspace(
                    state: state,
                    service: context.read<SalesKpiService>(),
                    onRefresh: _refreshAllData,
                    onClearCart: _clearCart,
                    products: SalesProductPanel(
                      searchController: productSearchController,
                      searchFocusNode: _productSearchFocusNode,
                      products: filteredProducts,
                      recentInvoices: recentInvoices,
                      onSearchChanged: _filterProducts,
                      onProductSelected: (product) => _addToCart(product),
                      onPrintInvoice: (invoice) {
                        _handlePrintReceipt(invoice);
                      },
                      onEditInvoice: _handleEditInvoice,
                      onCancelInvoice: (id, billNumber) {
                        _cancelSale(id, billNumber);
                      },
                    ),
                    cart: SalesCartPanel(
                      customerSearchController: customerSearchController,
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
                      onCustomerSearchChanged: _filterCustomers,
                      onCustomerSearchTap: _showCustomerSuggestions,
                      onSelectCustomer: _selectCustomer,
                      onAddCustomer: _showAddCustomerDialog,
                      onRemoveCartItem: _removeCartItem,
                      onUpdateCartItem: _updateCartItem,
                      onCheckout: _showCheckoutDialog,
                      onDiscountChanged: (_) => _calculateTotals(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
