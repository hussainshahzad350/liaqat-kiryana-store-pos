// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import '../../core/constants/desktop_dimensions.dart';
import '../../core/res/app_dimensions.dart';
import '../../core/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';
import '../../models/cart_item_model.dart';
import '../../domain/entities/money.dart';
import '../../widgets/app_header.dart';
import '../../widgets/main_layout.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final ReceiptRepository _receiptRepository = ReceiptRepository();
  final CustomersRepository _customersRepository = CustomersRepository();

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

  Future<void> _loadRecentInvoices() async =>
      context.read<SalesBloc>().add(SalesStarted());
  void _calculateTotals() =>
      context.read<SalesBloc>().add(DiscountChanged(discountController.text));
  void _updateCartItem(int index, double quantity, Money price) {
    context
        .read<SalesBloc>()
        .add(CartItemUpdated(index: index, quantity: quantity, price: price));
  }

  @override
  void initState() {
    super.initState();
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

  Future<bool> _onWillPop() async {
    final state = context.read<SalesBloc>().state;
    if (state.status == SalesStatus.loading) return false;

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (state.cartItems.isNotEmpty) {
      final bool? shouldExit = await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              minWidth: 800,
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.unsavedTitle,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(loc.unsavedMsg, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(loc.exit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final customersRepo = CustomersRepository(); // Use repo directly for add

    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        // Dialog content
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 800,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.addNewCustomer,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: nameEngCtrl,
                          decoration:
                              InputDecoration(labelText: loc.nameEnglish)),
                      TextField(
                          controller: nameUrduCtrl,
                          decoration: InputDecoration(labelText: loc.nameUrdu)),
                      TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: loc.phoneNum)),
                      TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(labelText: loc.address)),
                      TextField(
                          controller: creditLimitCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: loc.creditLimit)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.cancel)),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary),
                    onPressed: () async {
                      // Validation
                      if (nameEngCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.nameRequired)));
                        return;
                      }
                      String phoneNumber = phoneCtrl.text.trim();
                      if (phoneNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.phoneRequired)));
                        return;
                      }

                      try {
                        // Check if phone exists using repository
                        final existingCustomers =
                            await customersRepo.searchCustomers(phoneNumber);
                        final phoneExists = existingCustomers
                            .any((c) => c.contactPrimary == phoneNumber);

                        if (phoneExists) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('${loc.phoneExists}: "$phoneNumber"'),
                              backgroundColor: colorScheme.error));
                          return;
                        }

                        final newCustomer = Customer(
                          nameEnglish: nameEngCtrl.text.trim(),
                          nameUrdu: nameUrduCtrl.text.trim(),
                          contactPrimary: phoneNumber,
                          address: addressCtrl.text.trim(),
                          creditLimit:
                              Money.fromRupeesString(creditLimitCtrl.text)
                                  .paisas,
                        );

                        final int id =
                            await customersRepo.addCustomer(newCustomer);
                        final Customer savedCustomer =
                            newCustomer.copyWith(id: id);

                        if (mounted) {
                          _selectCustomer(savedCustomer);
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "${loc.customerAdded}: '${nameEngCtrl.text}'"),
                              backgroundColor: colorScheme.primary));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${loc.error}: $e'),
                            backgroundColor: colorScheme.error));
                      }
                    },
                    child: Text(loc.saveSelect),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameEngCtrl.dispose();
      nameUrduCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      creditLimitCtrl.dispose();
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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.read<SalesBloc>().state;

    if (state.cartItems.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 800,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.clearCartTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(loc.clearCartMsg, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _performClearCart();
                    },
                    child: Text(loc.clearAll),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // CHECKOUT DIALOG - USING REPOSITORY
  // ========================================

  void _showCheckoutDialog() {
    final state = context.read<SalesBloc>().state;
    if (state.cartItems.isEmpty) {
      return;
    }

    // 1. Walk-in Customer Flow
    if (state.selectedCustomer == null) {
      _showCheckoutPaymentDialog();
      return;
    }

    // 2. Registered Customer Flow - Check Credit Limit
    Money creditLimit = Money(state.selectedCustomer?.creditLimit ?? 0);
    Money currentBalance =
        Money(state.selectedCustomer?.outstandingBalance ?? 0);
    final Money potentialBalance = currentBalance + state.grandTotal;

    if (potentialBalance > creditLimit) {
      _showCreditLimitWarningDialog(
        creditLimit: creditLimit,
        currentBalance: currentBalance,
        billTotal: state.grandTotal,
        potentialBalance: potentialBalance,
        onContinueAnyway: () =>
            _showCheckoutPaymentDialog(ignoreCreditLimit: true),
        onIncreaseLimit: () {
          _showIncreaseLimitDialog(onLimitUpdated: () {
            _showCheckoutPaymentDialog(ignoreCreditLimit: true);
          });
        },
      );
    } else {
      _showCheckoutPaymentDialog();
    }
  }

  void _showCreditLimitWarningDialog({
    required Money creditLimit,
    required Money currentBalance,
    required Money billTotal,
    required Money potentialBalance,
    required Function() onContinueAnyway,
    required Function() onIncreaseLimit,
  }) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 800,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error),
                  const SizedBox(width: 10),
                  Text(loc.creditLimitExceeded,
                      style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.creditLimitWarningMsg(creditLimit.toString()),
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 16)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('${loc.customerCreditLimit}:',
                                creditLimit.toString(),
                                color: colorScheme.onErrorContainer),
                            _infoRow('${loc.currentBalance}:',
                                currentBalance.toString(),
                                color: colorScheme.onErrorContainer),
                            _infoRow('${loc.billTotal}:', billTotal.toString(),
                                color: colorScheme.onErrorContainer),
                            Divider(
                                color: colorScheme.onErrorContainer
                                    .withOpacity(0.5)),
                            _infoRow(
                              '${loc.totalBalance}:',
                              potentialBalance.toString(),
                              isBold: true,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${loc.excessAmount}: ${(potentialBalance - creditLimit).toString()}',
                              style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onIncreaseLimit();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      foregroundColor: colorScheme.primary,
                    ),
                    child: Text(loc.increaseLimit),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onContinueAnyway();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    child: Text(loc.continueAnyway),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncreaseLimitDialog({required VoidCallback onLimitUpdated}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final limitCtrl = TextEditingController();
    final salesBloc = context.read<SalesBloc>();

    Money currentLimit = Money(selectedCustomerMap?.creditLimit ?? 0);
    limitCtrl.text = currentLimit.toRupeesString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              minWidth: 800,
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.increaseCreditLimit,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Text('${loc.current}: ${currentLimit.toString()}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: limitCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.newCreditLimit,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        Money newLimit = Money.fromRupeesString(limitCtrl.text);
                        if (selectedCustomerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidLimit)),
                          );
                          return;
                        }

                        try {
                          await _customersRepository.updateCustomerCreditLimit(
                              selectedCustomerId!, newLimit.paisas);

                          salesBloc.add(CustomerSelected(selectedCustomerMap!
                              .copyWith(creditLimit: newLimit.paisas)));

                          if (mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${loc.creditLimitUpdated}: ${newLimit.toString()}'),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                            onLimitUpdated();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${loc.error}: $e'),
                                  backgroundColor: colorScheme.error),
                            );
                          }
                        }
                      },
                      child: Text(loc.updateLimit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCheckoutPaymentDialog({bool ignoreCreditLimit = false}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    bool isRegistered = selectedCustomerId != null;
    Money billTotal = grandTotal;
    Money oldBalance = previousBalance;

    final cashCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final creditCtrl = TextEditingController();

    if (isRegistered) {
      creditCtrl.text = '0';
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            Money cash = Money.fromRupeesString(cashCtrl.text);
            Money bank = Money.fromRupeesString(bankCtrl.text);
            Money credit = Money.fromRupeesString(creditCtrl.text);
            Money totalPayment = cash + bank + credit;
            Money change = const Money(0);
            bool isValid = false;

            if (isRegistered) {
              isValid = totalPayment == billTotal;
            } else {
              isValid = (cash + bank) >= billTotal;
              if (isValid) {
                change = (cash + bank) - billTotal;
              }
            }

            void processSaleAction() {
              Navigator.pop(context);
              _processSale(cash, bank, credit, change);
            }

            void checkCreditLimitAndProcess() {
              if (ignoreCreditLimit) {
                processSaleAction();
                return;
              }

              if (!isRegistered || credit <= const Money(0)) {
                processSaleAction();
                return;
              }

              final Money creditLimit = Money(selectedCustomerMap!.creditLimit);
              final Money potentialBalance = oldBalance + credit;

              if (potentialBalance > creditLimit) {
                Navigator.pop(context);
                _showCreditLimitWarningDialog(
                  creditLimit: creditLimit,
                  currentBalance: oldBalance,
                  billTotal: credit,
                  potentialBalance: potentialBalance,
                  onContinueAnyway: () =>
                      _showCheckoutPaymentDialog(ignoreCreditLimit: true),
                  onIncreaseLimit: () => _showIncreaseLimitDialog(
                      onLimitUpdated: () =>
                          _showCheckoutPaymentDialog(ignoreCreditLimit: true)),
                );
              } else {
                processSaleAction();
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 800,
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(loc.checkoutButton,
                            style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isRegistered) ...[
                              Text(
                                  '${loc.searchCustomerHint}: ${selectedCustomerMap!.nameEnglish}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: colorScheme.secondary)),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16, color: colorScheme.secondary),
                                    const SizedBox(width: 5),
                                    Text(
                                        '${loc.prevBalance}: ${oldBalance.toString()}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme
                                                .onSecondaryContainer)),
                                  ],
                                ),
                              ),
                              const Divider(height: 20),
                            ],
                            _infoRow(loc.billTotal, billTotal.toString(),
                                isBold: true,
                                size: 18,
                                color: colorScheme.onSurface),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(loc.paymentLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorScheme.onSurface)),
                            const SizedBox(height: 10),
                            _input(loc.cashInput, cashCtrl, (v) {
                              setDialogState(() {
                                if (isRegistered) {
                                  Money cash =
                                      Money.fromRupeesString(cashCtrl.text);
                                  Money bank =
                                      Money.fromRupeesString(bankCtrl.text);
                                  Money remaining = billTotal - cash - bank;
                                  creditCtrl.text = remaining > const Money(0)
                                      ? remaining.toRupeesString()
                                      : '0';
                                }
                              });
                            }),
                            _input(loc.bankInput, bankCtrl, (v) {
                              setDialogState(() {
                                if (isRegistered) {
                                  Money cash =
                                      Money.fromRupeesString(cashCtrl.text);
                                  Money bank =
                                      Money.fromRupeesString(bankCtrl.text);
                                  Money remaining = billTotal - cash - bank;
                                  creditCtrl.text = remaining > const Money(0)
                                      ? remaining.toRupeesString()
                                      : '0';
                                }
                              });
                            }),
                            if (isRegistered)
                              _input(loc.creditInput, creditCtrl, (v) {
                                setDialogState(() {});
                              }),
                            const SizedBox(height: 10),
                            if (!isRegistered)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(loc.changeDue,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface)),
                                  Text(change.toString(),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: change >= const Money(0)
                                              ? colorScheme.primary
                                              : colorScheme.error)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.cancel),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed:
                              isValid ? checkCreditLimitAndProcess : null,
                          child: Text(loc.savePrint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  Widget _infoRow(String label, String value,
      {bool isBold = false, double size = 14, Color? color}) {
    final defaultColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? defaultColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? defaultColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
      String label, TextEditingController ctrl, Function(String) onChanged,
      {bool enabled = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface))),
        Expanded(
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(10),
              border: const OutlineInputBorder(),
              prefixText: 'Rs ',
              filled: !enabled,
              fillColor: enabled ? null : colorScheme.surfaceVariant,
            ),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant),
            onChanged: onChanged,
          ),
        ),
      ]),
    );
  }

  // ========================================
  // PROCESS SALE - USING REPOSITORY
  // ========================================

  Future<void> _processSale(
      Money cash, Money bank, Money credit, Money change) async {
    final bloc = context.read<SalesBloc>();
    final currentLanguage = Localizations.localeOf(context).languageCode;

    bloc.add(InvoiceProcessed(
      cash: cash,
      bank: bank,
      credit: credit,
      change: change,
      languageCode: currentLanguage,
    ));

    // The BLoC will handle showing a loading dialog, processing, and showing the result.
    // For now, we can listen to the state changes in the UI to show dialogs.
  }

  void _showPostSaleDialog(Invoice invoice) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(loc.saleCompleted,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text('${loc.bill} #${invoice.invoiceNumber}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),

                // Print
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePrintReceipt(invoice),
                    icon: const Icon(Icons.print),
                    label: Text(loc.printReceipt),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Save PDF
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final path =
                            await _receiptRepository.saveReceiptAsPDF(invoice);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Receipt saved to: $path')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error saving PDF: $e'),
                                backgroundColor: colorScheme.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(loc.saveAsPdf),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // New Sale
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _performClearCart();
                      _refreshAllData();
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(loc.startNewSale),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // RECEIPT & EDIT ACTIONS
  // ========================================

  Future<void> _handlePrintReceipt(Invoice invoice) async {
    final loc = AppLocalizations.of(context)!;
    if (invoice.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.cannotPrintCancelled)),
      );
      return;
    }

    try {
      final receiptData = await _receiptRepository.generateReceiptData(invoice);
      await _receiptRepository.trackPrint(invoice.id!);
      _loadRecentInvoices();
      await _receiptRepository.printReceipt(receiptData);
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
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
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
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: 800,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.cancelSaleTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(loc.cancelSaleMessage, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: loc.cancelReasonLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(loc.cancelSale),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) {
      return;
    }

    context.read<SalesBloc>().add(InvoiceCancelled(
          invoiceId: id,
          reason: reasonCtrl.text.trim(),
        ));
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
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f9): CheckoutIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ClearCartIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            AddCustomerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CheckoutIntent: CallbackAction<CheckoutIntent>(onInvoke: (_) {
            if (cartItems.isNotEmpty) _showCheckoutDialog();
            return null;
          }),
          ClearCartIntent: CallbackAction<ClearCartIntent>(onInvoke: (_) {
            if (cartItems.isNotEmpty) _clearCart();
            return null;
          }),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(onInvoke: (_) {
            _productSearchFocusNode.requestFocus();
            return null;
          }),
          AddCustomerIntent: CallbackAction<AddCustomerIntent>(onInvoke: (_) {
            _showAddCustomerDialog();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: WillPopScope(
            onWillPop: _onWillPop,
            child: BlocConsumer<SalesBloc, SalesState>(
              listener: (context, state) {
                if (state.status == SalesStatus.success) {
                  if (state.completedInvoice != null) {
                    _showPostSaleDialog(state.completedInvoice!);
                  } else if (state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage!),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                } else if (state.status == SalesStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          state.errorMessage ?? 'An unknown error occurred'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return MainLayout(
                  currentRoute: AppRoutes.sales,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          AppHeader(
                            title: loc.posTitle,
                            icon: Icons.point_of_sale,
                            actions: [
                              IconButton(
                                icon: Icon(Icons.refresh,
                                    color: colorScheme.onPrimary),
                                onPressed: _refreshAllData,
                                tooltip: 'Refresh',
                              ),
                              const SizedBox(
                                  width: DesktopDimensions.spacingMedium),
                              IconButton(
                                icon: Icon(Icons.delete_sweep,
                                    color: colorScheme.onPrimary),
                                onPressed: _clearCart,
                                tooltip: loc.clearCartTitle,
                              ),
                            ],
                          ),
                          Expanded(
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
                                          Padding(
                                            padding: const EdgeInsets.all(
                                                DesktopDimensions.spacingMedium),
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
                                                  hintText: loc.searchItemHint,
                                                  isDense: true,
                                                  prefixIcon: Icon(Icons.search,
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

                                          // Product Grid
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context,
                                                  gridConstraints) {
                                                int crossAxisCount =
                                                    (gridConstraints.maxWidth /
                                                            180)
                                                        .floor();
                                                crossAxisCount =
                                                    crossAxisCount.clamp(4, 8);

                                                return GridView.builder(
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                                        return _buildProductCard(
                                                            product,
                                                            colorScheme,
                                                            Focus.of(context)
                                                                .hasFocus);
                                                      }),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),

                                          // Recent Sales
                                          _buildRecentSalesSection(
                                              loc, colorScheme),
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
                                            _buildCustomerSection(
                                                loc, colorScheme),
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
                                                      child: Text('Item',
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
                                                      child: Text('Total',
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
                                                        return _CartItemRow(
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
                                            _buildTotalsSection(
                                                loc, colorScheme),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (state.status == SalesStatus.loading)
                        _buildLoadingOverlay(loc, colorScheme),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 20),
              Text(
                "Processing...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
      Product product, ColorScheme colorScheme, bool isFocused) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isFocused
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.3),
            width: isFocused ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => _addToCart(product),
        hoverColor: colorScheme.primaryContainer.withOpacity(0.3),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 16,
                          color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          product.salePrice.formatted,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.nameEnglish,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (product.nameUrdu != null && product.nameUrdu!.isNotEmpty)
                    Text(
                      product.nameUrdu!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'NooriNastaleeq',
                        color: colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (product.currentStock) < 10
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product.currentStock}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (product.currentStock) < 10
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesSection(
      AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            width: double.infinity,
            child: Text(loc.recentSales,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: recentInvoices.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final invoice = recentInvoices[index];
                final isCancelled = invoice.status == 'CANCELLED';
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isCancelled
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isCancelled
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer)),
                  ),
                  title: Text(
                    invoice.customerName ?? loc.walkInCustomer,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCancelled ? TextDecoration.lineThrough : null,
                      color: isCancelled
                          ? colorScheme.onSurface.withOpacity(0.6)
                          : colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(invoice.invoiceNumber,
                      style: TextStyle(
                          fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Money(invoice.totalAmount).formatted,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.onSurface)),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 18, color: colorScheme.onSurfaceVariant),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'print') _handlePrintReceipt(invoice);
                          if (value == 'edit') _handleEditInvoice(invoice);
                          if (value == 'cancel') {
                            _cancelSale(invoice.id!, invoice.invoiceNumber);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isCancelled) ...[
                            const PopupMenuItem(
                                value: 'print',
                                child: Row(children: [
                                  Icon(Icons.print, size: 16),
                                  SizedBox(width: 8),
                                  Text('Print')
                                ])),
                            const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit')
                                ])),
                            PopupMenuItem(
                                value: 'cancel',
                                child: Row(children: [
                                  Icon(Icons.cancel,
                                      size: 16, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text('Cancel',
                                      style:
                                          TextStyle(color: colorScheme.error))
                                ])),
                          ] else ...[
                            const PopupMenuItem(
                                enabled: false, child: Text('Cancelled')),
                          ]
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customerSearchController,
                  decoration: InputDecoration(
                    labelText: loc.searchCustomerHint,
                    isDense: true,
                    prefixIcon: Icon(Icons.person_search,
                        color: colorScheme.onSurfaceVariant),
                    suffixIcon: selectedCustomerId != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _selectCustomer(null))
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  onChanged: _filterCustomers,
                  onTap: () async {
                    if (selectedCustomerId == null) {
                      // Load initial list if empty
                      if (customerSearchController.text.isEmpty &&
                          filteredCustomers.isEmpty) {
                        context
                            .read<SalesBloc>()
                            .add(const CustomerSearchChanged(' '));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _showAddCustomerDialog,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.person_add),
                ),
              ),
            ],
          ),
          if (showCustomerList)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1), blurRadius: 4)
                ],
              ),
              child: filteredCustomers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(loc.noCustomersFound,
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = filteredCustomers[index];
                        return ListTile(
                          dense: true,
                          title: Text(c.nameEnglish,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.contactPrimary ?? ''),
                          trailing: Text(
                              '${loc.currBal}: ${Money(c.outstandingBalance).toString()}'),
                          onTap: () => _selectCustomer(c),
                          hoverColor:
                              colorScheme.primaryContainer.withOpacity(0.1),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.subtotal,
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14)),
            Text(subtotal.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 14))
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.discount,
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14)),
            SizedBox(
              width: 100,
              height: 32,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  hintText: '0',
                ),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 14),
                onChanged: (_) => setState(() => _calculateTotals()),
              ),
            ),
          ]),
          if (previousBalance > const Money(0))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.prevBalance,
                        style:
                            TextStyle(color: colorScheme.error, fontSize: 14)),
                    Text(previousBalance.toString(),
                        style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 14,
                            fontWeight: FontWeight.bold))
                  ]),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.grandTotal.toUpperCase(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface)),
            Text(grandTotal.toString(),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary))
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : _showCheckoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    loc.checkoutButton.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "F9",
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

