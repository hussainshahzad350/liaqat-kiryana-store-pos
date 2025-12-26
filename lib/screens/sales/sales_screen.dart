// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../core/repositories/sales_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';

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
  double subtotal = 0.0;
  double grandTotal = 0.0;
  double previousBalance = 0.0;

  // --- Settings ---
  bool isSoundOn = true;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  @override
  void dispose() {
    productSearchController.dispose();
    customerSearchController.dispose();
    _productSearchDebounce?.cancel();
    _customerSearchDebounce?.cancel();
    for (var item in cartItems) {
      item['priceCtrl']?.dispose();
      item['qtyCtrl']?.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecentSales();
  }

  // --- WillPopScope for back button warning ---
  Future<bool> _onWillPop() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (cartItems.isNotEmpty) {
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
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.exit, style: TextStyle(color: colorScheme.error)),
            ),
          ],
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
      builder: (context) => AlertDialog(
        title: Text(loc.addNewCustomer),
        content: SingleChildScrollView(
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
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
                  creditLimit: (int.tryParse(creditLimitCtrl.text) ?? 0) * 100,
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
        cartItems[index]['total'] = newQty * cartItems[index]['unit_price'];
        
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

        double price = (product.salePrice) / 100.0;
        double qty = quantity;

        String displayPrice = price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
        String displayQty = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2);

        final pCtrl = TextEditingController(text: displayPrice);
        final qCtrl = TextEditingController(text: displayQty);

        cartItems.add({
          'id': product.id,
          'name_urdu': product.nameUrdu,
          'name_english': product.nameEnglish,
          'current_stock': availableStock,
          'unit_price': price,
          'quantity': qty,
          'total': price * qty,
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
    
    double newPrice = priceText.isEmpty ? 0.0 : double.tryParse(priceText) ?? 0.0;
    double newQty = qtyText.isEmpty ? 0.0 : double.tryParse(qtyText) ?? 0.0;

    if (newPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidPrice),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      item['priceCtrl'].text = item['unit_price'].toStringAsFixed(0);
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
      cartItems[index]['total'] = newPrice * newQty;
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
      builder: (context) => AlertDialog(
        title: Text(loc.clearCartTitle),
        content: Text(loc.clearCartMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCart();
            },
            child: Text(loc.clearAll, style: TextStyle(color: colorScheme.error)),
          ),
        ],
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
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    subtotal = cartItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
    grandTotal = subtotal;
    previousBalance = (selectedCustomerMap?.outstandingBalance ?? 0) / 100.0;
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
    double creditLimit = (selectedCustomerMap?.creditLimit ?? 0) / 100.0;
    double currentBalance = (selectedCustomerMap?.outstandingBalance ?? 0) / 100.0;
    final double potentialBalance = currentBalance + grandTotal;

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
    required double creditLimit,
    required double currentBalance,
    required double billTotal,
    required double potentialBalance,
    required Function() onContinueAnyway,
    required Function() onIncreaseLimit,
  }) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.error),
            const SizedBox(width: 10),
            Text(loc.creditLimitExceeded, style: TextStyle(color: colorScheme.error)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.creditLimitWarningMsg(creditLimit.toStringAsFixed(0)), style: TextStyle(color: colorScheme.onSurface)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('${loc.customerCreditLimit}:', 'Rs ${creditLimit.toStringAsFixed(0)}', color: colorScheme.onErrorContainer),
                    _infoRow('${loc.currentBalance}:', 'Rs ${currentBalance.toStringAsFixed(0)}', color: colorScheme.onErrorContainer),
                    _infoRow('${loc.billTotal}:', 'Rs ${billTotal.toStringAsFixed(0)}', color: colorScheme.onErrorContainer),
                    Divider(color: colorScheme.onErrorContainer.withOpacity(0.5)),
                    _infoRow('${loc.totalBalance}:', 'Rs ${potentialBalance.toStringAsFixed(0)}',
                      isBold: true,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${loc.excessAmount}: Rs ${(potentialBalance - creditLimit).toStringAsFixed(0)}',
                      style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
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
    );
  }

  void _showIncreaseLimitDialog({required VoidCallback onLimitUpdated}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final limitCtrl = TextEditingController();

    double currentLimit = (selectedCustomerMap?.creditLimit ?? 0).toDouble();
    currentLimit = currentLimit / 100.0;
    limitCtrl.text = currentLimit.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.increaseCreditLimit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${loc.current}: ${currentLimit.toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.newCreditLimit,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                double? newLimit = double.tryParse(limitCtrl.text);
                if (newLimit == null || selectedCustomerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.invalidLimit)),
                  );
                  return;
                }

                try {
                  await _customersRepository.updateCustomerCreditLimit(
                    selectedCustomerId!,
                    newLimit * 100
                  );

                  setState(() {
                    selectedCustomerMap = selectedCustomerMap!.copyWith(
                      creditLimit: (newLimit * 100).toInt(),
                    );
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${loc.creditLimitUpdated}: Rs ${newLimit.toStringAsFixed(0)}'),
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
        );
      },
    );
  }

  void _showCheckoutPaymentDialog({bool ignoreCreditLimit = false}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    bool isRegistered = selectedCustomerId != null;
    double billTotal = grandTotal;
    double oldBalance = previousBalance;

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
            double cash = double.tryParse(cashCtrl.text) ?? 0.0;
            double bank = double.tryParse(bankCtrl.text) ?? 0.0;
            double credit = double.tryParse(creditCtrl.text) ?? 0.0;
            double totalPayment = cash + bank + credit;
            double change = 0.0;
            bool isValid = false;

            if (isRegistered) {
              isValid = (totalPayment - billTotal).abs() < 0.01;
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

              if (!isRegistered || credit <= 0) {
                processSaleAction();
                return;
              }

              final creditLimit = selectedCustomerMap!.creditLimit.toDouble();
              final potentialBalance = oldBalance + credit;

              if (potentialBalance > creditLimit / 100.0) {
                Navigator.pop(context);
                _showCreditLimitWarningDialog(
                  creditLimit: creditLimit / 100.0,
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

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Container(
                color: colorScheme.primary,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: colorScheme.onPrimary),
                    const SizedBox(width: 10),
                    Text(loc.checkoutButton, style: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
              ),
              titlePadding: EdgeInsets.zero,
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                              Text('${loc.prevBalance}: Rs ${oldBalance.toStringAsFixed(0)}', 
                                style: TextStyle(fontSize: 13, color: colorScheme.onSecondaryContainer)),
                            ],
                          ),
                        ),
                        const Divider(height: 20),
                      ],

                      _infoRow(loc.billTotal, 'Rs ${billTotal.toStringAsFixed(0)}', isBold: true, size: 18, color: colorScheme.onSurface),
                      const Divider(),
                      
                      const SizedBox(height: 10),
                      Text(loc.paymentLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)),
                      const SizedBox(height: 10),
                      
                      _input(loc.cashInput, cashCtrl, (v) {
                        setDialogState(() {
                          if (isRegistered) {
                            double remaining = billTotal - (double.tryParse(cashCtrl.text) ?? 0.0) - (double.tryParse(bankCtrl.text) ?? 0.0);
                            creditCtrl.text = remaining > 0 ? remaining.toStringAsFixed(0) : '0';
                          }
                        });
                      }),

                      _input(loc.bankInput, bankCtrl, (v) {
                        setDialogState(() {
                          if (isRegistered) {
                            double remaining = billTotal - (double.tryParse(cashCtrl.text) ?? 0.0) - (double.tryParse(bankCtrl.text) ?? 0.0);
                            creditCtrl.text = remaining > 0 ? remaining.toStringAsFixed(0) : '0';
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
                            Text('Rs ${change.toStringAsFixed(0)}', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: change >= 0 ? colorScheme.primary : colorScheme.error
                              )
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: isValid ? checkCreditLimitAndProcess : null,
                  child: Text(loc.savePrint),
                ),
              ],
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
  
  Future<void> _processSale(double cash, double bank, double credit, double change) async {
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
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(loc.processingSale),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Prepare sale data
    final Map<String, dynamic> saleData = {
      'customer_id': selectedCustomerId,
      'grand_total': (grandTotal * 100).round(),
      'discount': 0.0,
      'cash_amount': (cash * 100).round(),
      'bank_amount': (bank * 100).round(),
      'credit_amount': (credit * 100).round(),
      'items': cartItems.map((item) {
        return {
          'id': item['id'],
          'quantity': item['quantity'],
          'sale_price': (item['unit_price'] * 100).round(),
          'total': (item['total'] * 100).round(),
        };
      }).toList(),
    };

    try {
      // Create sale using repository
      await _salesRepository.createSale(saleData);

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
  // CANCEL SALE - USING REPOSITORY
  // ========================================
  
  Future<void> _cancelSale(int id, String billNumber) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(loc.cancelSaleTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.cancelSaleMessage),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: loc.cancelReasonLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(loc.cancel),
          ),
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

    return WillPopScope(
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(children: [
                      TextField(
                        controller: productSearchController,
                        decoration: InputDecoration(
                          hintText: loc.searchItemHint, 
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
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
                                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
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
                    height: 180, 
                    color: colorScheme.surface,
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
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
                            return ListTile(
                              dense: true, 
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              leading: CircleAvatar(
                                radius: 12, 
                                backgroundColor: colorScheme.primaryContainer, 
                                child: Text('${index+1}', style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer))
                              ),
                              title: Text(sale.customerName ?? loc.walkInCustomer, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                              subtitle: Row(
                                children: [
                                  Text(sale.billNumber, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(width: 8),
                                  Text(
                                    sale.status == 'CANCELLED' ? loc.cancelled : loc.completed,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: sale.status == 'CANCELLED' ? colorScheme.error : colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Text(CurrencyUtils.formatRupees(sale.grandTotal.toInt()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)),
                                  if (sale.status != 'CANCELLED')
                                    IconButton(
                                      icon: Icon(Icons.cancel, size: 16, color: colorScheme.error), 
                                      onPressed: () => _cancelSale(sale.id!, sale.billNumber),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
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
                    padding: const EdgeInsets.all(12), 
                    color: colorScheme.surface, 
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: customerSearchController,
                            decoration: InputDecoration(
                              labelText: loc.searchCustomerHint, 
                              prefixIcon: Icon(Icons.person_search, color: colorScheme.onSurfaceVariant), 
                              suffixIcon: selectedCustomerId != null ? IconButton(
                                icon: const Icon(Icons.clear), 
                                onPressed: () => _selectCustomer(null)
                              ) : null, 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                              isDense: true,
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
                          height: 48, 
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
                                    trailing: Text('${loc.currBal}: ${c.outstandingBalance}'), 
                                    onTap: () => _selectCustomer(c),
                                    hoverColor: colorScheme.primaryContainer.withOpacity(0.1),
                                  ); 
                                }
                              )
                        ),
                    ]),
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
                          separatorBuilder: (c, i) => Divider(height: 1, color: colorScheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                              color: index % 2 == 0 ? colorScheme.surface : colorScheme.surfaceVariant.withOpacity(0.3),
                              child: Row(children: [
                                // Item Name
                                Expanded(
                                  flex: 4, 
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRTL && item['name_urdu'] != null ? item['name_urdu'] : item['name_english'], 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface), 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis
                                      ), 
                                      Text(
                                        '${loc.stock}: ${item['current_stock']}', 
                                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)
                                      ),
                                    ]
                                  )
                                ),
                                
                                // Price Box
                                SizedBox(
                                  width: 80, 
                                  child: TextField( 
                                    controller: item['priceCtrl'],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true, 
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), 
                                      border: const OutlineInputBorder(), 
                                      labelText: loc.price, 
                                      labelStyle: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)
                                    ),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface), 
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
                                    decoration: InputDecoration(
                                      isDense: true, 
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), 
                                      border: const OutlineInputBorder(), 
                                      labelText: loc.qty, 
                                      labelStyle: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)
                                    ),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface), 
                                    onChanged: (_) => _updateCartItemFromField(index),
                                  )
                                ),
                                const SizedBox(width: 12),
                                
                                // Total
                                SizedBox(
                                  width: 80, 
                                  child: Text(
                                    (item['total'] as double).toStringAsFixed(0), 
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)
                                  )
                                ),
                                
                                // Delete Button
                                InkWell(
                                  onTap: () => _removeCartItem(index), 
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0), 
                                    child: Icon(Icons.close, color: colorScheme.error, size: 20)
                                  )
                                ), 
                              ]),
                            );
                          },
                        )
                  ),
                  
                  Divider(height: 1, color: colorScheme.outlineVariant),

                  // Totals Section
                  Container(
                    padding: const EdgeInsets.all(16), 
                    color: colorScheme.surface, 
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.totalItems, style: TextStyle(color: colorScheme.onSurfaceVariant)), 
                          Text('${cartItems.length}', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))
                        ]
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.subtotal, style: TextStyle(color: colorScheme.onSurfaceVariant)), 
                          Text('Rs ${subtotal.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))
                        ]
                      ),
                      if (previousBalance > 0) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Text(loc.prevBalance, style: TextStyle(color: colorScheme.error, fontSize: 13)), 
                              Text('Rs ${previousBalance.toStringAsFixed(0)}', style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold))
                            ]
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(loc.grandTotal, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)), 
                          Text(
                            'Rs ${grandTotal.toStringAsFixed(0)}', 
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)
                          )
                        ]
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, 
                        height: 50, 
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : _showCheckoutDialog, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ), 
                          child: Text(
                            loc.checkoutButton, 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: colorScheme.onPrimary
                            )
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
    );
  }
}