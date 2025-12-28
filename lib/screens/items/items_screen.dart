// lib/screens/master_data/items_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/repositories/items_repository.dart';
import '../../l10n/app_localizations.dart';

import '../../models/product_model.dart';
import '../../core/utils/currency_utils.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemsRepository _itemsRepository = ItemsRepository();
  // Pagination & Data State
  List<Product> items = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
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
      _hasNextPage = true;
      items = [];
    });

    try {
      final String searchQuery = searchController.text.trim();
      
      List<Product> result;
      
      if (searchQuery.isNotEmpty) {
        result = await _itemsRepository.searchProducts(searchQuery);
      } else {
        result = await _itemsRepository.getAllProducts();
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
      final String searchQuery = searchController.text.trim();

      List<Product> result;
      
      if (searchQuery.isNotEmpty) {
        result = await _itemsRepository.searchProducts(searchQuery);
      } else {
        result = await _itemsRepository.getAllProducts();
      }

      if (!mounted) return;

      setState(() {
        if (result.isNotEmpty) {
          items.addAll(result);
        } else {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.itemsManagement, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
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
              style: TextStyle(color: colorScheme.onSurface),
              onChanged: (value) {
                // Debouncing could be added here for performance
                _firstLoad(); 
              },
              decoration: InputDecoration(
                labelText: localizations.searchItem,
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
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
                    ? Center(child: Text(localizations.noItemsFound, style: TextStyle(color: colorScheme.onSurface)))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController, // Attach Controller
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final isLowStock = item.currentStock < 5;
                                
                                return Card(
                                  elevation: 2,
                                  shadowColor: colorScheme.shadow.withOpacity(0.2),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  color: colorScheme.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: isLowStock ? colorScheme.errorContainer : colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12)
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.inventory_2_outlined, 
                                          color: isLowStock ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer
                                        )
                                      ),
                                    ),
                                    title: Text(
                                      item.nameEnglish, 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 16)
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item.nameUrdu != null && item.nameUrdu!.isNotEmpty)
                                          Text(item.nameUrdu!, style: TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 14, color: colorScheme.onSurfaceVariant)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isLowStock ? colorScheme.errorContainer : colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${localizations.stock}: ${item.currentStock}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Rs ${item.salePrice}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                                fontSize: 15
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: colorScheme.secondary), 
                                          onPressed: () => _showEditItemDialog(item)
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: colorScheme.error), 
                                          onPressed: () => _deleteItem(item.id!)
                                        ),
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
                              child: Center(child: Text(localizations.endOfList, style: TextStyle(color: colorScheme.onSurfaceVariant))),
                            ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  // ... [Dialog methods _showAddItemDialog, _showEditItemDialog, _deleteItem remain unchanged] ...
  
  // (Include previous helper methods here for complete file)
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _showAddItemDialog() async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final nameEngController = TextEditingController();
    final nameUrduController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(localizations.addItem, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: nameEngController, 
                decoration: _buildInputDecoration(localizations.englishName, Icons.inventory_2_outlined),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameUrduController, 
                decoration: _buildInputDecoration(localizations.urduName, Icons.translate),
                style: TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 16, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController, 
                keyboardType: TextInputType.number, 
                decoration: _buildInputDecoration(localizations.salePrice, Icons.attach_money),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController, 
                keyboardType: TextInputType.number, 
                decoration: _buildInputDecoration(localizations.initialStock, Icons.warehouse),
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () async {
              if (nameEngController.text.isNotEmpty) {
                final newProduct = Product(
                  nameEnglish: nameEngController.text,
                  nameUrdu: nameUrduController.text,
                  salePrice: CurrencyUtils.toPaisas(priceController.text),
                  currentStock: int.tryParse(stockController.text) ?? 0,
                );
                
                await _itemsRepository.addProduct(newProduct);
                
                if (!mounted) return;
                Navigator.pop(context);
                _firstLoad(); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.saveChangesSuccess), backgroundColor: colorScheme.primary));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${localizations.englishName} ${localizations.fieldRequired}"), backgroundColor: colorScheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            child: Text(localizations.save),
          ),
        ],
      ),
    );
    
    nameEngController.dispose();
    nameUrduController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  Future<void> _showEditItemDialog(Product item) async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final nameEngController = TextEditingController(text: item.nameEnglish);
    final nameUrduController = TextEditingController(text: item.nameUrdu);
    final priceController = TextEditingController(text: item.salePrice.toString());
    final stockController = TextEditingController(text: item.currentStock.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(localizations.editItem, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: nameEngController, 
                decoration: _buildInputDecoration(localizations.englishName, Icons.inventory_2_outlined),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameUrduController, 
                decoration: _buildInputDecoration(localizations.urduName, Icons.translate),
                style: TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 16, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController, 
                keyboardType: TextInputType.number, 
                decoration: _buildInputDecoration(localizations.salePrice, Icons.attach_money),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController, 
                keyboardType: TextInputType.number, 
                decoration: _buildInputDecoration(localizations.stockUpdate, Icons.warehouse),
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () async {
              final updatedProduct = item.copyWith(
                nameEnglish: nameEngController.text,
                nameUrdu: nameUrduController.text,
                salePrice: CurrencyUtils.toPaisas(priceController.text),
                currentStock: int.tryParse(stockController.text) ?? 0,
              );
              
              await _itemsRepository.updateProduct(item.id!, updatedProduct);
              
              if (!mounted) return;
              Navigator.pop(context);
              _firstLoad(); // Refresh
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.saveChangesSuccess), backgroundColor: colorScheme.primary));
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            child: Text(localizations.update),
          ),
        ],
      ),
    );

    nameEngController.dispose();
    nameUrduController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  Future<void> _deleteItem(int id) async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(localizations.confirm),
        content: Text(localizations.confirmDeleteItem),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.no, style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            child: Text(localizations.yesDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _itemsRepository.deleteProduct(id);
        
        if (!mounted) return;

        _firstLoad();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.itemDeleted), backgroundColor: colorScheme.primary));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.error}: $e'), backgroundColor: colorScheme.error));
      }
    }
  }
}