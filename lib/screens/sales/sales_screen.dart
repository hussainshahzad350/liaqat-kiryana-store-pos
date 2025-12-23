// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../../core/repositories/sales_repository.dart';
import '../../models/sale_model.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/repositories/customers_repository.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  final ItemsRepository _itemsRepository = ItemsRepository();
  final CustomersRepository _customersRepository = CustomersRepository();
  // --- Data Variables ---
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> cartItems = []; 
  List<Sale> recentSales = [];

  // --- Search & Filter ---
  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController customerSearchController = TextEditingController();
  
  List<Map<String, dynamic>> filteredCustomers = [];
  List<Map<String, dynamic>> filteredProducts = []; 
  
  bool showCustomerList = false;
  bool showProductList = false; 

  // Debounce Timers
  Timer? _productSearchDebounce;
  Timer? _customerSearchDebounce;

  // --- Selection ---
  int? selectedCustomerId;
  Map<String, dynamic>? selectedCustomerMap;

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
    // Access localization directly
    final loc = AppLocalizations.of(context)!;

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
              child: Text(loc.exit, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  // --- Data Loading ---
  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadProducts(),
      _loadCustomers(),
      _loadRecentSales(),
    ]);
  }

  Future<void> _loadCustomers() async {
    // Use Repository
    final result = await _customersRepository.getAllCustomers();
    if (mounted) {
      setState(() {
        customers = result;
        filteredCustomers = result;
      });
    }
  }

  Future<void> _loadProducts() async {
    final result = await _itemsRepository.getSellableItems();
    if (mounted) {
      setState(() {
        products = result;
        filteredProducts = result;
      });
    }
  }

  Future<void> _loadRecentSales() async {
    if (!mounted) return;
    // Use Repository - The repo should handle the complex join query
    final result = await _salesRepository.getRecentSales();
    if (mounted) setState(() => recentSales = result.map((map) => Sale.fromMap(map)).toList());
  }

  // --- Item Search Logic ---
  void _filterProducts(String query) {
    // Cancel previous timer
    _productSearchDebounce?.cancel();
    // Set new timer (300ms delay)
    _productSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        if (query.isEmpty) {
          filteredProducts = products;
          showProductList = false;
        } else {
          showProductList = true;
          final q = query.toLowerCase();
          filteredProducts = products.where((p) {
            final nameEng = (p['name_english'] ?? '').toString().toLowerCase();
            final itemCode = (p['item_code'] ?? '').toString().toLowerCase();
            return nameEng.contains(q) || itemCode.contains(q);
          }).toList();
        }
      });
    });
  }

  // --- Customer Search & Add Logic ---
  void _filterCustomers(String query) {
    _customerSearchDebounce?.cancel();
    
    _customerSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        if (query.isEmpty) {
          filteredCustomers = customers;
          showCustomerList = false;
        } else {
          showCustomerList = true;
          final q = query.toLowerCase();
          filteredCustomers = customers.where((c) {
            final nameEng = (c['name_english'] ?? '').toString().toLowerCase();
            final phone = (c['contact_primary'] ?? '').toString();
            return nameEng.contains(q) || phone.contains(q);
          }).toList();
        }
      });
    });
  }

  void _selectCustomer(Map<String, dynamic>? customer) {
    setState(() {
      if (customer == null) {
        selectedCustomerId = null;
        selectedCustomerMap = null;
        customerSearchController.clear();
      } else {
        selectedCustomerId = customer['id'];
        selectedCustomerMap = customer;
        customerSearchController.text = "${customer['name_english']} (${customer['contact_primary'] ?? ''})";
      }
      showCustomerList = false;
      _calculateTotals();
    });
  }

  // Quick Add Customer
  void _showAddCustomerDialog() {
    final loc = AppLocalizations.of(context)!;
    
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () async {
              // 1. Validation 
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
                final bool customerExists = await _customersRepository.customerExistsByPhone(phoneNumber);

                // 2. Check Exists
                if (customerExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${loc.phoneExists}: "$phoneNumber"'), 
                      backgroundColor: Colors.red
                    )
                  );
                  return; 
                }

                final newCustomerData = {
                  'name_english': nameEngCtrl.text.trim(),
                  'name_urdu': nameUrduCtrl.text.trim(),
                  'contact_primary': phoneNumber,
                  'address': addressCtrl.text.trim(),
                  'credit_limit': double.tryParse(creditLimitCtrl.text) ?? 0.0,
                  'outstanding_balance': 0.0,
                  'is_active': 1,
                  'created_at': DateTime.now().toIso8601String(),
                };

                final int id = await _customersRepository.addCustomer(newCustomerData);
                final Map<String, dynamic> savedCustomer = {'id': id, ...newCustomerData};

                if (mounted) {
                  _selectCustomer(savedCustomer);
                  Navigator.of(context).pop();
                  await _loadCustomers();
                  
                  // 3. Success Message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${loc.customerAdded}: '${nameEngCtrl.text}'"), 
                      backgroundColor: Colors.green
                    )
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text(loc.saveSelect),
          ),
        ],
      ),
    );
  }

  // --- Cart Actions ---
  void _addToCart(Map<String, dynamic> product, {double quantity = 1.0}) {
    final loc = AppLocalizations.of(context)!;


    // ✅ VALIDATION: Prevent adding invalid amounts (0 or negative)
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidQuantity)),
      );
      return;
    }

    if (isSoundOn) SystemSound.play(SystemSoundType.click);

    final index = cartItems.indexWhere((item) => item['id'] == product['id']);
    final availableStock = (product['current_stock'] as num).toDouble();

    setState(() {
      if (index != -1) {
        final currentQty = cartItems[index]['quantity'] as double;
        final newQty = currentQty + quantity;

        // ✅ VALIDATION: Check stock before adding
        if (newQty > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.insufficientStock}: ${availableStock.toStringAsFixed(2)} available'), // Show 2 decimals
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        cartItems[index]['quantity'] = newQty;
        cartItems[index]['total'] = newQty * cartItems[index]['unit_price'];
        
        // ✅ FORMATTING: Show decimals if needed (e.g. 1.5), otherwise integer (e.g. 1)
        String displayQty = newQty % 1 == 0 ? newQty.toInt().toString() : newQty.toString();
        cartItems[index]['qtyCtrl'].text = displayQty;
        
      } else {
        // ✅ VALIDATION: Check stock for new item
        if (availableStock < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.outOfStock),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        double price = (product['sale_price'] ?? 0) / 100.0;
        double qty = quantity;

        // ✅ FORMATTING: Support decimals for Price and Qty
        String displayPrice = price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
        String displayQty = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2);

        final pCtrl = TextEditingController(text: displayPrice);
        final qCtrl = TextEditingController(text: displayQty);

        cartItems.add({
          'id': product['id'],
          'name_urdu': product['name_urdu'],
          'name_english': product['name_english'],
          'current_stock': availableStock,
          'unit_price': price,
          'quantity': qty,
          'total': price * qty,
          'priceCtrl': pCtrl,
          'qtyCtrl': qCtrl,
        });
      }

      if (showProductList) {
        productSearchController.clear();
        showProductList = false;
      }
      _calculateTotals();
    });
}

  void _updateCartItemFromField(int index) {
    final loc = AppLocalizations.of(context)!;
    final item = cartItems[index];

    // Allow empty string during typing
    String priceText = item['priceCtrl'].text;
    String qtyText = item['qtyCtrl'].text;
    
    double newPrice = priceText.isEmpty ? 0.0 : double.tryParse(priceText) ?? 0.0;
    double newQty = qtyText.isEmpty ? 0.0 : double.tryParse(qtyText) ?? 0.0;

    // ✅ VALIDATION: Prevent negative or zero values
    if (newPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidPrice),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reset to original value
      item['priceCtrl'].text = item['unit_price'].toStringAsFixed(0);
      return;
    }

    if (newQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidQuantity),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reset to original value
      item['qtyCtrl'].text = item['quantity'].toStringAsFixed(0);
      return;
    }

    // ✅ VALIDATION: Check stock availability
    final availableStock = (item['current_stock'] as num).toDouble();
    if (newQty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.insufficientStock}: ${availableStock.toStringAsFixed(0)} available'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reset to available stock
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

  void _showCheckoutDialog() {
    final loc = AppLocalizations.of(context)!;
    
    double cashAmount = 0.0;
    double bankAmount = 0.0;
    double creditAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        final cashCtrl = TextEditingController(text: grandTotal.toStringAsFixed(0));
        final bankCtrl = TextEditingController();
        final creditCtrl = TextEditingController();
        
        return AlertDialog(
          title: Text(loc.selectPaymentMethod),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.grandTotal}: ${CurrencyUtils.formatRupees((grandTotal * 100).toInt())}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: cashCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${loc.cash} (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${loc.bank} (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: creditCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${loc.credit} (Rs)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                cashAmount = double.tryParse(cashCtrl.text) ?? 0.0;
                bankAmount = double.tryParse(bankCtrl.text) ?? 0.0;
                creditAmount = double.tryParse(creditCtrl.text) ?? 0.0;
                
                final totalPaid = cashAmount + bankAmount + creditAmount;
                if (totalPaid < grandTotal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.insufficientPayment),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                final change = totalPaid - grandTotal;
                _processSale(cashAmount, bankAmount, creditAmount, change);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child: Text(loc.confirmPayment, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _clearCart() {
    final loc = AppLocalizations.of(context)!;

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
            child: Text(loc.clearAll, style: const TextStyle(color: Colors.red)),
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
    previousBalance = selectedCustomerMap?['outstanding_balance'] ?? 0.0;
  }

  // --- Process Sale ---
  Future<void> _processSale(double cash, double bank, double credit, double change) async {
    final loc = AppLocalizations.of(context)!;

    // ✅ SHOW LOADING INDICATOR
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

    // Prepare Data
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
      await _salesRepository.createSale(saleData);

      // ✅ DISMISS LOADING INDICATOR
      if (mounted) Navigator.pop(context);

      _performClearCart();
      await _refreshAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saleCompleted), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      // ✅ DISMISS LOADING INDICATOR
      if (mounted) Navigator.pop(context);

      print('Error processing sale: $e');
      if (mounted) {
        final cleanError = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.errorProcessingSale(cleanError)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            )
        );
      }
    }
  }

  // --- Cancel Sale ---
  Future<void> _cancelSale(int id, String billNumber) async {
  final loc = AppLocalizations.of(context)!;

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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(c, true),
          child: Text(loc.cancelSale, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await _salesRepository.cancelSale(
      saleId: id,
      cancelledBy: 'Cashier', // TODO: Replace with actual logged-in user
      reason: reasonCtrl.text.trim(),
    );

    // ✅ FIXED: Refresh data after cancellation
    await _refreshAllData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.saleCancelledSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // --- REFACTORED BUILD METHOD (RTL FIXES) ---
  @override
  Widget build(BuildContext context) {
    // 1. Initialize Localization Helper
    final loc = AppLocalizations.of(context)!;
    
    // Determine if RTL is active for specific conditional logic if needed
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.posTitle), 
          backgroundColor: Colors.green[700],
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAllData), 
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart), 
          ]
        ),
        body: Row(children: [
          // ------------------------------------------------------------------
          // LEFT PANEL (Item Grid) 
          // ------------------------------------------------------------------
          Expanded(flex: 6, child: Column(children: [
            // Item Search
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                TextField(
                  controller: productSearchController,
                  decoration: InputDecoration(
                    hintText: loc.searchItemHint, 
                    // Prefix Icon logic handled automatically by Flutter's Start position
                    prefixIcon: const Icon(Icons.search), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                    filled: true, 
                    fillColor: Colors.grey[100]
                  ),
                  onChanged: _filterProducts,
                  onTap: () { 
                    if(productSearchController.text.isNotEmpty) {
                      _filterProducts(productSearchController.text); 
                    }
                  },
                ),
                if (showProductList && filteredProducts.isNotEmpty)
                  Container(
                    height: 200, 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      border: Border.all(color: Colors.grey[300]!), 
                      borderRadius: BorderRadius.circular(8), 
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]
                    ),
                    child: ListView.separated(
                      itemCount: filteredProducts.length, 
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        return ListTile(
                          dense: true,
                          title: Text(p['name_english'] ?? 'Unknown'),
                          subtitle: Text('Stock: ${p['current_stock']} | Rs ${p['sale_price']}'),
                          onTap: () => _addToCart(p),
                        );
                      },
                    ),
                  ),
              ]),
            ),
            
            // Product Grid
            Expanded(
              flex: 6,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, 
                  childAspectRatio: 1.0, 
                  crossAxisSpacing: 5, 
                  mainAxisSpacing: 5
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 2, 
                    child: InkWell(
                      onTap: () => _addToCart(product),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0), 
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Text(
                              product['name_urdu'] ?? '', 
                              style: const TextStyle(fontSize: 12, fontFamily: 'NooriNastaleeq', fontWeight: FontWeight.bold), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                            Text(product['name_english'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(CurrencyUtils.formatRupees(product['sale_price'] ?? 0), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${loc.stock}:${product['current_stock']}', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ]
                        )
                      ),
                    )
                  );
                },
              ),
            ),
            const Divider(thickness: 2),
            // Recent Sales
            Container(
              height: 200, 
              color: Colors.white,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(8), 
                  color: Colors.grey[200], 
                  width: double.infinity, 
                  // RTL Fix: centerLeft -> centerStart
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(loc.recentSales, style: const TextStyle(fontWeight: FontWeight.bold))
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: recentSales.length, 
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = recentSales[index];
                      return ListTile(
                        dense: true, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        leading: CircleAvatar(
                          radius: 12, 
                          backgroundColor: Colors.green[100], 
                          child: Text('${index+1}', style: const TextStyle(fontSize: 10))
                        ),
                        title: Text(sale.customerName ?? loc.walkInCustomer, style: const TextStyle(fontSize: 13)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Text(sale.billNumber,
                        style: const TextStyle(fontSize: 10),),Text(sale.status == 'CANCELLED'? loc.cancelled: loc.completed,
                        style: TextStyle(fontSize: 10,fontWeight: FontWeight.bold,color: 
                        sale.status == 'CANCELLED'? Colors.red: Colors.green,),),]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(CurrencyUtils.formatRupees(sale.grandTotal.toInt()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.cancel, size: 16, color: Colors.orange), 
                              onPressed: sale.status == 'CANCELLED'
                              ? null
                              : () => _cancelSale(sale.id!, sale.billNumber),
                            ),
                          ]
                        ),
                      );
                    },
                  )
                ),
              ]),
            ),
          ])),

          // ------------------------------------------------------------------
          // RIGHT PANEL (Cart & Customer)
          // ------------------------------------------------------------------
          Expanded(flex: 4, child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50], 
              // RTL Fix: Border(left:...) -> BorderDirectional(start:...)
              border: BorderDirectional(start: BorderSide(color: Colors.grey[300]!))
            ),
            child: Column(children: [
              // Customer Search Panel
              Container(
                padding: const EdgeInsets.all(8), 
                color: Colors.white, 
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: customerSearchController,
                        decoration: InputDecoration(
                          labelText: loc.searchCustomerHint, 
                          prefixIcon: const Icon(Icons.person_search), 
                          suffixIcon: selectedCustomerId != null ? IconButton(
                            icon: const Icon(Icons.clear), 
                            onPressed: () => _selectCustomer(null)
                          ) : null, 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                          isDense: true
                        ), 
                        onChanged: _filterCustomers, 
                        onTap: () { 
                          if(selectedCustomerId == null) {
                            _filterCustomers(customerSearchController.text); 
                          }
                        }
                      )
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      height: 48, 
                      width: 48, 
                      child: ElevatedButton(
                        onPressed: _showAddCustomerDialog, 
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, 
                          backgroundColor: Colors.green[700], 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ), 
                        child: const Icon(Icons.person_add, color: Colors.white)
                      )
                    ),
                  ]),
                  if (showCustomerList && filteredCustomers.isNotEmpty)
                    Container(
                      height: 150, 
                      margin: const EdgeInsets.only(top: 5), 
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        border: Border.all(color: Colors.grey[300]!), 
                        borderRadius: BorderRadius.circular(8), 
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]
                      ), 
                      child: ListView.separated(
                        itemCount: filteredCustomers.length, 
                        separatorBuilder: (c, i) => const Divider(height: 1), 
                        itemBuilder: (context, index) { 
                          final c = filteredCustomers[index]; 
                          return ListTile(
                            dense: true, 
                            title: Text(c['name_english'] ?? 'Unknown'), 
                            subtitle: Text('${c['contact_primary'] ?? ''}'), 
                            trailing: Text('${loc.currBal}: ${c['outstanding_balance']}'), 
                            onTap: () => _selectCustomer(c)
                          ); 
                        }
                      )
                    ),
                ]),
              ),
              const Divider(height: 1),
              
              // Cart List
              Expanded(
                child: cartItems.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(loc.cartEmpty, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: cartItems.length, 
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Container(
                          // RTL Fix: padding only(left) would be bad. symmetric is safe.
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
                          child: Row(children: [
                            // Item Name
                            Expanded(
                              flex: 3, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Auto-flips for RTL
                                children: [
                                  Text(
                                    isRTL && item['name_urdu'] != null ? item['name_urdu'] : item['name_english'], 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ), 
                                  Text(
                                    '${loc.stock}: ${item['current_stock']}', 
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)
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
                                  contentPadding: const EdgeInsets.all(8), 
                                  border: const OutlineInputBorder(), 
                                  labelText: loc.price, 
                                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
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
                                  contentPadding: const EdgeInsets.all(8), 
                                  border: const OutlineInputBorder(), 
                                  labelText: loc.qty, 
                                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
                                onChanged: (_) => _updateCartItemFromField(index),
                              )
                            ),
                            const SizedBox(width: 8),
                            
                            // Total
                            SizedBox(
                              width: 70, 
                              child: Text(
                                (item['total'] as double).toStringAsFixed(0), 
                                textAlign: TextAlign.end, // RTL Fix: right -> end
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                              )
                            ),
                            
                            // Delete Button
                            InkWell(
                              onTap: () => _removeCartItem(index), 
                              child: const Padding(
                                padding: EdgeInsets.all(8.0), 
                                child: Icon(Icons.close, color: Colors.red, size: 24)
                              )
                            ), 
                          ]),
                        );
                      },
                    )
              ),
              // Totals Section
              Container(
                padding: const EdgeInsets.all(12), 
                color: Colors.white, 
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(loc.totalItems), 
                      Text('${cartItems.length}')
                    ]
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(loc.subtotal), 
                      Text(CurrencyUtils.formatRupees((subtotal * 100).toInt()))
                    ]
                  ),
                  if (previousBalance > 0) 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(loc.prevBalance, style: const TextStyle(color: Colors.orange, fontSize: 12)), 
                        Text('Rs ${previousBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orange, fontSize: 12))
                      ]
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(loc.grandTotal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                      Text(
                        CurrencyUtils.formatRupees((grandTotal * 100).toInt()), 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)
                      )
                    ]
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity, 
                    height: 45, 
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty ? null : _showCheckoutDialog, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700]
                      ), 
                      child: Text(
                        loc.checkoutButton, 
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        )
                      )
                    )
                  ),
                ]),
              ),
            ])),
          ),
        ]),
      ),
    );
  }
}