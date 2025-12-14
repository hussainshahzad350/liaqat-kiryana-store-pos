// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart'; // ✅ Imported Localizations

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Map<String, dynamic>> items = [];
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

  Future<void> _loadItems() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products', orderBy: 'name_english ASC');
      
      if (!mounted) return;
      
      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // ✅ Localization helper

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.itemsManagement), // ✅ Localized Title
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
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
                labelText: localizations.searchItem, // ✅ Localized Label
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
                    ? Center(child: Text(localizations.noItemsFound)) // ✅ Localized
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
                              title: Text(item['name_urdu'] ?? item['name_english'] ?? localizations.unknown, style: const TextStyle(fontWeight: FontWeight.bold)),
                              // ✅ Localized Subtitle (Stock | Price)
                              subtitle: Text('${localizations.stock}: ${item['current_stock']} | ${localizations.price}: ${item['sale_price']}'),
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
    final localizations = AppLocalizations.of(context)!;
    final nameEngController = TextEditingController();
    final nameUrduController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addItem), // ✅ Localized
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngController, decoration: InputDecoration(labelText: localizations.englishName)),
              const SizedBox(height: 10),
              TextField(controller: nameUrduController, decoration: InputDecoration(labelText: localizations.urduName)),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: localizations.salePrice)),
              const SizedBox(height: 10),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: localizations.initialStock)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
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
                
                if (!mounted) return;
                Navigator.pop(context);
                _loadItems();
              }
            },
            child: Text(localizations.save), // ✅ Localized
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final localizations = AppLocalizations.of(context)!;
    final nameEngController = TextEditingController(text: item['name_english']);
    final nameUrduController = TextEditingController(text: item['name_urdu']);
    final priceController = TextEditingController(text: item['sale_price'].toString());
    final stockController = TextEditingController(text: item['current_stock'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.editItem), // ✅ Localized
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEngController, decoration: InputDecoration(labelText: localizations.englishName)),
              const SizedBox(height: 10),
              TextField(controller: nameUrduController, decoration: InputDecoration(labelText: localizations.urduName)),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: localizations.salePrice)),
              const SizedBox(height: 10),
              TextField(controller: stockController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: localizations.stockUpdate)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
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
              
              if (!mounted) return;
              Navigator.pop(context);
              _loadItems();
            },
            child: Text(localizations.update), // ✅ Localized
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final localizations = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirm),
        content: Text(localizations.confirmDeleteItem),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.no)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.yesDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('products', where: 'id = ?', whereArgs: [id]);
        
        if (!mounted) return;

        _loadItems();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.itemDeleted)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.error}: $e')));
      }
    }
  }
}