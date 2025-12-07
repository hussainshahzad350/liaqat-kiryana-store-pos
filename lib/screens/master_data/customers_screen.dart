// lib/screens/master_data/customers_screen.dart - مکمل Functional
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> allCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ✅ Load Customers
  Future<void> _loadCustomers() async {
    setState(() => isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('customers', orderBy: 'name_english ASC');
      
      setState(() {
        allCustomers = result;
        filteredCustomers = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() => isLoading = false);
    }
  }

  // ✅ Search Customers
  void _searchCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = allCustomers;
      } else {
        filteredCustomers = allCustomers.where((customer) {
          final nameEn = (customer['name_english'] ?? '').toString().toLowerCase();
          final nameUr = (customer['name_urdu'] ?? '').toString().toLowerCase();
          final phone = (customer['contact_primary'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          
          return nameEn.contains(searchLower) || 
                 nameUr.contains(searchLower) || 
                 phone.contains(searchLower);
        }).toList();
      }
    });
  }

  // ✅ Delete Customer
  Future<void> _deleteCustomer(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: Text('کیا "$name" کو حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نہیں'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('customers', where: 'id = ?', whereArgs: [id]);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ کسٹمر حذف ہو گیا'), backgroundColor: Colors.green),
        );
        
        _loadCustomers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خرابی: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کسٹمرز مینیجمنٹ'),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
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
                labelText: 'کسٹمر تلاش کریں (نام، فون)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchCustomers('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchCustomers,
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
                          const Text('کل کسٹمرز', style: TextStyle(color: Colors.blue)),
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
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('کل بیلنس', style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 5),
                          Text(
                            'Rs ${_calculateTotalBalance().toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
                          final balance = (customer['outstanding_balance'] ?? 0).toDouble();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: balance > 0 ? Colors.red : Colors.green,
                                child: Text(
                                  (customer['name_english']?[0] ?? 'C').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                                  Text(
                                    'بیلنس: Rs ${balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: balance > 0 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                        Text('ایڈٹ'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('حذف', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showCustomerDialog(customer: customer);
                                  } else if (value == 'delete') {
                                    _deleteCustomer(
                                      customer['id'],
                                      customer['name_urdu'] ?? customer['name_english'] ?? '',
                                    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        backgroundColor: Colors.purple[700],
        icon: const Icon(Icons.add),
        label: const Text('نیا کسٹمر'),
      ),
    );
  }

  double _calculateTotalBalance() {
    return filteredCustomers.fold(0.0, (sum, customer) {
      return sum + ((customer['outstanding_balance'] ?? 0) as num).toDouble();
    });
  }

  void _showCustomerDialog({Map<String, dynamic>? customer}) {
    showDialog(
      context: context,
      builder: (context) => CustomerDialog(
        customer: customer,
        onSave: () {
          _loadCustomers();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ==================== Customer Dialog ====================
class CustomerDialog extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback onSave;

  const CustomerDialog({super.key, this.customer, required this.onSave});

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameEnController.text = widget.customer!['name_english'] ?? '';
      _nameUrController.text = widget.customer!['name_urdu'] ?? '';
      _phoneController.text = widget.customer!['contact_primary'] ?? '';
      _addressController.text = widget.customer!['address'] ?? '';
      _creditLimitController.text = (widget.customer!['credit_limit'] ?? 0).toString();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = await DatabaseHelper.instance.database;
      
      final customerData = {
        'name_english': _nameEnController.text.trim(),
        'name_urdu': _nameUrController.text.trim(),
        'contact_primary': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'credit_limit': double.parse(_creditLimitController.text.isEmpty ? '0' : _creditLimitController.text),
        'is_active': 1,
      };

      if (widget.customer == null) {
        await db.insert('customers', customerData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ نیا کسٹمر شامل ہو گیا'), backgroundColor: Colors.green),
          );
        }
      } else {
        await db.update('customers', customerData, where: 'id = ?', whereArgs: [widget.customer!['id']]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ کسٹمر اپ ڈیٹ ہو گیا'), backgroundColor: Colors.green),
          );
        }
      }

      widget.onSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خرابی: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'نیا کسٹمر' : 'کسٹمر ایڈٹ'),
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
                validator: (v) => v == null || v.trim().isEmpty ? 'ضروری ہے' : null,
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
                  hintText: '0300-1234567',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'ضروری ہے' : null,
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('منسوخ'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCustomer,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('محفوظ کریں'),
        ),
      ],
    );
  }
}