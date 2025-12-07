// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  // ✅ FIXED: Controller marked final
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // ✅ FIXED: Dispose controller
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products', orderBy: 'name_english ASC');
      
      // ✅ FIXED: Check mounted before setState
      if (!mounted) return;
      
      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آئٹمز مينيجمنٹ'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddItemDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'آئٹم تلاش کريں',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _loadItems();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('کوئی آئٹم نہيں ملا'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Center(child: Icon(Icons.inventory, color: Colors.green)),
                              ),
                              title: Text(item['name_urdu'] ?? item['name_english'] ?? 'نامعلوم', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('اسٹاک: ${item['current_stock']} | قیمت: ${item['sale_price']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditItemDialog(item)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddItemDialog() {
    // ✅ FIXED: Added Controllers and Insert Logic
    final nameEngController = TextEditingController();
    final nameUrduController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نیا آئٹم شامل کريں'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngController, decoration: const InputDecoration(labelText: 'انگریزی نام')),
              const SizedBox(height: 10),
              TextField(controller: nameUrduController, decoration: const InputDecoration(labelText: 'اردو نام')),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروخت')),
              const SizedBox(height: 10),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ابتدائی اسٹاک')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () async {
              if (nameEngController.text.isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('products', {
                  'name_english': nameEngController.text,
                  'name_urdu': nameUrduController.text,
                  'sale_price': double.tryParse(priceController.text) ?? 0,
                  'current_stock': double.tryParse(stockController.text) ?? 0,
                  'created_at': DateTime.now().toIso8601String(),
                });
                
                // ✅ FIXED: Check mounted before using context
                if (!mounted) return;
                
                Navigator.pop(context);
                _loadItems();
              }
            },
            child: const Text('محفوظ کريں'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    // ✅ FIXED: Implemented Edit Logic with pre-filled controllers
    final nameEngController = TextEditingController(text: item['name_english']);
    final nameUrduController = TextEditingController(text: item['name_urdu']);
    final priceController = TextEditingController(text: item['sale_price'].toString());
    final stockController = TextEditingController(text: item['current_stock'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('آئٹم میں ترمیم کریں'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngController, decoration: const InputDecoration(labelText: 'انگریزی نام')),
              const SizedBox(height: 10),
              TextField(controller: nameUrduController, decoration: const InputDecoration(labelText: 'اردو نام')),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروخت')),
              const SizedBox(height: 10),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'اسٹاک اپڈیٹ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.update(
                'products',
                {
                  'name_english': nameEngController.text,
                  'name_urdu': nameUrduController.text,
                  'sale_price': double.tryParse(priceController.text) ?? 0,
                  'current_stock': double.tryParse(stockController.text) ?? 0,
                },
                where: 'id = ?',
                whereArgs: [item['id']],
              );
              
              // ✅ FIXED: Check mounted before using context
              if (!mounted) return;

              Navigator.pop(context);
              _loadItems();
            },
            child: const Text('اپڈیٹ کريں'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: const Text('کیا آپ واقعی اس آئٹم کو حذف کرنا چاہتے ہيں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('نہيں')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں، حذف کريں'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('products', where: 'id = ?', whereArgs: [id]);
        
        // ✅ FIXED: Check mounted before using context
        if (!mounted) return;

        _loadItems();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('آئٹم حذف ہو گيا')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('غلطی: $e')));
      }
    }
  }
}