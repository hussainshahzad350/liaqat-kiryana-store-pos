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

  void _loadRecentInvoices() {
    _refreshAllData();
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
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: DesktopDimensions.dialogWidth * 1.5,
            ),
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.unsavedTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                Text(loc.unsavedMsg,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingMedium),
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

    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: DesktopDimensions.dialogWidth * 1.5,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.addNewCustomer,
                      style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: nameEngCtrl,
                          decoration:
                              InputDecoration(labelText: loc.nameEnglish)),
                      const SizedBox(height: DesktopDimensions.spacingMedium),
                      TextField(
                          controller: nameUrduCtrl,
                          decoration: InputDecoration(labelText: loc.nameUrdu)),
                      const SizedBox(height: DesktopDimensions.spacingMedium),
                      TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: loc.phoneNum)),
                      const SizedBox(height: DesktopDimensions.spacingMedium),
                      TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(labelText: loc.address)),
                      const SizedBox(height: DesktopDimensions.spacingMedium),
                      TextField(
                          controller: creditLimitCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: loc.creditLimit)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.cancel)),
                  const SizedBox(width: DesktopDimensions.spacingMedium),
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
                        final creditLimit =
                            Money.fromRupeesString(creditLimitCtrl.text);

                        context.read<SalesBloc>().add(
                              QuickCustomerAddRequested(
                                nameEnglish: nameEngCtrl.text.trim(),
                                nameUrdu: nameUrduCtrl.text.trim(),
                                phone: phoneNumber,
                                address: addressCtrl.text.trim(),
                                creditLimitPaisas: creditLimit.paisas,
                              ),
                            );
                        Navigator.of(context).pop();
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(loc.invalidAmount),
                            backgroundColor: colorScheme.error));
                        return;
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
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: DesktopDimensions.dialogWidth * 1.5,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.clearCartTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Text(loc.clearCartMsg,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: DesktopDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: DesktopDimensions.spacingMedium),
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
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: DesktopDimensions.dialogWidth * 1.5,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error),
                  const SizedBox(width: DesktopDimensions.spacingSmall),
                  Text(
                    loc.creditLimitExceeded,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.creditLimitWarningMsg(creditLimit.toString()),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: DesktopDimensions.spacingLarge),
                      Container(
                        padding:
                            const EdgeInsets.all(DesktopDimensions.cardPadding),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius),
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
                            const SizedBox(
                                height: DesktopDimensions.spacingSmall),
                            Text(
                              '${loc.excessAmount}: ${(potentialBalance - creditLimit).toString()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: DesktopDimensions.spacingMedium),
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
                  const SizedBox(width: DesktopDimensions.spacingMedium),
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
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
          child: Container(
            constraints: BoxConstraints(
              minWidth: DesktopDimensions.dialogWidth,
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.increaseCreditLimit,
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                Text(
                  '${loc.current}: ${currentLimit.toString()}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                TextField(
                  controller: limitCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.newCreditLimit,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingMedium),
                    ElevatedButton(
                      onPressed: () async {
                        Money newLimit;
                        // Check if dialog is still mounted before async operations
                        final dialogMounted =
                            dialogContext.findRenderObject() != null;
                        if (!dialogMounted) return;
                        try {
                          newLimit = Money.fromRupeesString(limitCtrl.text);
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidLimit)),
                          );
                          return;
                        }
                        if (selectedCustomerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidLimit)),
                          );
                          return;
                        }

                        // Capture localized strings before async call
                        final successLabel = loc.creditLimitUpdated;
                        final errorLabel = loc.error;
                        final newLimitStr = newLimit.toString();

                        try {
                          salesBloc.add(
                            CustomerCreditLimitUpdateRequested(
                              customerId: selectedCustomerId!,
                              newLimitPaisas: newLimit.paisas,
                            ),
                          );

                          final updateResult =
                              await salesBloc.stream.firstWhere(
                            (state) =>
                                state.creditLimitUpdateCustomerId ==
                                    selectedCustomerId &&
                                (state.creditLimitUpdateStatus ==
                                        CreditLimitUpdateStatus.success ||
                                    state.creditLimitUpdateStatus ==
                                        CreditLimitUpdateStatus.error),
                          );

                          if (!mounted) return;

                          final successMsg = '$successLabel: $newLimitStr';
                          final errorMsg = updateResult
                                      .creditLimitUpdateError ==
                                  null
                              ? errorLabel
                              : '$errorLabel: ${updateResult.creditLimitUpdateError}';

                          if (updateResult.creditLimitUpdateStatus ==
                              CreditLimitUpdateStatus.success) {
                            salesBloc.add(CustomerSelected(selectedCustomerMap!
                                .copyWith(creditLimit: newLimit.paisas)));

                            if (dialogContext.mounted &&
                                Navigator.of(dialogContext).canPop()) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(successMsg),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            }
                            onLimitUpdated();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('$errorLabel: $e'),
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
    ).whenComplete(limitCtrl.dispose);
  }

  void _showCheckoutPaymentDialog({bool ignoreCreditLimit = false}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    Money billTotal = grandTotal;
    Money oldBalance = previousBalance;

    final isWalkInCustomer =
        selectedCustomerMap == null || selectedCustomerMap!.id == 1;

    final cashCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final creditCtrl = TextEditingController();

    if (!isWalkInCustomer) {
      creditCtrl.text = '0';
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            final parsedCash = _tryParseMoney(cashCtrl.text);
            final parsedBank = _tryParseMoney(bankCtrl.text);
            final parsedCredit = _tryParseMoney(creditCtrl.text);
            final cashError = parsedCash == null ? loc.invalidAmount : null;
            final bankError = parsedBank == null ? loc.invalidAmount : null;
            final creditError = parsedCredit == null ? loc.invalidAmount : null;
            final hasParseError = cashError != null ||
                bankError != null ||
                (!isWalkInCustomer && creditError != null);

            final Money cash = parsedCash ?? Money.zero;
            final Money bank = parsedBank ?? Money.zero;
            final Money credit = parsedCredit ?? Money.zero;
            Money totalPayment = cash + bank + credit;
            Money change = const Money(0);
            bool isValid = false;

            if (hasParseError) {
              isValid = false;
            } else if (!isWalkInCustomer) {
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
              if (hasParseError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.invalidAmount),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }

              if (ignoreCreditLimit) {
                processSaleAction();
                return;
              }

              if (isWalkInCustomer || credit <= const Money(0)) {
                processSaleAction();
                return;
              }

              final selectedCustomer = selectedCustomerMap;
              if (selectedCustomer == null) {
                processSaleAction();
                return;
              }
              final Money creditLimit = Money(selectedCustomer.creditLimit);
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
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.cardBorderRadius)),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: DesktopDimensions.dialogWidth * 1.5,
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: colorScheme.primary),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        Text(loc.checkoutButton,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: colorScheme.primary,
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
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isWalkInCustomer) ...[
                              Text(
                                  '${loc.searchCustomerHint}: ${selectedCustomerMap!.nameEnglish}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(
                                  height: DesktopDimensions.spacingSmall),
                              Container(
                                padding: const EdgeInsets.all(
                                    DesktopDimensions.spacingSmall),
                                decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(
                                        DesktopDimensions.smallBorderRadius),
                                    border: Border.all(
                                        color: colorScheme.secondary)),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: DesktopDimensions.iconSizeSmall,
                                        color: colorScheme.secondary),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text(
                                        '${loc.prevBalance}: ${oldBalance.toString()}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                                color: colorScheme
                                                    .onSecondaryContainer)),
                                  ],
                                ),
                              ),
                              const Divider(
                                  height: DesktopDimensions.spacingLarge),
                            ],
                            _infoRow(loc.billTotal, billTotal.toString(),
                                isBold: true,
                                size: DesktopDimensions.headingSize,
                                color: colorScheme.onSurface),
                            const Divider(),
                            const SizedBox(
                                height: DesktopDimensions.spacingStandard),
                            Text(loc.paymentLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(
                                height: DesktopDimensions.spacingStandard),
                            _input(loc.cashInput, cashCtrl, (v) {
                              setDialogState(() {
                                if (!isWalkInCustomer) {
                                  Money cash = safeMoney(cashCtrl.text);
                                  Money bank = safeMoney(bankCtrl.text);
                                  Money remaining = billTotal - cash - bank;
                                  creditCtrl.text = remaining > const Money(0)
                                      ? remaining.toRupeesString()
                                      : '0';
                                }
                              });
                            }, errorText: cashError),
                            _input(loc.bankInput, bankCtrl, (v) {
                              setDialogState(() {
                                if (!isWalkInCustomer) {
                                  Money cash = safeMoney(cashCtrl.text);
                                  Money bank = safeMoney(bankCtrl.text);
                                  Money remaining = billTotal - cash - bank;
                                  creditCtrl.text = remaining > const Money(0)
                                      ? remaining.toRupeesString()
                                      : '0';
                                }
                              });
                            }, errorText: bankError),
                            if (!isWalkInCustomer)
                              _input(loc.creditInput, creditCtrl, (v) {
                                setDialogState(() {});
                              }, errorText: creditError),
                            const SizedBox(
                                height: DesktopDimensions.spacingStandard),
                            if (isWalkInCustomer)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(loc.changeDue,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(change.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
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
                    const SizedBox(height: DesktopDimensions.spacingLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(loc.cancel),
                        ),
                        const SizedBox(width: DesktopDimensions.spacingMedium),
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
        }).whenComplete(() {
      cashCtrl.dispose();
      bankCtrl.dispose();
      creditCtrl.dispose();
    });
  }

  Widget _infoRow(String label, String value,
      {bool isBold = false, double? size, Color? color}) {
    final textTheme = Theme.of(context).textTheme;
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    TextStyle? baseStyle;
    if (size == null) {
      baseStyle = textTheme.bodyMedium;
    } else if (size >= DesktopDimensions.headingSize) {
      baseStyle = textTheme.titleMedium;
    } else if (size >= DesktopDimensions.bodyLargeSize) {
      baseStyle = textTheme.bodyLarge;
    } else {
      baseStyle = textTheme.bodyMedium;
    }

    final finalStyle = baseStyle?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? defaultColor,
      fontSize: size,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: DesktopDimensions.spacingXXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: finalStyle),
          Text(value, style: finalStyle),
        ],
      ),
    );
  }

  Money? _tryParseMoney(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return Money.zero;
    final validPattern = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!validPattern.hasMatch(normalized)) {
      return null;
    }
    return Money.fromRupeesString(normalized);
  }

  /// Safe money parser that returns Money(0) for invalid input
  Money safeMoney(String text) {
    return _tryParseMoney(text) ?? Money.zero;
  }

  Widget _input(
      String label, TextEditingController ctrl, Function(String) onChanged,
      {bool enabled = true, String? errorText}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopDimensions.spacingStandard),
      child: Row(children: [
        SizedBox(
            width: DesktopDimensions.labelWidthStandard,
            child: Text(label, style: textTheme.bodyLarge)),
        Expanded(
          child: SizedBox(
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: ctrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingStandard),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.formFieldBorderRadius)),
                prefixText: 'Rs ',
                filled: !enabled,
                fillColor: enabled ? null : colorScheme.surfaceVariant,
                errorText: errorText,
              ),
              style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant),
              onChanged: onChanged,
            ),
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
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
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
                Text('${loc.bill} #${invoice.invoiceNumber}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: DesktopDimensions.spacingXLarge),
                SizedBox(
                  width: double.infinity,
                  height: DesktopDimensions.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePrintReceipt(invoice),
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

                      if (invoice.status == 'CANCELLED') {
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
                        final path =
                            await _receiptRepository.saveReceiptAsPDF(invoice);
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
      ),
    );
  }

  // ========================================
  // RECEIPT & EDIT ACTIONS
  // ========================================

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
      _loadRecentInvoices();
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
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
        child: Container(
          constraints: BoxConstraints(
            minWidth: DesktopDimensions.dialogWidth * 1.5,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.cancelSaleTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Text(loc.cancelSaleMessage,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: loc.cancelReasonLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: DesktopDimensions.spacingMedium),
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

    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();

    if (confirm != true) {
      return;
    }

    if (mounted) {
      context.read<SalesBloc>().add(InvoiceCancelled(
            invoiceId: id,
            reason: reason,
          ));
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
                        ),
                      ],
                    ),
                    if (state.status == SalesStatus.loading)
                      _buildLoadingOverlay(loc, colorScheme),
                  ],
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
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: DesktopDimensions.cardElevation,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius),
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
              padding: const EdgeInsets.all(DesktopDimensions.spacingSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: DesktopDimensions.iconSizeSmall,
                          color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: DesktopDimensions.spacingXSmall),
                      Flexible(
                        child: Text(
                          product.salePrice.formatted,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesktopDimensions.spacingXSmall),
                  Text(
                    product.nameEnglish,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (product.nameUrdu != null && product.nameUrdu!.isNotEmpty)
                    Text(
                      product.nameUrdu!,
                      style: textTheme.bodySmall?.copyWith(
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
              top: DesktopDimensions.spacingXSmall,
              right: DesktopDimensions.spacingXSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingXSmall,
                    vertical: DesktopDimensions.spacingXXSmall),
                decoration: BoxDecoration(
                  color: (product.currentStock) < 10
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.smallBorderRadius),
                ),
                child: Text(
                  '${product.currentStock}',
                  style: textTheme.labelSmall?.copyWith(
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
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: DesktopDimensions.cardElevation,
      margin: const EdgeInsets.only(top: DesktopDimensions.spacingMedium),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesktopDimensions.spacingStandard,
                  vertical: DesktopDimensions.spacingSmall),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesktopDimensions.cardBorderRadius),
                  topRight: Radius.circular(DesktopDimensions.cardBorderRadius),
                ),
              ),
              width: double.infinity,
              child: Text(loc.recentSales,
                  style: textTheme.titleSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: recentInvoices.length,
                separatorBuilder: (c, i) =>
                    const Divider(height: DesktopDimensions.dividerThickness),
                itemBuilder: (context, index) {
                  final invoice = recentInvoices[index];
                  final isCancelled = invoice.status == 'CANCELLED';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingStandard),
                    leading: CircleAvatar(
                      radius: DesktopDimensions.iconSizeSmall,
                      backgroundColor: isCancelled
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      child: Text('${index + 1}',
                          style: textTheme.labelSmall?.copyWith(
                              color: isCancelled
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer)),
                    ),
                    title: Text(
                      invoice.customerName ?? loc.walkInCustomer,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(invoice.invoiceNumber,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Money(invoice.totalAmount).formatted,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              size: DesktopDimensions.iconSizeMedium,
                              color: colorScheme.onSurfaceVariant),
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
                              PopupMenuItem(
                                  value: 'print',
                                  child: Row(children: [
                                    const Icon(Icons.print,
                                        size: DesktopDimensions.iconSizeSmall),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text('Print', style: textTheme.bodyMedium)
                                  ])),
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    const Icon(Icons.edit,
                                        size: DesktopDimensions.iconSizeSmall),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text('Edit', style: textTheme.bodyMedium)
                                  ])),
                              PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(children: [
                                    Icon(Icons.cancel,
                                        size: DesktopDimensions.iconSizeSmall,
                                        color: colorScheme.error),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text('Cancel',
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.error))
                                  ])),
                            ] else ...[
                              PopupMenuItem(
                                  enabled: false,
                                  child: Text('Cancelled',
                                      style: textTheme.bodyMedium)),
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
      ),
    );
  }

  Widget _buildCustomerSection(AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      elevation: DesktopDimensions.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
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
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius / 2)),
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
                const SizedBox(width: DesktopDimensions.spacingSmall),
                SizedBox(
                  height: DesktopDimensions.buttonHeight,
                  width: DesktopDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _showAddCustomerDialog,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.buttonBorderRadius)),
                    ),
                    child: const Icon(Icons.person_add),
                  ),
                ),
              ],
            ),
            if (showCustomerList)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin:
                    const EdgeInsets.only(top: DesktopDimensions.spacingXSmall),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.buttonBorderRadius),
                  boxShadow: [
                    BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: DesktopDimensions.spacingXSmall)
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildTotalsSection(AppLocalizations loc, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: DesktopDimensions.spacingSmall,
          )
        ],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.subtotal, style: textTheme.bodyLarge),
            Text(subtotal.toString(),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ))
          ]),
          const SizedBox(height: DesktopDimensions.spacingStandard),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.discount, style: textTheme.bodyLarge),
            SizedBox(
              width: 120,
              height: DesktopDimensions.buttonHeight,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: DesktopDimensions.spacingStandard,
                      horizontal: DesktopDimensions.spacingStandard),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.buttonBorderRadius)),
                  hintText: '0',
                ),
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                onChanged: (_) => setState(() => _calculateTotals()),
              ),
            ),
          ]),
          if (previousBalance > const Money(0))
            Padding(
              padding:
                  const EdgeInsets.only(top: DesktopDimensions.spacingStandard),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.prevBalance,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colorScheme.error)),
                    Text(previousBalance.toString(),
                        style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold))
                  ]),
            ),
          const SizedBox(height: DesktopDimensions.spacingStandard),
          const Divider(),
          const SizedBox(height: DesktopDimensions.spacingStandard),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.grandTotal.toUpperCase(),
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(grandTotal.toString(),
                style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900, color: colorScheme.primary))
          ]),
          const SizedBox(height: DesktopDimensions.spacingMedium),
          SizedBox(
            width: double.infinity,
            height: DesktopDimensions.buttonHeight * 1.4,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : _showCheckoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: DesktopDimensions.cardElevation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment,
                      size: DesktopDimensions.iconSizeXLarge),
                  const SizedBox(width: DesktopDimensions.spacingStandard),
                  Text(
                    loc.checkoutButton.toUpperCase(),
                    style: textTheme.titleLarge
                        ?.copyWith(color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: DesktopDimensions.spacingStandard),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingSmall,
                        vertical: DesktopDimensions.spacingXSmall),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.smallBorderRadius),
                    ),
                    child: Text(
                      "F9",
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onPrimary),
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
      Money currentPrice;
      try {
        currentPrice = Money.fromRupeesString(_priceCtrl.text);
      } catch (_) {
        currentPrice = Money.zero;
      }
      if (currentPrice != widget.item.unitPrice) {
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
      Money price;
      try {
        price = Money.fromRupeesString(_priceCtrl.text);
      } catch (_) {
        price = Money.zero;
      }
      widget.onUpdate(widget.index, qty, price);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingStandard,
          vertical: DesktopDimensions.spacingSmall),
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
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.itemCode != null)
                  Text(widget.item.itemCode!,
                      style: textTheme.labelSmall?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: DesktopDimensions.spacingSmall,
                    horizontal: DesktopDimensions.spacingXSmall),
                border: InputBorder.none,
                hintText: '0',
              ),
              style: textTheme.bodyMedium,
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingSmall),
          SizedBox(
            width: 70,
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: DesktopDimensions.spacingSmall,
                    horizontal: DesktopDimensions.spacingXSmall),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.formFieldBorderRadius)),
              ),
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingSmall),
          SizedBox(
            width: 80,
            child: Text(
              widget.item.total.toString().replaceAll('Rs ', ''),
              textAlign: TextAlign.end,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: DesktopDimensions.iconSizeXLarge,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: widget.colorScheme.error,
                  size: DesktopDimensions.iconSizeMedium),
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
