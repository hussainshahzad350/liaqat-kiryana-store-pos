// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('customers', orderBy: 'name_english ASC');
      
      setState(() {
        customers = result;
        filteredCustomers = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => isLoading = false);
      
      // Temporary dummy data
      setState(() {
        customers = [
          {
            'id': 1,
            'name_english': 'Ali Khan',
            'name_urdu': 'علی خان',
            'contact_primary': '0300-1111111',
            'credit_limit': 10000.0,
            'outstanding_balance': 2500.0,
          },
          {
            'id': 2,
            'name_english': 'Sami Ahmed',
            'name_urdu': 'سامی احمد',
            'contact_primary': '0321-2222222',
            'credit_limit': 5000.0,
            'outstanding_balance': 1200.0,
          },
          {
            'id': 3,
            'name_english': 'Bilal Hassan',
            'name_urdu': 'بلال حسن',
            'contact_primary': '0333-3333333',
            'credit_limit': 2000.0,
            'outstanding_balance': 0.0,
          },
        ];
        filteredCustomers = customers;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      filteredCustomers = customers.where((customer) {
        final nameEn = customer['name_english']?.toString().toLowerCase() ?? '';
        final nameUr = customer['name_urdu']?.toString().toLowerCase() ?? '';
        final phone = customer['contact_primary']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        
        return nameEn.contains(searchLower) || 
               nameUr.contains(searchLower) || 
               phone.contains(searchLower);
      }).toList();
    });
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerDialog(
        onSave: () {
          _loadCustomers();
        },
      ),
    );
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerDialog(
        customer: customer,
        onSave: () {
          _loadCustomers();
        },
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        customer: customer,
        onSave: () {
          _loadCustomers();
        },
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: const Text('کیا آپ واقعی اس کسٹمر کو حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نہیں'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں، حذف کریں'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('customers', where: 'id = ?', whereArgs: [id]);
        _loadCustomers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کسٹمر حذف ہو گیا')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('غلطی: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کسٹمرز مينيجمنٹ'),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'تازہ کریں',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'کسٹمر تلاش کریں',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _filterCustomers('');
                  },
                ),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'کل کسٹمرز',
                            style: TextStyle(color: Colors.blue),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            filteredCustomers.length.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'کل بیلنس',
                            style: TextStyle(color: Colors.green),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Rs ${_calculateTotalBalance().toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Customers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCustomers.isEmpty
                    ? const Center(child: Text('کوئی کسٹمر نہیں ملا'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final balance = customer['outstanding_balance'] ?? 0.0;
                          final limit = customer['credit_limit'] ?? 0.0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getCustomerColor(balance),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    (customer['name_english']?[0] ?? 'C').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                customer['name_urdu'] ?? customer['name_english'] ?? 'نامعلوم',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('فون: ${customer['contact_primary'] ?? 'N/A'}'),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'بیلنس: Rs ${balance.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: balance > 0 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'حد: Rs ${limit.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('ایڈٹ کریں'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'payment',
                                    child: Row(
                                      children: [
                                        Icon(Icons.payment, size: 20),
                                        SizedBox(width: 8),
                                        Text('پیمنٹ کریں'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 20),
                                        SizedBox(width: 8),
                                        Text('تفصیل دیکھیں'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('حذف کریں', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _showEditCustomerDialog(customer);
                                      break;
                                    case 'payment':
                                      _showPaymentDialog(customer);
                                      break;
                                    case 'view':
                                      _viewCustomerDetails(customer);
                                      break;
                                    case 'delete':
                                      _deleteCustomer(customer['id']);
                                      break;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  double _calculateTotalBalance() {
    return filteredCustomers.fold(0.0, (sum, customer) {
      return sum + (customer['outstanding_balance'] ?? 0.0);
    });
  }

  Color _getCustomerColor(double balance) {
    if (balance == 0) return Colors.green;
    if (balance < 1000) return Colors.blue;
    if (balance < 5000) return Colors.orange;
    return Colors.red;
  }

  void _viewCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer['name_urdu'] ?? customer['name_english'] ?? 'کسٹمر'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('انگریزی نام:', customer['name_english']),
              _buildDetailRow('اردو نام:', customer['name_urdu']),
              _buildDetailRow('فون نمبر:', customer['contact_primary']),
              _buildDetailRow('پتہ:', customer['address']),
              const SizedBox(height: 10),
              const Divider(),
              _buildDetailRow('کریڈٹ حد:', 'Rs ${customer['credit_limit']?.toStringAsFixed(0) ?? '0'}'),
              _buildDetailRow('موجودہ بیلنس:', 'Rs ${customer['outstanding_balance']?.toStringAsFixed(0) ?? '0'}'),
              _buildDetailRow('کل خریداری:', 'Rs ${customer['total_purchases']?.toStringAsFixed(0) ?? '0'}'),
              _buildDetailRow('آخری خریداری:', customer['last_sale_date'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بند کریں'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}

// ==================== Customer Dialog ====================
class CustomerDialog extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSave;

  const CustomerDialog({
    super.key,
    this.customer,
    required this.onSave,
  });

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameUrController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameEnController.text = widget.customer!['name_english'] ?? '';
      _nameUrController.text = widget.customer!['name_urdu'] ?? '';
      _phoneController.text = widget.customer!['contact_primary'] ?? '';
      _addressController.text = widget.customer!['address'] ?? '';
      _creditLimitController.text = widget.customer!['credit_limit']?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final db = await DatabaseHelper.instance.database;
        
        final customerData = {
          'name_english': _nameEnController.text,
          'name_urdu': _nameUrController.text,
          'contact_primary': _phoneController.text,
          'address': _addressController.text,
          'credit_limit': double.parse(_creditLimitController.text),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (widget.customer == null) {
          // Add new customer
          await db.insert('customers', customerData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نیا کسٹمر شامل ہو گیا')),
          );
        } else {
          // Update existing customer
          await db.update(
            'customers',
            customerData,
            where: 'id = ?',
            whereArgs: [widget.customer!['id']],
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کسٹمر اپ ڈیٹ ہو گیا')),
          );
        }

        widget.onSave();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('غلطی: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'نیا کسٹمر' : 'کسٹمر ایڈٹ کریں'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'انگریزی نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameUrController,
                decoration: const InputDecoration(
                  labelText: 'اردو نام',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'فون نمبر *',
                  border: OutlineInputBorder(),
                  prefixText: '+92 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم فون نمبر درج کریں';
                  }
                  if (value.length < 11) {
                    return 'فون نمبر کم از کم 11 ہندسوں کا ہونا چاہیے';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'پتہ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'کریڈٹ حد',
                  border: OutlineInputBorder(),
                  prefixText: 'Rs ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('منسوخ'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          child: const Text('محفوظ کریں'),
        ),
      ],
    );
  }
}

// ==================== Payment Dialog ====================
class PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onSave;

  const PaymentDialog({
    super.key,
    required this.customer,
    required this.onSave,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.customer['outstanding_balance']?.toString() ?? '0';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('براہ کرم درست رقم درج کریں')),
        );
        return;
      }

      final db = await DatabaseHelper.instance.database;
      
      // Update customer balance
      await db.execute(
        'UPDATE customers SET outstanding_balance = outstanding_balance - ?, total_payments = total_payments + ? WHERE id = ?',
        [amount, amount, widget.customer['id']],
      );

      // Record in ledger (you need to create customer_ledger table)
      // await db.insert('customer_ledger', {
      //   'customer_id': widget.customer['id'],
      //   'amount': -amount,
      //   'description': _descriptionController.text,
      //   'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پیمنٹ ریکارڈ ہو گئی')),
      );

      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('غلطی: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('پیمنٹ ریکارڈ کریں'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer['name_urdu'] ?? widget.customer['name_english'] ?? 'کسٹمر',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'موجودہ بیلنس: Rs ${widget.customer['outstanding_balance']?.toStringAsFixed(0) ?? '0'}',
              style: TextStyle(
                color: (widget.customer['outstanding_balance'] ?? 0) > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'رقم *',
                border: OutlineInputBorder(),
                prefixText: 'Rs ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'تفصیل',
                border: OutlineInputBorder(),
                hintText: 'مثال: کیش پیمنٹ، بینک ٹرانسفر',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('منسوخ'),
        ),
        ElevatedButton(
          onPressed: _recordPayment,
          child: const Text('پیمنٹ محفوظ کریں'),
        ),
      ],
    );
  }
}