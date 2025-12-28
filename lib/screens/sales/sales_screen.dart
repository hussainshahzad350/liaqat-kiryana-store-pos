// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../core/repositories/sales_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';
import '../../domain/entities/money.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // ========================================
  // REPOSITORY INSTANCES
  // ========================================
  final SalesRepository _salesRepository = SalesRepository();
  final ItemsRepository _itemsRepository = ItemsRepository();
  final CustomersRepository _customersRepository = CustomersRepository();
  final ReceiptRepository _receiptRepository = ReceiptRepository();
  
  // --- Data Variables ---
  List<Product> products = [];
  List<Customer> customers = [];
  List<Map<String, dynamic>> cartItems = []; 
  List<Sale> recentSales = [];

  // --- Search & Filter ---
  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController customerSearchController = TextEditingController();
  
  List<Customer> filteredCustomers = [];
  List<Product> filteredProducts = []; 
  
  bool showCustomerList = false;

  // Debounce Timers
  Timer? _productSearchDebounce;
  Timer? _customerSearchDebounce;

  // --- Selection ---
  int? selectedCustomerId;
  Customer? selectedCustomerMap;

  // --- Totals ---
  Money subtotal = const Money(0);
  Money discount = const Money(0);
  Money grandTotal = const Money(0);
  Money previousBalance = const Money(0);
  final TextEditingController discountController = TextEditingController();

  // --- Settings ---
  bool isSoundOn = true;

  final FocusNode _productSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  @override
  void dispose() {
    productSearchController.dispose();
    customerSearchController.dispose();
    discountController.dispose();
    _productSearchFocusNode.dispose();
    _productSearchDebounce?.cancel();
    _customerSearchDebounce?.cancel();
    for (var item in cartItems) {
      item['priceCtrl']?.dispose();
      item['qtyCtrl']?.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (cartItems.isNotEmpty) {
      final bool? shouldExit = await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.unsavedTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
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

  // ========================================
  // DATA LOADING - USING REPOSITORIES
  // ========================================
  
  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadProducts(),
      _loadCustomers(),
      _loadRecentSales(),
    ]);
  }

  Future<void> _loadProducts() async {
    final result = await _itemsRepository.getAllProducts();
    if (mounted) {
      setState(() {
        products = result;
        filteredProducts = result;
      });
    }
  }

  Future<void> _loadCustomers() async {
    final result = await _customersRepository.getAllCustomers();
    if (mounted) {
      setState(() {
        customers = result;
        filteredCustomers = result;
      });
    }
  }

  Future<void> _loadRecentSales() async {
    if (!mounted) return;
    final result = await _salesRepository.getRecentSales();
    if (mounted) setState(() => recentSales = result);
  }

  // --- Item Search Logic ---
  void _filterProducts(String query) {
    _productSearchDebounce?.cancel();
    _productSearchDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        if (query.isEmpty) {
          filteredProducts = products;
        } else {
          final q = query.toLowerCase();
          filteredProducts = products.where((p) {
            final nameEng = (p.nameEnglish).toLowerCase();
            final itemCode = (p.itemCode ?? '').toLowerCase();
            return nameEng.contains(q) || itemCode.contains(q);
          }).toList();
        }
      });
    });
  }

  // --- Customer Search & Add Logic ---
  void _filterCustomers(String query) {
    _customerSearchDebounce?.cancel();
    
    _customerSearchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        if (query.isEmpty) {
          filteredCustomers = customers;
        } else {
          showCustomerList = true;
          final q = query.toLowerCase();
          filteredCustomers = customers.where((c) {
            final nameEng = (c.nameEnglish).toLowerCase();
            final phone = (c.contactPrimary ?? '').toString();
            return nameEng.contains(q) || phone.contains(q);
          }).toList();
        }
      });
    });
  }

  void _selectCustomer(Customer? customer) {
    setState(() {
      if (customer == null) {
        selectedCustomerId = null;
        selectedCustomerMap = null;
        customerSearchController.clear();
      } else {
        selectedCustomerId = customer.id;
        selectedCustomerMap = customer;
        customerSearchController.text = "${customer.nameEnglish} (${customer.contactPrimary ?? ''})";
      }
      showCustomerList = false;
      _calculateTotals();
    });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.addNewCustomer, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      TextField(controller: nameEngCtrl, decoration: InputDecoration(labelText: loc.nameEnglish)),
                      TextField(controller: nameUrduCtrl, decoration: InputDecoration(labelText: loc.nameUrdu)),
                      TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: loc.phoneNum)),
                      TextField(controller: addressCtrl, decoration: InputDecoration(labelText: loc.address)),
                      TextField(controller: creditLimitCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: loc.creditLimit)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                    onPressed: () async {
                      // Validation 
                      if (nameEngCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.nameRequired)));
                        return;
                      }
                      String phoneNumber = phoneCtrl.text.trim();
                      if (phoneNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.phoneRequired)));
                        return;
                      }

                      try {
                        // Check if phone exists using repository
                        final existingCustomers = await _customersRepository.searchCustomers(phoneNumber);
                        final phoneExists = existingCustomers.any((c) => c.contactPrimary == phoneNumber);

                        if (phoneExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${loc.phoneExists}: "$phoneNumber"'), 
                              backgroundColor: colorScheme.error
                            )
                          );
                          return; 
                        }

                        final newCustomer = Customer(
                          nameEnglish: nameEngCtrl.text.trim(),
                          nameUrdu: nameUrduCtrl.text.trim(),
                          contactPrimary: phoneNumber,
                          address: addressCtrl.text.trim(),
                          creditLimit: CurrencyUtils.toPaisas(creditLimitCtrl.text),
                        );

                        final int id = await _customersRepository.addCustomer(newCustomer);
                        final Customer savedCustomer = newCustomer.copyWith(id: id);

                        if (mounted) {
                          _selectCustomer(savedCustomer);
                          Navigator.of(context).pop();
                          await _loadCustomers();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${loc.customerAdded}: '${nameEngCtrl.text}'"), 
                              backgroundColor: colorScheme.primary
                            )
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e'), backgroundColor: colorScheme.error));
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
    );
  }

  // --- Cart Actions ---
  void _addToCart(Product product, {double quantity = 1.0}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidQuantity)),
      );
      return;
    }

    if (isSoundOn) SystemSound.play(SystemSoundType.click);

    final index = cartItems.indexWhere((item) => item['id'] == product.id);
    final availableStock = (product.currentStock as num).toDouble();

    setState(() {
      if (index != -1) {
        final currentQty = cartItems[index]['quantity'] as double;
        final newQty = currentQty + quantity;

        if (newQty > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.insufficientStock}: ${availableStock.toStringAsFixed(2)} available'),
              backgroundColor: colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        cartItems[index]['quantity'] = newQty;
        cartItems[index]['total'] = (newQty * cartItems[index]['unit_price']).round();
        
        String displayQty = newQty % 1 == 0 ? newQty.toInt().toString() : newQty.toString();
        cartItems[index]['qtyCtrl'].text = displayQty;
        
      } else {
        if (availableStock < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.outOfStock),
              backgroundColor: colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        int price = product.salePrice;
        double qty = quantity;

        final pCtrl = TextEditingController(text: CurrencyUtils.toDecimal(price));
        final qCtrl = TextEditingController(text: qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2));

        cartItems.add({
          'id': product.id,
          'name_urdu': product.nameUrdu,
          'name_english': product.nameEnglish,
          'unit_name': product.unitType,
          'item_code': product.itemCode,
          'current_stock': availableStock,
          'unit_price': price,
          'quantity': qty,
          'total': (price * qty).round(),
          'priceCtrl': pCtrl,
          'qtyCtrl': qCtrl,
        });
      }

      _calculateTotals();
    });
  }

  void _updateCartItemFromField(int index) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final item = cartItems[index];

    String priceText = item['priceCtrl'].text;
    String qtyText = item['qtyCtrl'].text;
    
    int newPrice = CurrencyUtils.toPaisas(priceText);
    double newQty = qtyText.isEmpty ? 0.0 : double.tryParse(qtyText) ?? 0.0;

    if (newPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidPrice),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      item['priceCtrl'].text = CurrencyUtils.toDecimal(item['unit_price']);
      return;
    }

    if (newQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidQuantity),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      item['qtyCtrl'].text = item['quantity'].toStringAsFixed(0);
      return;
    }

    final availableStock = (item['current_stock'] as num).toDouble();
    if (newQty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.insufficientStock}: ${availableStock.toStringAsFixed(0)} available'),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      item['qtyCtrl'].text = availableStock.toStringAsFixed(0);
      newQty = availableStock;
    }

    setState(() {
      cartItems[index]['unit_price'] = newPrice;
      cartItems[index]['quantity'] = newQty;
      cartItems[index]['total'] = (newPrice * newQty).round();
      _calculateTotals();
    });
  }

  void _removeCartItem(int index) {
    if (cartItems.isNotEmpty && index < cartItems.length) {
      cartItems[index]['priceCtrl']?.dispose();
      cartItems[index]['qtyCtrl']?.dispose();
      setState(() {
        cartItems.removeAt(index);
        _calculateTotals();
      });
    }
  }

  void _clearCart() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.clearCartTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
                    onPressed: () {
                      Navigator.pop(context);
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

  void _performClearCart() {
    for (var item in cartItems) {
      item['priceCtrl']?.dispose();
      item['qtyCtrl']?.dispose();
    }
    setState(() {
      cartItems.clear();
      selectedCustomerId = null;
      selectedCustomerMap = null;
      customerSearchController.clear();
      discountController.clear();
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    // 1. Calculate Subtotal
    int subtotalPaisas = cartItems.fold(0, (sum, item) => sum + (item['total'] as int));
    subtotal = Money(subtotalPaisas);
    
    // 2. Parse Discount
    Money discVal = CurrencyUtils.parse(discountController.text);
    if (discVal > subtotal) discVal = subtotal;
    discount = discVal;

    // 3. Calculate Grand Total
    grandTotal = subtotal - discount;
    if (grandTotal < const Money(0)) grandTotal = const Money(0);

    // 4. Previous Balance
    previousBalance = Money(selectedCustomerMap?.outstandingBalance ?? 0);
  }

  // ========================================
  // CHECKOUT DIALOG - USING REPOSITORY
  // ========================================
  
  void _showCheckoutDialog() {
    if (cartItems.isEmpty) return;

    // 1. Walk-in Customer Flow
    if (selectedCustomerId == null) {
      _showCheckoutPaymentDialog();
      return;
    }
    
    // 2. Registered Customer Flow - Check Credit Limit
    Money creditLimit = Money(selectedCustomerMap?.creditLimit ?? 0);
    Money currentBalance = Money(selectedCustomerMap?.outstandingBalance ?? 0);
    final Money potentialBalance = currentBalance + grandTotal;

    if (potentialBalance > creditLimit) {
      _showCreditLimitWarningDialog(
        creditLimit: creditLimit,
        currentBalance: currentBalance,
        billTotal: grandTotal,
        potentialBalance: potentialBalance,
        onContinueAnyway: () => _showCheckoutPaymentDialog(ignoreCreditLimit: true),
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
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error),
                  const SizedBox(width: 10),
                  Text(loc.creditLimitExceeded, style: TextStyle(color: colorScheme.error, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      Text(loc.creditLimitWarningMsg(CurrencyUtils.format(creditLimit)), style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
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
                            _infoRow('${loc.customerCreditLimit}:', CurrencyUtils.format(creditLimit), color: colorScheme.onErrorContainer),
                            _infoRow('${loc.currentBalance}:', CurrencyUtils.format(currentBalance), color: colorScheme.onErrorContainer),
                            _infoRow('${loc.billTotal}:', CurrencyUtils.format(billTotal), color: colorScheme.onErrorContainer),
                            Divider(color: colorScheme.onErrorContainer.withOpacity(0.5)),
                            _infoRow('${loc.totalBalance}:', CurrencyUtils.format(potentialBalance),
                              isBold: true,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${loc.excessAmount}: ${CurrencyUtils.format(potentialBalance - creditLimit)}',
                              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
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
                    child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant)),
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

    int currentLimit = selectedCustomerMap?.creditLimit ?? 0;
    limitCtrl.text = CurrencyUtils.toDecimal(currentLimit);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.increaseCreditLimit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                Text('${loc.current}: ${CurrencyUtils.formatRupees(currentLimit)}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        int newLimit = CurrencyUtils.toPaisas(limitCtrl.text);
                        if (selectedCustomerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidLimit)),
                          );
                          return;
                        }

                        try {
                          await _customersRepository.updateCustomerCreditLimit(
                            selectedCustomerId!,
                            newLimit
                          );

                          setState(() {
                            selectedCustomerMap = selectedCustomerMap!.copyWith(
                              creditLimit: newLimit,
                            );
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${loc.creditLimitUpdated}: ${CurrencyUtils.formatRupees(newLimit)}'),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                            onLimitUpdated(); 
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${loc.error}: $e'), backgroundColor: colorScheme.error),
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Money cash = CurrencyUtils.parse(cashCtrl.text);
            Money bank = CurrencyUtils.parse(bankCtrl.text);
            Money credit = CurrencyUtils.parse(creditCtrl.text);
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
              _processSale(cash.paisas, bank.paisas, credit.paisas, change.paisas);
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
                  onContinueAnyway: () => _showCheckoutPaymentDialog(ignoreCreditLimit: true),
                  onIncreaseLimit: () => _showIncreaseLimitDialog(
                    onLimitUpdated: () => _showCheckoutPaymentDialog(ignoreCreditLimit: true)
                  ),
                );
              } else {
                processSaleAction();
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 800,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(loc.checkoutButton, style: TextStyle(color: colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
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
                              Text('${loc.searchCustomerHint}: ${selectedCustomerMap!.nameEnglish}', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer, 
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: colorScheme.secondary)
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: colorScheme.secondary),
                                    const SizedBox(width: 5),
                                    Text('${loc.prevBalance}: ${CurrencyUtils.format(oldBalance)}', 
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSecondaryContainer)),
                                  ],
                                ),
                              ),
                              const Divider(height: 20),
                            ],

                            _infoRow(loc.billTotal, CurrencyUtils.format(billTotal), isBold: true, size: 18, color: colorScheme.onSurface),
                            const Divider(),
                            
                            const SizedBox(height: 10),
                            Text(loc.paymentLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)),
                            const SizedBox(height: 10),
                            
                            _input(loc.cashInput, cashCtrl, (v) {
                              setDialogState(() {
                                if (isRegistered) {
                                  Money remaining = billTotal - CurrencyUtils.parse(cashCtrl.text) - CurrencyUtils.parse(bankCtrl.text);
                                  creditCtrl.text = remaining > const Money(0) ? CurrencyUtils.toDecimalMoney(remaining) : '0';
                                }
                              });
                            }),

                            _input(loc.bankInput, bankCtrl, (v) {
                              setDialogState(() {
                                if (isRegistered) {
                                  Money remaining = billTotal - CurrencyUtils.parse(cashCtrl.text) - CurrencyUtils.parse(bankCtrl.text);
                                  creditCtrl.text = remaining > const Money(0) ? CurrencyUtils.toDecimalMoney(remaining) : '0';
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(loc.changeDue, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  Text(CurrencyUtils.format(change), 
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold, 
                                      color: change >= const Money(0) ? colorScheme.primary : colorScheme.error
                                    )
                                  ),
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
                          onPressed: isValid ? checkCreditLimitAndProcess : null,
                          child: Text(loc.savePrint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, double size = 14, Color? color}) {
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

  Widget _input(String label, TextEditingController ctrl, Function(String) onChanged, {bool enabled = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurface))),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
              onChanged: onChanged,
            ),
          ),
        ]
      ),
    );
  }

  // ========================================
  // PROCESS SALE - USING REPOSITORY
  // ========================================
  
  Future<void> _processSale(int cash, int bank, int credit, int change) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // 1. STOCK VALIDATION - Using Repository
    final validationResult = await _salesRepository.validateStock(cartItems);
    
    if (!validationResult['valid']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationResult['error'] ?? 'Stock validation failed',
          ),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(loc.processingSale, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );

    final String currentLanguage = Localizations.localeOf(context).languageCode;

    // Prepare sale data
    final Map<String, dynamic> saleData = {
      'customer_id': selectedCustomerId,
      'grand_total_paisas': grandTotal.paisas,
      'discount_paisas': discount.paisas,
      'cash_paisas': cash,
      'bank_paisas': bank,
      'credit_paisas': credit,
      'receipt_language': currentLanguage,
      'items': cartItems.map((item) {
        return {
          'id': item['id'],
          'name_english': item['name_english'],
          'name_urdu': item['name_urdu'],
          'unit_name': item['unit_name'],
          'quantity': item['quantity'],
          'sale_price': item['unit_price'],
          'total': item['total'],
        };
      }).toList(),
    };

    try {
      // Create sale using repository
      await _salesRepository.completeSaleWithSnapshot(saleData);

      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);

      _performClearCart();
      await _refreshAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.saleCompleted), backgroundColor: colorScheme.primary)
        );
      }
    } catch (e) {
      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);

      print('Error processing sale: $e');
      if (mounted) {
        final cleanError = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorProcessingSale(cleanError)),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 4),
          )
        );
      }
    }
  }

  // ========================================
  // RECEIPT & EDIT ACTIONS
  // ========================================

  Future<void> _handlePrintReceipt(Sale sale) async {
    if (sale.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot print cancelled sale')),
      );
      return;
    }

    try {
      // 1. Generate Data
      final receiptData = await _receiptRepository.generateReceiptData(sale);
      
      // 2. Track Print
      await _receiptRepository.trackPrint(sale.id!);

      // 3. Update UI (Print Count)
      await _loadRecentSales();

      // 4. Actual Printing (Placeholder for 80mm Thermal)
      await _receiptRepository.printReceipt(receiptData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt sent to printer (Bill #${sale.billNumber})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  void _handleEditSale(Sale sale) {
    if (sale.status == 'CANCELLED') return;

    // Logic-ready entry point
    // This would navigate to an edit screen or populate the cart with this sale's items
    // linked via original_sale_id.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
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
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.cancelSaleTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

    if (confirm != true) return;

    try {
      // Cancel sale using repository
      await _salesRepository.cancelSale(
        saleId: id,
        cancelledBy: 'Cashier',
        reason: reasonCtrl.text.trim(),
      );

      // Refresh data after cancellation
      await _refreshAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.saleCancelledSuccess),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
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
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f9): CheckoutIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ClearCartIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true): AddCustomerIntent(),
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
            child: Scaffold(
        appBar: AppBar(
          title: Text(loc.posTitle, style: TextStyle(color: colorScheme.onPrimary)), 
          backgroundColor: colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAllData), 
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart), 
          ]
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT PANEL (Products + Search) - 55%
            Expanded(
              flex: 11, 
              child: Column(
                children: [
                  // Item Search
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: [
                      TextField(
                        controller: productSearchController,
                        focusNode: _productSearchFocusNode,
                        decoration: InputDecoration(
                          hintText: loc.searchItemHint, 
                          isDense: true,
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                          filled: true, 
                          fillColor: colorScheme.surfaceVariant
                        ),
                        onChanged: _filterProducts,
                        onTap: () { 
                          if(productSearchController.text.isNotEmpty) {
                            _filterProducts(productSearchController.text); 
                          }
                        },
                      ),
                    ]),
                  ),
                  
                  // Product Grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final int crossAxisCount = (constraints.maxWidth / 140).floor().clamp(3, 10);
                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              color: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                              ),
                              child: InkWell(
                                onTap: () => _addToCart(product),
                                hoverColor: colorScheme.primaryContainer.withOpacity(0.3),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.primary.withOpacity(0.5)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  CurrencyUtils.formatRupees(product.salePrice),
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.nameEnglish,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          if (product.nameUrdu != null && product.nameUrdu!.isNotEmpty)
                                            Text(
                                              product.nameUrdu!,
                                              style: TextStyle(
                                                fontSize: 10,
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
                                      top: 4,
                                      right: 4,
                                      child: Text(
                                        '${product.currentStock}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: (product.currentStock) < 10 
                                              ? colorScheme.error 
                                              : colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Recent Sales
                  const Divider(thickness: 1, height: 1),
                  Container(
                    height: 250, 
                    color: colorScheme.surface,
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
                        color: colorScheme.surfaceVariant.withOpacity(0.5), 
                        width: double.infinity, 
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(loc.recentSales, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: recentSales.length, 
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = recentSales[index];
                            final isCancelled = sale.status == 'CANCELLED';
                            
                            return ListTile(
                              dense: true, 
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              leading: CircleAvatar(
                                radius: 12, 
                                backgroundColor: isCancelled ? colorScheme.errorContainer : colorScheme.primaryContainer, 
                                child: Text(
                                  '${index+1}', 
                                  style: TextStyle(fontSize: 10, color: isCancelled ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer)
                                )
                              ),
                              title: Text(
                                sale.customerName ?? loc.walkInCustomer, 
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: isCancelled ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sale.billNumber, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (isCancelled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        borderRadius: BorderRadius.circular(2)
                                      ),
                                      child: Text(
                                        loc.cancelled,
                                        style: TextStyle(fontSize: 9, color: colorScheme.onError),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Text(
                                    CurrencyUtils.formatRupees(sale.grandTotalPaisas), 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'print') _handlePrintReceipt(sale);
                                      if (value == 'edit') _handleEditSale(sale);
                                      if (value == 'cancel') _cancelSale(sale.id!, sale.billNumber);
                                    },
                                    itemBuilder: (context) => [
                                      if (!isCancelled) ...[
                                        const PopupMenuItem(value: 'print', child: Row(children: [Icon(Icons.print, size: 16), SizedBox(width: 8), Text('Print')])),
                                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                                        PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel, size: 16, color: colorScheme.error), const SizedBox(width: 8), Text('Cancel', style: TextStyle(color: colorScheme.error))])),
                                      ] else ...[
                                        const PopupMenuItem(enabled: false, child: Text('Cancelled')),
                                      ]
                                    ],
                                  )
                                ]
                              ),
                            );
                          },
                        )
                      ),
                    ]),
                  ),
                ]),
              ),

            // Vertical Divider
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),

            // RIGHT PANEL (Customer + Cart + Totals) - 45%
            Expanded(
              flex: 9, 
              child: Container(
                color: colorScheme.surface, 
                child: Column(children: [
                  // Customer Search Panel
                  Container(
                    padding: const EdgeInsets.all(8), 
                    color: colorScheme.surface, 
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: customerSearchController,
                            decoration: InputDecoration(
                              labelText: loc.searchCustomerHint, 
                              isDense: true,
                              prefixIcon: Icon(Icons.person_search, color: colorScheme.onSurfaceVariant), 
                              suffixIcon: selectedCustomerId != null ? IconButton(
                                icon: const Icon(Icons.clear), 
                                onPressed: () => _selectCustomer(null)
                              ) : null, 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                              filled: true,
                              fillColor: colorScheme.surfaceVariant
                            ), 
                            onChanged: _filterCustomers, 
                            onTap: () { 
                              if(selectedCustomerId == null) {
                                setState(() {
                                  if (customerSearchController.text.isEmpty) filteredCustomers = customers;
                                  showCustomerList = true;
                                });
                              }
                            }
                          )
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40, 
                          child: ElevatedButton.icon(
                            onPressed: _showAddCustomerDialog, 
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16), 
                              backgroundColor: colorScheme.primary, 
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ), 
                            icon: const Icon(Icons.person_add),
                            label: const Text("Add"),
                          )
                        ),
                      ]),
                      if (showCustomerList)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          margin: const EdgeInsets.only(top: 5), 
                          decoration: BoxDecoration(
                            color: colorScheme.surface, 
                            border: Border.all(color: colorScheme.outline), 
                            borderRadius: BorderRadius.circular(8), 
                            boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 4)]
                          ), 
                          child: filteredCustomers.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(loc.noCustomersFound, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredCustomers.length, 
                                separatorBuilder: (c, i) => const Divider(height: 1), 
                                itemBuilder: (context, index) { 
                                  final c = filteredCustomers[index]; 
                                  return ListTile(
                                    dense: true, 
                                    title: Text(c.nameEnglish, style: const TextStyle(fontWeight: FontWeight.bold)), 
                                    subtitle: Text(c.contactPrimary ?? ''), 
                                    trailing: Text('${loc.currBal}: ${CurrencyUtils.formatRupees(c.outstandingBalance)}'), 
                                    onTap: () => _selectCustomer(c),
                                    hoverColor: colorScheme.primaryContainer.withOpacity(0.1),
                                  ); 
                                }
                              )
                        ),
                    ]),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  
                  // Cart Header
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant))),
                        SizedBox(width: 70, child: Text(loc.price, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant))),
                        const SizedBox(width: 8),
                        SizedBox(width: 60, child: Text(loc.qty, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant))),
                        const SizedBox(width: 8),
                        SizedBox(width: 70, child: Text('Total', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurfaceVariant))),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),

                  // Cart List
                  Expanded(
                    child: cartItems.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 64, color: colorScheme.outline.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(loc.cartEmpty, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(0),
                          itemCount: cartItems.length, 
                          separatorBuilder: (c, i) => const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 8), 
                              color: index % 2 == 0 ? colorScheme.surface : colorScheme.surfaceVariant.withOpacity(0.3),
                              child: Row(children: [
                                // Item Name
                                Expanded(
                                  flex: 4, 
                                  child: Text(
                                    isRTL && item['name_urdu'] != null ? item['name_urdu'] : item['name_english'], 
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.w500), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  )
                                ),
                                
                                // Price Box
                                SizedBox(
                                  width: 70, 
                                  child: TextField( 
                                    controller: item['priceCtrl'],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      isDense: true, 
                                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      border: InputBorder.none,
                                      hintText: '0',
                                    ),
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface), 
                                    onChanged: (_) => _updateCartItemFromField(index),
                                  )
                                ),
                                const SizedBox(width: 8),
                                
                                // Qty Box
                                SizedBox(
                                  width: 60, 
                                  child: TextField( 
                                    controller: item['qtyCtrl'],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      isDense: true, 
                                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      border: OutlineInputBorder(), 
                                    ),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface), 
                                    onChanged: (_) => _updateCartItemFromField(index),
                                  )
                                ),
                                const SizedBox(width: 8),
                                
                                // Total
                                SizedBox(
                                  width: 70, 
                                  child: Text(
                                    CurrencyUtils.formatRupees(item['total'] as int).replaceAll('Rs ', ''), 
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)
                                  )
                                ),
                                
                                // Delete Button
                                SizedBox(
                                  width: 32,
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: colorScheme.error, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _removeCartItem(index), 
                                  ),
                                ), 
                              ]),
                            );
                          },
                        )
                  ),
                  
                  Divider(height: 1, color: colorScheme.outlineVariant),

                  // Totals Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.subtotal, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)), 
                          Text(CurrencyUtils.format(subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 14))
                        ]
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.discount, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)), 
                          SizedBox(
                            width: 90,
                            height: 30,
                            child: TextField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                border: UnderlineInputBorder(),
                                hintText: '0',
                              ),
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 14),
                              onChanged: (_) => setState(() => _calculateTotals()),
                            ),
                          ),
                        ]
                      ),
                      if (previousBalance > const Money(0)) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Text(loc.prevBalance, style: TextStyle(color: colorScheme.error, fontSize: 14)), 
                              Text(CurrencyUtils.format(previousBalance), style: TextStyle(color: colorScheme.error, fontSize: 14, fontWeight: FontWeight.bold))
                            ]
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.grandTotal.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)), 
                          Text(
                            CurrencyUtils.format(grandTotal), 
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.primary)
                          )
                        ]
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, 
                        height: 48, 
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : _showCheckoutDialog, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ), 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                loc.checkoutButton.toUpperCase(), 
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: colorScheme.onPrimary,
                                  letterSpacing: 1.0,
                                )
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          )
                        )
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
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