class _CartItemRow extends StatefulWidget {
  final CartItem item;
  final int index;
  final bool isRTL;
  final ColorScheme colorScheme;
  final Function(int) onRemove;
  final Function(int, double, Money) onUpdate;

  const _CartItemRow({
    required this.item,
    required this.index,
    required this.isRTL,
    required this.colorScheme,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.item.unitPrice.toRupeesString());
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(_CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.quantity != oldWidget.item.quantity) {
      if (double.tryParse(_qtyCtrl.text) != widget.item.quantity) {
        _qtyCtrl.text = widget.item.quantity.toString();
      }
    }
    if (widget.item.unitPrice != oldWidget.item.unitPrice) {
      if (Money.fromRupeesString(_priceCtrl.text) != widget.item.unitPrice) {
        _priceCtrl.text = widget.item.unitPrice.toRupeesString();
      }
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final double qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
      final Money price = Money.fromRupeesString(_priceCtrl.text);
      widget.onUpdate(widget.index, qty, price);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: widget.index % 2 == 0
          ? widget.colorScheme.surface
          : widget.colorScheme.surfaceVariant.withOpacity(0.2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isRTL && widget.item.nameUrdu.isNotEmpty
                      ? widget.item.nameUrdu
                      : widget.item.nameEnglish,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.itemCode != null)
                  Text(widget.item.itemCode!,
                      style: TextStyle(
                          fontSize: 10,
                          color: widget.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
                hintText: '0',
              ),
              style:
                  TextStyle(fontSize: 13, color: widget.colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              widget.item.total.toString().replaceAll('Rs ', ''),
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: widget.colorScheme.onSurface),
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              icon:
                  Icon(Icons.close, color: widget.colorScheme.error, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.onRemove(widget.index),
            ),
          ),
        ],
      ),
    );
  }
}
