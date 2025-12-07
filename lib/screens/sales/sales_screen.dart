// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Cart holds Controllers for editing
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
  double discount = 0.0;
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
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT 
        s.id, s.bill_number, s.sale_time, s.grand_total,
        COALESCE(c.name_english, 'Walk-in') as customer_name
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

  // Quick Add Customer (FIXED LOGIC)
  void _showAddCustomerDialog() {
    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngCtrl, decoration: const InputDecoration(labelText: 'Name (English)*')),
              TextField(controller: nameUrduCtrl, decoration: const InputDecoration(labelText: 'Name (Urdu)')),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number*')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: creditLimitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // ==== VALIDATION ====
              if (nameEngCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('English Name is required')),
                );
                return;
              }
              if (phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone Number is required')),
                );
                return;
              }

              try {
                final db = await DatabaseHelper.instance.database;

                final newCustomerData = {
                  'name_english': nameEngCtrl.text.trim(),
                  'name_urdu': nameUrduCtrl.text.trim(),
                  'contact_primary': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'credit_limit': double.tryParse(creditLimitCtrl.text) ?? 0.0,
                  'outstanding_balance': 0.0,
                  'is_active': 1,
                  'created_at': DateTime.now().toIso8601String(),
                };

                // THESE TWO LINES ARE FOR DEBUGGING
                print('Inserting customer data: $newCustomerData');
                final int id = await db.insert('customers', newCustomerData);
                print('Inserted customer ID: $id'); // You will see this in console if success

                final Map<String, dynamic> savedCustomer = {
                  'id': id,
                  ...newCustomerData,
                };

                if (mounted) {
                  _selectCustomer(savedCustomer);
                  Navigator.of(context).pop(); // close dialog

                  await _loadCustomers(); // refresh list

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Customer '${nameEngCtrl.text}' added & selected!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e, stackTrace) {
                print('ERROR ADDING CUSTOMER: $e');
                print(stackTrace);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add customer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save & Select'),
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
    cartItems[index]['priceCtrl']?.dispose();
    cartItems[index]['qtyCtrl']?.dispose();
    setState(() {
      cartItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _clearCart() {
    for (var item in cartItems) {
      item['priceCtrl']?.dispose();
      item['qtyCtrl']?.dispose();
    }
    setState(() {
      cartItems.clear();
      discount = 0.0;
      selectedCustomerId = null;
      selectedCustomerMap = null;
      customerSearchController.clear();
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    subtotal = cartItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
    grandTotal = subtotal - discount;
    if (grandTotal < 0) grandTotal = 0;
    previousBalance = selectedCustomerMap?['outstanding_balance'] ?? 0.0;
  }

  // --- Checkout Dialog ---
  void _showCheckoutDialog() {
    if (cartItems.isEmpty) return;
    double dCash = grandTotal;
    double dBank = 0.0;
    double dCredit = 0.0;
    double dDiscount = discount;

    final cashCtrl = TextEditingController(text: dCash.toStringAsFixed(0));
    final bankCtrl = TextEditingController(text: '0');
    final creditCtrl = TextEditingController(text: '0');
    final discountCtrl = TextEditingController(text: dDiscount.toStringAsFixed(0));
    bool isRegistered = selectedCustomerId != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentTotal = subtotal - dDiscount;
            double totalPaid = dCash + dBank + dCredit;
            double remaining = currentTotal - totalPaid;
            double limit = selectedCustomerMap?['credit_limit'] ?? 0.0;
            double currentBal = selectedCustomerMap?['outstanding_balance'] ?? 0.0;
            bool limitExceeded = (currentBal + dCredit) > limit;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Container(color: Colors.green[700], padding: const EdgeInsets.all(10), child: const Text('Checkout', style: TextStyle(color: Colors.white))),
              titlePadding: EdgeInsets.zero,
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _row('Subtotal', 'Rs ${subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Expanded(child: Text('Discount:')),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (v) {
                              setDialogState(() {
                                dDiscount = double.tryParse(v) ?? 0.0;
                                dCash = (subtotal - dDiscount) - dBank - dCredit;
                                if(dCash < 0) dCash = 0;
                                cashCtrl.text = dCash.toStringAsFixed(0);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _row('Grand Total', 'Rs ${currentTotal.toStringAsFixed(0)}', isBold: true),
                    const SizedBox(height: 15),
                    _input('Cash', cashCtrl, (v) => setDialogState(() => dCash = v)),
                    _input('Bank', bankCtrl, (v) => setDialogState(() => dBank = v)),
                    Opacity(
                      opacity: isRegistered ? 1 : 0.5,
                      child: _input('Credit', creditCtrl, (v) => setDialogState(() => dCredit = v), enabled: isRegistered),
                    ),
                    if (isRegistered && limitExceeded) const Text('Credit Limit Exceeded!', style: TextStyle(color: Colors.red, fontSize: 12)),
                    const Divider(),
                    _row('Remaining', remaining.toStringAsFixed(0), color: remaining.abs() < 1 ? Colors.green : Colors.red),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  onPressed: remaining.abs() > 1 ? null : () {
                    setState(() => discount = dDiscount);
                    _processSale(dCash, dBank, dCredit);
                    Navigator.pop(context);
                  },
                  child: const Text('Print & Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ]),
    );
  }

  Widget _input(String label, TextEditingController ctrl, Function(double) onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label)),
        SizedBox(width: 100, child: TextField(controller: ctrl, enabled: enabled, keyboardType: TextInputType.number, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()), onChanged: (val) => onChanged(double.tryParse(val) ?? 0.0))),
      ]),
    );
  }

  // --- Transactions ---
  Future<void> _processSale(double cash, double bank, double credit) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    try {
      // 1. Generate Custom Bill Number (SB-000001)
      final lastIdRes = await db.rawQuery('SELECT MAX(id) as max_id FROM sales');
      int nextId = 1;
      if (lastIdRes.isNotEmpty && lastIdRes.first['max_id'] != null) {
        nextId = (lastIdRes.first['max_id'] as int) + 1;
      }
      final billNo = 'SB-${nextId.toString().padLeft(6, '0')}';

      await db.transaction((txn) async {
        final saleId = await txn.insert('sales', {
          'bill_number': billNo, 
          'customer_id': selectedCustomerId, 
          'sale_date': now.toIso8601String().split('T')[0], 
          'sale_time': '${now.hour}:${now.minute}',
          'grand_total': grandTotal, 
          'cash_amount': cash, 
          'bank_amount': bank, 
          'credit_amount': credit, 
          'total_paid': cash + bank, 
          'remaining_balance': 0.0, 
          'created_at': now.toIso8601String(),
        });
        
        for (var item in cartItems) {
          await txn.insert('sale_items', {'sale_id': saleId, 'product_id': item['id'], 'quantity_sold': item['quantity'], 'unit_price': item['unit_price'], 'total_price': item['total'], 'created_at': now.toIso8601String()});
          await txn.rawUpdate('UPDATE products SET current_stock = current_stock - ? WHERE id = ?', [item['quantity'], item['id']]);
        }
        
        if (selectedCustomerId != null && credit > 0) {
          await txn.rawUpdate('UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?', [credit, selectedCustomerId]);
        }
      });
      _clearCart();
      _refreshAllData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale Completed! Bill No: $billNo')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteSale(int id, String billNumber) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Delete Bill?'), content: const Text('This will revert stock and customer balance.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))]));
    if (confirm == true) await _revertSale(billNumber, loadToCart: false);
  }

  Future<void> _editSale(int id, String billNumber) async {
    bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Edit Bill?'), content: const Text('This will DELETE the current bill and load items back to cart.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Edit'))]));
    if (confirm == true) { _clearCart(); await _revertSale(billNumber, loadToCart: true); }
  }

  Future<void> _revertSale(String billNumber, {required bool loadToCart}) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final saleRes = await db.query('sales', where: 'bill_number = ?', whereArgs: [billNumber]);
      if (saleRes.isEmpty) return;
      final sale = saleRes.first;
      final itemsRes = await db.rawQuery('SELECT si.*, p.name_english, p.name_urdu, p.unit_type, p.current_stock FROM sale_items si JOIN products p ON si.product_id = p.id WHERE si.sale_id = ?', [sale['id']]);

      await db.transaction((txn) async {
        for (var item in itemsRes) await txn.rawUpdate('UPDATE products SET current_stock = current_stock + ? WHERE id = ?', [item['quantity_sold'], item['product_id']]);
        double credit = (sale['credit_amount'] as num?)?.toDouble() ?? 0.0;
        if (sale['customer_id'] != null && credit > 0) await txn.rawUpdate('UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?', [credit, sale['customer_id']]);
        await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [sale['id']]);
        await txn.delete('sales', where: 'id = ?', whereArgs: [sale['id']]);
      });

      if (loadToCart) {
        setState(() {
           int? cId = sale['customer_id'] as int?;
           if(cId != null) { final c = customers.firstWhere((cust) => cust['id'] == cId, orElse: () => {}); if(c.isNotEmpty) _selectCustomer(c); }
           for (var item in itemsRes) {
              _addToCart({
                'id': item['product_id'], 'name_urdu': item['name_urdu'], 'name_english': item['name_english'], 'current_stock': item['current_stock'], 'sale_price': item['unit_price']
              });
              int idx = cartItems.length - 1;
              double qty = (item['quantity_sold'] as num).toDouble();
              cartItems[idx]['quantity'] = qty;
              cartItems[idx]['qtyCtrl'].text = qty.toStringAsFixed(0);
              cartItems[idx]['total'] = qty * (item['unit_price'] as num).toDouble();
           }
           _calculateTotals();
        });
      }
      _refreshAllData();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  // --- UI Structure ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Terminal'), backgroundColor: Colors.green[700], actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAllData), IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart)]),
      body: Row(children: [
        // LEFT PANEL (60%)
        Expanded(flex: 6, child: Column(children: [
          // Item Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              TextField(
                controller: productSearchController,
                decoration: InputDecoration(hintText: 'Search Item / Scan Barcode', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey[100]),
                onChanged: _filterProducts,
                onTap: () { if(productSearchController.text.isNotEmpty) _filterProducts(productSearchController.text); },
              ),
              if (showProductList && filteredProducts.isNotEmpty)
                Container(
                  height: 200, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]),
                  child: ListView.separated(
                    itemCount: filteredProducts.length, separatorBuilder: (c, i) => const Divider(height: 1),
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
          
          // Product Grid (Smaller & Bold - 6 Columns)
          Expanded(
            flex: 6,
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              // 6 Columns for compact view (4th size as compared to original)
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 1.0, crossAxisSpacing: 5, mainAxisSpacing: 5),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(elevation: 2, child: InkWell(
                  onTap: () => _addToCart(product),
                  child: Padding(padding: const EdgeInsets.all(2.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(product['name_urdu'] ?? '', style: const TextStyle(fontSize: 12, fontFamily: 'NooriNastaleeq', fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(product['name_english'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('Rs ${product['sale_price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Stk:${product['current_stock']}', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ])),
                ));
              },
            ),
          ),
          const Divider(thickness: 2),
          // Recent Sales (Scrollable)
          Container(
            height: 200, color: Colors.white,
            child: Column(children: [
              Container(padding: const EdgeInsets.all(8), color: Colors.grey[200], width: double.infinity, child: const Text('Recent Sales', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: ListView.separated(
                itemCount: recentSales.length, separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sale = recentSales[index];
                  return ListTile(
                    dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    leading: CircleAvatar(radius: 12, backgroundColor: Colors.green[100], child: Text('${index+1}', style: const TextStyle(fontSize: 10))),
                    title: Text(sale['customer_name'] ?? 'Walk-in', style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${sale['bill_number']}', style: const TextStyle(fontSize: 10)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Rs ${sale['grand_total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      IconButton(icon: const Icon(Icons.edit, size: 16, color: Colors.blue), onPressed: () => _editSale(sale['id'], sale['bill_number'])),
                      IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: () => _deleteSale(sale['id'], sale['bill_number'])),
                    ]),
                  );
                },
              )),
            ]),
          ),
        ])),
        // RIGHT PANEL (40%)
        Expanded(flex: 4, child: Container(
          decoration: BoxDecoration(color: Colors.grey[50], border: Border(left: BorderSide(color: Colors.grey[300]!))),
          child: Column(children: [
            // Customer Search
            Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Column(children: [
              Row(children: [
                Expanded(child: TextField(controller: customerSearchController, decoration: InputDecoration(labelText: 'Search Customer', prefixIcon: const Icon(Icons.person_search), suffixIcon: selectedCustomerId != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _selectCustomer(null)) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), onChanged: _filterCustomers, onTap: () { if(selectedCustomerId == null) _filterCustomers(customerSearchController.text); })),
                const SizedBox(width: 5),
                SizedBox(height: 48, width: 48, child: ElevatedButton(onPressed: _showAddCustomerDialog, style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Icon(Icons.person_add, color: Colors.white))),
              ]),
              if (showCustomerList && filteredCustomers.isNotEmpty)
                Container(height: 150, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]), child: ListView.separated(itemCount: filteredCustomers.length, separatorBuilder: (c, i) => const Divider(height: 1), itemBuilder: (context, index) { final c = filteredCustomers[index]; return ListTile(dense: true, title: Text(c['name_english'] ?? 'Unknown'), subtitle: Text('${c['contact_primary'] ?? ''}'), trailing: Text('Bal: ${c['outstanding_balance']}'), onTap: () => _selectCustomer(c)); })),
            ])),
            const Divider(height: 1),
            // Cart List (BIGGER & BOLD)
            Expanded(child: cartItems.isEmpty ? const Center(child: Text('Cart Empty', style: TextStyle(color: Colors.grey))) : ListView.separated(
              itemCount: cartItems.length, separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
                  child: Row(children: [
                    // Item Name (Expanded)
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['name_english'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis), 
                      Text('Stock: ${item['current_stock']}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ])),
                    
                    // Price Box (Bigger)
                    SizedBox(width: 80, child: TextField( 
                      controller: item['priceCtrl'],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder(), labelText: 'Price', labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
                      onChanged: (_) => _updateCartItemFromField(index),
                    )),
                    const SizedBox(width: 8),
                    
                    // Qty Box (Bigger)
                    SizedBox(width: 60, child: TextField( 
                      controller: item['qtyCtrl'],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder(), labelText: 'Qty', labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
                      onChanged: (_) => _updateCartItemFromField(index),
                    )),
                    const SizedBox(width: 8),
                    
                    // Total (Big & Bold)
                    SizedBox(width: 70, child: Text((item['total'] as double).toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    
                    // Delete Button
                    InkWell(onTap: () => _removeCartItem(index), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.close, color: Colors.red, size: 24))), 
                  ]),
                );
              },
            )),
            // Totals
            Container(padding: const EdgeInsets.all(12), color: Colors.white, child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Items'), Text('${cartItems.length}')]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('Rs ${subtotal.toStringAsFixed(0)}')]),
              if (previousBalance > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Prev Balance', style: TextStyle(color: Colors.red)), Text('Rs $previousBalance', style: const TextStyle(color: Colors.red))]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Rs ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))]),
              const SizedBox(height: 5),
              SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: cartItems.isEmpty ? null : _showCheckoutDialog, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), child: const Text('CHECKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
            ])),
          ])),
        ),
      ]),
    );
  }
}