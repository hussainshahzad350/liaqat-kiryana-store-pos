// lib/screens/sales/sales_screen.dart
// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
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

  // This helper makes your code cleaner
String tr(String key) {
    // This fetches the actual Urdu/English text based on the user's choice
    final loc = AppLocalizations.of(context)!;
    
    switch (key) {
      case 'posTitle': return loc.posTitle;
      case 'searchItemHint': return loc.searchItemHint;
      case 'searchCustomerHint': return loc.searchCustomerHint;
      case 'walkInCustomer': return loc.walkInCustomer;
      case 'cartEmpty': return loc.cartEmpty;
      case 'totalItems': return loc.totalItems;
      case 'subtotal': return loc.subtotal;
      case 'prevBalance': return loc.prevBalance;
      case 'grandTotal': return loc.grandTotal;
      case 'checkoutButton': return loc.checkoutButton;
      case 'recentSales': return loc.recentSales;
      case 'billTotal': return loc.billTotal;
      case 'paymentLabel': return loc.paymentLabel;
      case 'cashInput': return loc.cashInput;
      case 'bankInput': return loc.bankInput;
      case 'creditInput': return loc.creditInput;
      case 'confirmSale': return loc.confirmSale;
      case 'cancel': return loc.cancel;
      case 'clearCartTitle': return loc.clearCartTitle;
      case 'clearCartMsg': return loc.clearCartMsg;
      case 'clearAll': return loc.clearAll;
      case 'unsavedTitle': return loc.unsavedTitle;
      case 'unsavedMsg': return loc.unsavedMsg;
      case 'exit': return loc.exit;
      case 'addNewCustomer': return loc.addNewCustomer;
      case 'nameEnglish': return loc.nameEnglish;
      case 'nameUrdu': return loc.nameUrdu;
      case 'phoneNum': return loc.phoneNum;
      case 'address': return loc.address;
      case 'creditLimit': return loc.creditLimit;
      case 'saveSelect': return loc.saveSelect;
      case 'price': return loc.price;
      case 'qty': return loc.qty;
      case 'stock': return loc.stock;
      case 'currBal': return loc.currBal;
      case 'changeReturn': return loc.changeReturn;
      case 'insufficientPayment': return loc.insufficientPayment;
      case 'paymentMatch': return loc.paymentMatch;
      case 'deleteBillTitle': return loc.deleteBillTitle;
      case 'deleteBillMsg': return loc.deleteBillMsg;
      case 'delete': return loc.delete;
      case 'saleCompleted': return loc.saleCompleted;
      case 'error': return loc.error;
      default: return key;
    }
  }

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
    if (cartItems.isNotEmpty) {
      final bool? shouldExit = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('unsavedTitle')),
          content: Text(tr('unsavedMsg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('exit'), style: const TextStyle(color: Colors.red)),
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
    final db = await DatabaseHelper.instance.database;
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
        COALESCE(c.name_english, '${tr('walkInCustomer')}') as customer_name,
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
    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('addNewCustomer')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngCtrl, decoration: InputDecoration(labelText: tr('nameEnglish'))),
              TextField(controller: nameUrduCtrl, decoration: InputDecoration(labelText: tr('nameUrdu'))),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: tr('phoneNum'))),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: tr('address'))),
              TextField(controller: creditLimitCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('creditLimit'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () async {
              if (nameEngCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('English Name is required')));
                return;
              }
              String phoneNumber = phoneCtrl.text.trim();
              if (phoneNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone Number is required')));
                return;
              }

              try {
                final db = await DatabaseHelper.instance.database;
                final existingUser = await db.query('customers', where: 'contact_primary = ?', whereArgs: [phoneNumber]);

                if (existingUser.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number "$phoneNumber" already exists!'), backgroundColor: Colors.red));
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Customer '${nameEngCtrl.text}' added!"), backgroundColor: Colors.green));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error')}: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text(tr('saveSelect')),
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
    if (cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('clearCartTitle')),
        content: Text(tr('clearCartMsg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCart();
            },
            child: Text(tr('clearAll'), style: const TextStyle(color: Colors.red)),
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
            double credit = double.tryParse(creditCtrl.text) ?? 0.0;
            
            double totalPayment = cash + bank + (isRegistered ? credit : 0);
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
                    Text(tr('checkoutButton'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        Text('${tr('searchCustomerHint')}: ${selectedCustomerMap!['name_english']}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange[200]!)),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 5),
                              Text('${tr('prevBalance')}: Rs ${oldBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                      
                      _row(tr('billTotal'), 'Rs ${billTotal.toStringAsFixed(0)}', isBold: true, size: 18),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(tr('paymentLabel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      
                      _input(tr('cashInput'), cashCtrl, (v) {
                        setDialogState(() {
                          if (isRegistered) {
                            double remaining = billTotal - (double.tryParse(cashCtrl.text) ?? 0.0) - (double.tryParse(bankCtrl.text) ?? 0.0);
                            creditCtrl.text = remaining > 0 ? remaining.toStringAsFixed(0) : '0';
                          }
                        });
                      }),
                      
                      _input(tr('bankInput'), bankCtrl, (v) {
                        setDialogState(() {
                          if (isRegistered) {
                            double remaining = billTotal - (double.tryParse(cashCtrl.text) ?? 0.0) - (double.tryParse(bankCtrl.text) ?? 0.0);
                            creditCtrl.text = remaining > 0 ? remaining.toStringAsFixed(0) : '0';
                          }
                        });
                      }),
                      
                      if (isRegistered)
                        _input(tr('creditInput'), creditCtrl, (v) { setDialogState(() {}); }, enabled: false),
                      
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
                                    isValid ? tr('paymentMatch') : tr('insufficientPayment'),
                                    style: TextStyle(fontSize: 12, color: isValid ? Colors.green[700] : Colors.red[700]),
                                  ),
                                ],
                              ),
                            ] else ...[
                              if (change > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(tr('changeReturn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Rs ${change.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                                  ],
                                ),
                              if (!isValid)
                                Text(
                                  '${tr('insufficientPayment')} (Need Rs ${(billTotal - totalPayment).toStringAsFixed(0)})',
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
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? Colors.green[700] : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                  ),
                  onPressed: isValid ? () {
                    Navigator.pop(context);
                    _processSale(cash, bank, isRegistered ? credit : 0.0);
                  } : null,
                  child: Text(tr('confirmSale'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    double totalPaid = cash + bank;
    double remainingBalance = grandTotal - totalPaid; 

    try {
      final lastIdRes = await db.rawQuery('SELECT MAX(id) as max_id FROM sales');
      int nextId = 1;
      if (lastIdRes.isNotEmpty && lastIdRes.first['max_id'] != null) {
        nextId = (lastIdRes.first['max_id'] as int) + 1;
      }
      String billNo = 'SB-${nextId.toString().padLeft(6, '0')}';
      
      int saleId = await db.insert('sales', {
        'bill_number': billNo,
        'customer_id': selectedCustomerId,
        'sale_date': now.toIso8601String().split('T')[0],
        'sale_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'grand_total': grandTotal,
        'cash_amount': cash,
        'bank_amount': bank,
        'credit_amount': credit,
        'total_paid': totalPaid,
        'remaining_balance': remainingBalance,
        'created_at': now.toIso8601String(),
      });
      
      await db.transaction((txn) async {
        for (var item in cartItems) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': item['id'],
            'quantity_sold': item['quantity'],
            'unit_price': item['unit_price'],
            'total_price': item['total'],
            'created_at': now.toIso8601String()
          });
          
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
            [item['quantity'], item['id']]
          );
        }
        
        if (selectedCustomerId != null && credit > 0) {
          await txn.rawUpdate(
            'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
            [credit, selectedCustomerId]
          );
        }
      });
      
      _performClearCart();
      await _refreshAllData();
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('saleCompleted')} $billNo'), backgroundColor: Colors.green));
      
    } catch (e) {
      print('Error processing sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error')}: $e'), backgroundColor: Colors.red));
    }
  }

  // --- Delete Sale ---
  Future<void> _deleteSale(int id, String billNumber) async {
    bool? confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: Text(tr('deleteBillTitle')), 
        content: Text(tr('deleteBillMsg')), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () => Navigator.pop(c, true), 
            child: Text(tr('delete'), style: const TextStyle(color: Colors.white))
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
        for (var item in itemsRes) {
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock + ? WHERE id = ?', 
            [item['quantity_sold'], item['product_id']]
          );
        }
        
        double credit = (sale['credit_amount'] as num?)?.toDouble() ?? 0.0;
        if (sale['customer_id'] != null && credit > 0) {
          await txn.rawUpdate(
            'UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?', 
            [credit, sale['customer_id']]
          );
        }
        
        await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
        await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
      });

      await _refreshAllData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill deleted successfully'), backgroundColor: Colors.green));
      
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error')}: $e'), backgroundColor: Colors.red)); 
    }
  }

  // --- REFACTORED BUILD METHOD (RTL FIXES) ---
  @override
  Widget build(BuildContext context) {
    // Determine if RTL is active for specific conditional logic if needed
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('posTitle')), 
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
                    hintText: tr('searchItemHint'), 
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
                            Text('${tr('stock')}:${product['current_stock']}', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                  child: Text(tr('recentSales'), style: const TextStyle(fontWeight: FontWeight.bold))
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
                        title: Text(sale['customer_name'] ?? tr('walkInCustomer'), style: const TextStyle(fontSize: 13)),
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
                          labelText: tr('searchCustomerHint'), 
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
                            trailing: Text('${tr('currBal')}: ${c['outstanding_balance']}'), 
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
                          Text(tr('cartEmpty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
                                    '${tr('stock')}: ${item['current_stock']}', 
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
                                  labelText: tr('price'), 
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
                                  labelText: tr('qty'), 
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
                      Text(tr('totalItems')), 
                      Text('${cartItems.length}')
                    ]
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(tr('subtotal')), 
                      Text('Rs ${subtotal.toStringAsFixed(0)}')
                    ]
                  ),
                  if (previousBalance > 0) 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(tr('prevBalance'), style: const TextStyle(color: Colors.orange, fontSize: 12)), 
                        Text('Rs ${previousBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orange, fontSize: 12))
                      ]
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(tr('grandTotal'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
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
                        tr('checkoutButton'), 
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