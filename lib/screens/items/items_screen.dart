// lib/screens/master_data/items_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  // Pagination & Data State
  List<Map<String, dynamic>> items = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;

  late ScrollController _scrollController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _firstLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 && // Load when near bottom
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _hasNextPage) {
      _loadMoreItems();
    }
  }

  // --- Data Loading Logic ---

  Future<void> _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 0;
      _hasNextPage = true;
      items = [];
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final String searchQuery = searchController.text.trim();
      
      List<Map<String, dynamic>> result;
      
      if (searchQuery.isNotEmpty) {
        // FIX: DB-Side Search for Scalability
        result = await db.query(
          'products',
          where: 'name_english LIKE ? OR name_urdu LIKE ?',
          whereArgs: ['%$searchQuery%', '%$searchQuery%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      } else {
        // FIX: Pagination (Limit/Offset)
        result = await db.query(
          'products',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      }

      if (!mounted) return;

      setState(() {
        items = result;
        _isFirstLoadRunning = false;
        // If we got fewer items than limit, no more pages exist
        if (result.length < _limit) {
          _hasNextPage = false;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isFirstLoadRunning = false);
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;

    setState(() => _isLoadMoreRunning = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final String searchQuery = searchController.text.trim();
      _page += 1; // Increment page for offset calculation
      final int offset = _page * _limit;

      List<Map<String, dynamic>> result;
      
      if (searchQuery.isNotEmpty) {
        result = await db.query(
          'products',
          where: 'name_english LIKE ? OR name_urdu LIKE ?',
          whereArgs: ['%$searchQuery%', '%$searchQuery%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      } else {
        result = await db.query(
          'products',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      }

      if (!mounted) return;

      setState(() {
        if (result.isNotEmpty) {
          items.addAll(result);
        } else {
          _hasNextPage = false;
        }
        
        // If strictly less than limit, end reached
        if (result.length < _limit) {
          _hasNextPage = false;
        }
        
        _isLoadMoreRunning = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadMoreRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.itemsManagement),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddItemDialog),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                // Debouncing could be added here for performance
                _firstLoad(); 
              },
              decoration: InputDecoration(
                labelText: localizations.searchItem,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _firstLoad();
                  },
                ),
              ),
            ),
          ),
          
          // List
          Expanded(
            child: _isFirstLoadRunning
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(child: Text(localizations.noItemsFound))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController, // Attach Controller
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
                          // Bottom Loading Indicator
                          if (_isLoadMoreRunning)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          // End of List Message
                          if (!_hasNextPage && items.isNotEmpty)
                             Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: Text(localizations.endOfList, style: const TextStyle(color: Colors.grey))),
                            ),
                        ],
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

  // ... [Dialog methods _showAddItemDialog, _showEditItemDialog, _deleteItem remain unchanged] ...
  
  // (Include previous helper methods here for complete file)
  void _showAddItemDialog() {
    final localizations = AppLocalizations.of(context)!;
    final nameEngController = TextEditingController();
    final nameUrduController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addItem),
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
                _firstLoad(); // Refresh list
              }
            },
            child: Text(localizations.save),
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
        title: Text(localizations.editItem),
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
              _firstLoad(); // Refresh
            },
            child: Text(localizations.update),
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

        _firstLoad();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.itemDeleted)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.error}: $e')));
      }
    }
  }
}