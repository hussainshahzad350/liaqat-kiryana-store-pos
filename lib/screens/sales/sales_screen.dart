// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? selectedCustomer;
  double subtotal = 0.0;
  double discount = 0.0;
  double grandTotal = 0.0;
  double previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCustomers();
  }

  Future<void> _loadProducts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products', where: 'is_active = 1');
      setState(() {
        products = result;
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('customers', where: 'is_active = 1');
      setState(() {
        customers = result;
      });
    } catch (e) {
      print('Error loading customers: $e');
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      // Check if product already in cart
      final existingIndex = cartItems.indexWhere((item) => item['id'] == product['id']);
      
      if (existingIndex != -1) {
        // Increase quantity
        cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] ?? 1) + 1;
        cartItems[existingIndex]['total'] = cartItems[existingIndex]['quantity'] * cartItems[existingIndex]['unit_price'];
      } else {
        // Add new item
        cartItems.add({
          'id': product['id'],
          'name_urdu': product['name_urdu'],
          'name_english': product['name_english'],
          'unit_type': product['unit_type'],
          'unit_price': product['sale_price'] ?? 0.0,
          'quantity': 1,
          'total': product['sale_price'] ?? 0.0,
        });
      }
      _calculateTotals();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _updateQuantity(int index, double newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }
    
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
      cartItems[index]['total'] = cartItems[index]['quantity'] * cartItems[index]['unit_price'];
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    subtotal = cartItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
    
    // If customer selected, add previous balance
    double customerBalance = selectedCustomer?['outstanding_balance'] ?? 0.0;
    previousBalance = customerBalance;
    
    grandTotal = subtotal - discount + previousBalance;
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      selectedCustomer = customer;
      _calculateTotals();
    });
  }

  void _clearCart() {
    setState(() {
      cartItems.clear();
      discount = 0.0;
      selectedCustomer = null;
      _calculateTotals();
    });
  }

  Future<void> _completeSale() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کارٹ خالی ہے')),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Generate bill number
      final now = DateTime.now();
      final billNumber = 'SALE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour}${now.minute}${now.second}';
      
      // Insert sale
      final saleId = await db.insert('sales', {
        'bill_number': billNumber,
        'customer_id': selectedCustomer?['id'],
        'sale_date': now.toIso8601String().split('T')[0],
        'sale_time': '${now.hour}:${now.minute}',
        'grand_total': grandTotal,
        'cash_amount': grandTotal, // For now, assume full cash payment
        'total_paid': grandTotal,
        'remaining_balance': 0.0,
        'created_at': now.toIso8601String(),
      });

      // Insert sale items
      for (var item in cartItems) {
        await db.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item['id'],
          'quantity_sold': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total'],
          'created_at': now.toIso8601String(),
        });

        // Update stock
        await db.execute(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
          [item['quantity'], item['id']],
        );
      }

      // Update customer balance if credit customer
      if (selectedCustomer != null && previousBalance > 0) {
        await db.execute(
          'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
          [previousBalance, selectedCustomer!['id']],
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فروخت مکمل ہوئی! بل نمبر: $billNumber')),
      );

      _clearCart();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('غلطی: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروخت / POS'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearCart,
            tooltip: 'کارٹ صاف کریں',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side - Products List (60%)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'آئٹم تلاش کریں',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      // Implement search
                    },
                  ),
                ),

                // Products Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _addToCart(product),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product['name_urdu'] ?? product['name_english'] ?? 'نامعلوم',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Rs ${product['sale_price']?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'اسٹاک: ${product['current_stock']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side - Cart & Checkout (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Customer Selection
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'گاہک منتخب کریں',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<Map<String, dynamic>>(
                            value: selectedCustomer,
                            isExpanded: true,
                            hint: const Text('گاہک منتخب کریں...'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('کیش گاہک'),
                              ),
                              ...customers.map((customer) {
                                return DropdownMenuItem(
                                  value: customer,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customer['name_urdu'] ?? customer['name_english'] ?? 'نامعلوم'),
                                      Text(
                                        'بیلنس: Rs ${customer['outstanding_balance']?.toStringAsFixed(0) ?? '0'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              _selectCustomer(value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cart Items
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Text(
                                  'کارٹ آئٹمز',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'آئٹمز: ${cartItems.length}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: cartItems.isEmpty
                                ? const Center(
                                    child: Text(
                                      'کارٹ خالی ہے',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: cartItems.length,
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.green[100],
                                            child: Text(
                                              (index + 1).toString(),
                                              style: TextStyle(color: Colors.green[700]),
                                            ),
                                          ),
                                          title: Text(item['name_urdu'] ?? item['name_english'] ?? 'نامعلوم'),
                                          subtitle: Text('قیمت: Rs ${item['unit_price']?.toStringAsFixed(0)}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 18),
                                                onPressed: () {
                                                  _updateQuantity(index, item['quantity'] - 1);
                                                },
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item['quantity'].toStringAsFixed(0),
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 18),
                                                onPressed: () {
                                                  _updateQuantity(index, item['quantity'] + 1);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                onPressed: () {
                                                  _removeFromCart(index);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Totals & Checkout
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Subtotal
                          Row(
                            children: [
                              const Text('سب ٹوٹل:'),
                              const Spacer(),
                              Text('Rs ${subtotal.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Previous Balance (if customer selected)
                          if (selectedCustomer != null && previousBalance > 0) ...[
                            Row(
                              children: [
                                const Text('پچھلا بیلنس:'),
                                const Spacer(),
                                Text(
                                  'Rs ${previousBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Discount
                          Row(
                            children: [
                              const Text('ڈسکاؤنٹ:'),
                              const Spacer(),
                              Text('Rs ${discount.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Divider
                          const Divider(),
                          const SizedBox(height: 8),

                          // Grand Total
                          Row(
                            children: [
                              const Text(
                                'کل رقم:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Rs ${grandTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checkout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _completeSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'فروخت مکمل کریں',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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