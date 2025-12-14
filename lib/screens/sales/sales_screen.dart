// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // --- Data Variables ---
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> cartItems = []; 
  List<Map<String, dynamic>> recentSales = [];

  // --- Search & Filter ---
  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController customerSearchController = TextEditingController();
  
  List<Map<String, dynamic>> filteredCustomers = [];
  List<Map<String, dynamic>> filteredProducts = []; 
  
  bool showCustomerList = false;
  bool showProductList = false; 

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
    for (var item in cartItems) {
      item['priceCtrl']?.dispose();
      item['qtyCtrl']?.dispose();
    }
    super.dispose();
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

  Future<void> _loadProducts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products', orderBy: 'name_english ASC');
    if (mounted) {
      setState(() {
        products = result;
        filteredProducts = result;
      });
    }
  }

  Future<void> _loadCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers', orderBy: 'name_english ASC');
    if (mounted) {
      setState(() {
        customers = result;
        filteredCustomers = result; 
      });
    }
  }

  Future<void> _loadRecentSales() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final db = await DatabaseHelper.instance.database;
    
    // Note: We inject the translated "Walk-in Customer" string into the query result if name is null
    final result = await db.rawQuery('''
      SELECT 
        s.id, 
        s.bill_number, 
        s.sale_time, 
        s.grand_total, 
        s.cash_amount, 
        s.bank_amount, 
        s.credit_amount,
        s.total_paid,
        s.remaining_balance,
        COALESCE(c.name_english, '${loc.walkInCustomer}') as customer_name,
        c.outstanding_balance as customer_balance
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.created_at DESC
      LIMIT 20
    ''');
    if (mounted) setState(() => recentSales = result);
  }

  // --- Item Search Logic ---
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
        showProductList = false;
      } else {
        showProductList = true;
        filteredProducts = products.where((p) {
          final nameEng = (p['name_english'] ?? '').toString().toLowerCase();
          final itemCode = (p['item_code'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return nameEng.contains(q) || itemCode.contains(q);
        }).toList();
      }
    });
  }

  // --- Customer Search & Add Logic ---
  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
        showCustomerList = false;
      } else {
        showCustomerList = true;
        filteredCustomers = customers.where((c) {
          final nameEng = (c['name_english'] ?? '').toString().toLowerCase();
          final nameUrdu = (c['name_urdu'] ?? '').toString();
          final phone = (c['contact_primary'] ?? '').toString();
          final q = query.toLowerCase();
          return nameEng.contains(q) || nameUrdu.contains(q) || phone.contains(q);
        }).toList();
      }
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
                final db = await DatabaseHelper.instance.database;
                final existingUser = await db.query('customers', where: 'contact_primary = ?', whereArgs: [phoneNumber]);

                // 2. Check Exists
                if (existingUser.isNotEmpty) {
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

                final int id = await db.insert('customers', newCustomerData);
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
  void _addToCart(Map<String, dynamic> product) {
    if (isSoundOn) SystemSound.play(SystemSoundType.click);
    
    final index = cartItems.indexWhere((item) => item['id'] == product['id']);
    
    setState(() {
      if (index != -1) {
        final currentQty = cartItems[index]['quantity'] + 1.0;
        cartItems[index]['quantity'] = currentQty;
        cartItems[index]['total'] = currentQty * cartItems[index]['unit_price'];
        cartItems[index]['qtyCtrl'].text = currentQty.toStringAsFixed(0); 
      } else {
        double price = (product['sale_price'] ?? 0.0).toDouble();
        double qty = 1.0;
        
        final pCtrl = TextEditingController(text: price.toStringAsFixed(0));
        final qCtrl = TextEditingController(text: qty.toStringAsFixed(0));
        
        cartItems.add({
          'id': product['id'],
          'name_urdu': product['name_urdu'],
          'name_english': product['name_english'],
          'current_stock': product['current_stock'], 
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
    final item = cartItems[index];
    double newPrice = double.tryParse(item['priceCtrl'].text) ?? 0.0;
    double newQty = double.tryParse(item['qtyCtrl'].text) ?? 1.0;

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

  // --- NEW SIMPLIFIED CHECKOUT DIALOG (LOCALIZED) ---
  void _showCheckoutDialog() {
    if (cartItems.isEmpty) return;
    
    final loc = AppLocalizations.of(context)!;
    
    bool isRegistered = selectedCustomerId != null;
    double billTotal = grandTotal;
    double oldBalance = previousBalance;
    
    final cashCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final creditCtrl = TextEditingController();
    
    if (isRegistered) {
      creditCtrl.text = billTotal.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            double cash = double.tryParse(cashCtrl.text) ?? 0.0;
            double bank = double.tryParse(bankCtrl.text) ?? 0.0;
            // double credit = double.tryParse(creditCtrl.text) ?? 0.0; // Unused variable warning fix
            
            double totalPayment = cash + bank + (isRegistered ? (double.tryParse(creditCtrl.text) ?? 0.0) : 0);
            double change = 0.0;
            bool isValid = false;
            
            if (isRegistered) {
              isValid = (totalPayment == billTotal);
            } else {
              isValid = (cash + bank) >= billTotal;
              if (isValid) {
                change = (cash + bank) - billTotal;
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Container(
                color: Colors.green[700], 
                padding: const EdgeInsets.all(12), 
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(loc.checkoutButton, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      // Customer Info
                      if (isRegistered) ...[
                        Text('${loc.searchCustomerHint}: ${selectedCustomerMap!['name_english']}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange[200]!)),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 5),
                              Text('${loc.prevBalance}: Rs ${oldBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                      
                      _row(loc.billTotal, 'Rs ${billTotal.toStringAsFixed(0)}', isBold: true, size: 18),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(loc.paymentLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        _input(loc.creditInput, creditCtrl, (v) { setDialogState(() {}); }, enabled: false),
                      
                      const Divider(thickness: 2, height: 30),
                      
                      // Validation Status
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isValid ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isValid ? Colors.green : Colors.red)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Rs ${totalPayment.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (isRegistered) ...[
                              Row(
                                children: [
                                  Icon(isValid ? Icons.check_circle : Icons.cancel, size: 16, color: isValid ? Colors.green : Colors.red),
                                  const SizedBox(width: 5),
                                  Text(
                                    isValid ? loc.paymentMatch : loc.insufficientPayment,
                                    style: TextStyle(fontSize: 12, color: isValid ? Colors.green[700] : Colors.red[700]),
                                  ),
                                ],
                              ),
                            ] else ...[
                              if (change > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(loc.changeReturn, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Rs ${change.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                                  ],
                                ),
                              if (!isValid)
                                Text(
                                  '${loc.insufficientPayment} (Need Rs ${(billTotal - totalPayment).toStringAsFixed(0)})',
                                  style: const TextStyle(fontSize: 12, color: Colors.red),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? Colors.green[700] : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                  ),
                  onPressed: isValid ? () {
                    Navigator.pop(context);
                    _processSale(cash, bank, isRegistered ? (double.tryParse(creditCtrl.text) ?? 0.0) : 0.0);
                  } : null,
                  child: Text(loc.confirmSale, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isBold = false, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size)),
        ]
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, Function(String) onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 14))),
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
                fillColor: enabled ? null : Colors.grey[200],
              ), 
              style: TextStyle(fontWeight: FontWeight.bold, color: enabled ? Colors.black : Colors.grey[600]),
              onChanged: onChanged,
            ),
          ),
        ]
      ),
    );
  }

  // --- Process Sale ---
  Future<void> _processSale(double cash, double bank, double credit) async {
    final loc = AppLocalizations.of(context)!;
    
    // 1. Prepare Data
    final Map<String, dynamic> saleData = {
      'customer_id': selectedCustomerId,
      'grand_total': grandTotal,
      'discount': 0.0,
      
      // FIX: Pass the Payment Breakdown
      'cash_amount': cash,
      'bank_amount': bank,
      // We don't necessarily need 'credit' input here because 
      // the DB will calculate (Total - Cash - Bank). 
      // But passing it is fine for record keeping.
      'credit_amount': credit, 

      'items': cartItems.map((item) {
         return {
           'id': item['id'],
           'quantity': item['quantity'],
           'sale_price': item['unit_price'],
           'total': item['total'],
         };
      }).toList(),
    };

    try {
      await DatabaseHelper.instance.createSale(saleData);
      
      _performClearCart();
      await _refreshAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.saleCompleted), backgroundColor: Colors.green));
      }
    } catch (e) {
      print('Error processing sale: $e');
      if (mounted) {
        final cleanError = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $cleanError'), backgroundColor: Colors.red));
      }
    }
  }

  // --- Delete Sale ---
  Future<void> _deleteSale(int id, String billNumber) async {
    final loc = AppLocalizations.of(context)!;
    
    bool? confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: Text(loc.deleteBillTitle), 
        content: Text(loc.deleteBillMsg), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(loc.cancel)), // Use loc.cancel
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () => Navigator.pop(c, true), 
            child: Text(loc.delete, style: const TextStyle(color: Colors.white))
          )
        ]
      )
    );
    
    if (confirm != true) return;
    
    final db = await DatabaseHelper.instance.database;
    
    try {
      final saleRes = await db.query('sales', where: 'id = ?', whereArgs: [id]);
      if (saleRes.isEmpty) return;
      
      final sale = saleRes.first;
      final itemsRes = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [id]);

      await db.transaction((txn) async {
        // 1. Restore Stock
        for (var item in itemsRes) {
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock + ? WHERE id = ?', 
            [item['quantity_sold'], item['product_id']]
          );
        }
        
        // 2. Restore Customer Balance (THE FIX)
        double remaining = (sale['remaining_balance'] as num?)?.toDouble() ?? 0.0;
        if (sale['customer_id'] != null && remaining > 0) {
          await txn.rawUpdate(
            'UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?', 
            [remaining, sale['customer_id']]
          );
        }
        
        // 3. Delete Records
        await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
        await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
      });

      await _refreshAllData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.bill} $billNumber ${loc.deletedSuccessfully}'), backgroundColor: Colors.green));
      
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red)); 
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
                            Text('Rs ${product['sale_price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        title: Text(sale['customer_name'] ?? loc.walkInCustomer, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('${sale['bill_number']}', style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text('Rs ${sale['grand_total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red), 
                              onPressed: () => _deleteSale(sale['id'], sale['bill_number'])
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
                      Text('Rs ${subtotal.toStringAsFixed(0)}')
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
                        'Rs ${grandTotal.toStringAsFixed(0)}', 
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