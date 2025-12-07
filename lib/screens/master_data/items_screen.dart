// lib/screens/master_data/items_screen.dart - مکمل Functional
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ✅ Load Items from Database
  Future<void> _loadItems() async {
    setState(() => isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products', orderBy: 'name_english ASC');
      
      setState(() {
        allItems = result;
        filteredItems = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading items: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خرابی: $e')),
        );
      }
    }
  }

  // ✅ Search Functionality
  void _searchItems(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = allItems;
      } else {
        filteredItems = allItems.where((item) {
          final nameEn = (item['name_english'] ?? '').toString().toLowerCase();
          final nameUr = (item['name_urdu'] ?? '').toString().toLowerCase();
          final code = (item['item_code'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          
          return nameEn.contains(searchLower) || 
                 nameUr.contains(searchLower) || 
                 code.contains(searchLower);
        }).toList();
      }
    });
  }

  // ✅ Delete Item
  Future<void> _deleteItem(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: Text('کیا آپ "$name" کو حذف کرنا چاہتے ہیں؟'),
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
        await db.delete('products', where: 'id = ?', whereArgs: [id]);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ آئٹم حذف ہو گیا'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadItems(); // Reload list
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
        title: const Text('آئٹمز مینیجمنٹ'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: 'تازہ کریں',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showItemDialog(),
            tooltip: 'نیا آئٹم',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'آئٹم تلاش کریں (نام، کوڈ)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchItems('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchItems,
            ),
          ),

          // ✅ Items Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'کل آئٹمز: ${filteredItems.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Items List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              searchController.text.isEmpty
                                  ? 'کوئی آئٹم نہیں ملا'
                                  : 'تلاش کا کوئی نتیجہ نہیں',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final stock = (item['current_stock'] ?? 0).toDouble();
                          final minStock = (item['min_stock_alert'] ?? 0).toDouble();
                          final isLowStock = stock <= minStock;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isLowStock ? Colors.red[50] : null,
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isLowStock
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    isLowStock ? Icons.warning : Icons.inventory,
                                    color: isLowStock ? Colors.red : Colors.green,
                                    size: 30,
                                  ),
                                ),
                              ),
                              title: Text(
                                item['name_urdu'] ?? item['name_english'] ?? 'نامعلوم',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('کوڈ: ${item['item_code'] ?? 'N/A'}'),
                                  Text(
                                    'اسٹاک: ${stock.toStringAsFixed(0)} ${item['unit_type'] ?? ''}',
                                    style: TextStyle(
                                      color: isLowStock ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('قیمت: Rs ${item['sale_price']?.toStringAsFixed(0) ?? '0'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showItemDialog(item: item),
                                    tooltip: 'ایڈٹ',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteItem(
                                      item['id'],
                                      item['name_urdu'] ?? item['name_english'] ?? '',
                                    ),
                                    tooltip: 'حذف کریں',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('نیا آئٹم'),
      ),
    );
  }

  // ✅ Add/Edit Item Dialog
  void _showItemDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    
    showDialog(
      context: context,
      builder: (context) => ItemDialog(
        item: item,
        onSave: () {
          _loadItems(); // Reload items after save
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ==================== Item Dialog (Add/Edit) ====================
class ItemDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSave;

  const ItemDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameUrController = TextEditingController();
  final _codeController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedUnit = 'KG';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.item != null) {
      _nameEnController.text = widget.item!['name_english'] ?? '';
      _nameUrController.text = widget.item!['name_urdu'] ?? '';
      _codeController.text = widget.item!['item_code'] ?? '';
      _stockController.text = (widget.item!['current_stock'] ?? 0).toString();
      _minStockController.text = (widget.item!['min_stock_alert'] ?? 10).toString();
      _costController.text = (widget.item!['avg_cost_price'] ?? 0).toString();
      _priceController.text = (widget.item!['sale_price'] ?? 0).toString();
      _selectedUnit = widget.item!['unit_type'] ?? 'KG';
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    _codeController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ✅ Save Item to Database
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = await DatabaseHelper.instance.database;
      
      final itemData = {
        'name_english': _nameEnController.text.trim(),
        'name_urdu': _nameUrController.text.trim(),
        'item_code': _codeController.text.trim(),
        'unit_type': _selectedUnit,
        'current_stock': double.parse(_stockController.text),
        'min_stock_alert': double.parse(_minStockController.text),
        'avg_cost_price': double.parse(_costController.text),
        'sale_price': double.parse(_priceController.text),
        'is_active': 1,
      };

      if (widget.item == null) {
        // Add new item
        await db.insert('products', itemData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ نیا آئٹم شامل ہو گیا'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing item
        await db.update(
          'products',
          itemData,
          where: 'id = ?',
          whereArgs: [widget.item!['id']],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ آئٹم اپ ڈیٹ ہو گیا'),
              backgroundColor: Colors.green,
            ),
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
      title: Text(widget.item == null ? 'نیا آئٹم شامل کریں' : 'آئٹم ایڈٹ کریں'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // English Name
              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'انگریزی نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'براہ کرم نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Urdu Name
              TextFormField(
                controller: _nameUrController,
                decoration: const InputDecoration(
                  labelText: 'اردو نام',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Item Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'آئٹم کوڈ',
                  border: OutlineInputBorder(),
                  hintText: 'مثال: PRD001',
                ),
              ),
              const SizedBox(height: 10),

              // Unit Type
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'یونٹ *',
                  border: OutlineInputBorder(),
                ),
                items: ['KG', 'Gram', 'Liter', 'ML', 'Piece', 'Dozen', 'Packet']
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedUnit = value!),
              ),
              const SizedBox(height: 10),

              // Current Stock & Min Alert
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'موجودہ اسٹاک *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'ضروری ہے';
                        if (double.tryParse(value) == null) return 'نمبر درج کریں';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'کم اسٹاک الرٹ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) return 'نمبر';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cost Price & Sale Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'خریداری قیمت',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'فروخت قیمت *',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'ضروری';
                        if (double.tryParse(value) == null) return 'نمبر';
                        return null;
                      },
                    ),
                  ),
                ],
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
          onPressed: _isSaving ? null : _saveItem,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('محفوظ کریں'),
        ),
      ],
    );
  }
}