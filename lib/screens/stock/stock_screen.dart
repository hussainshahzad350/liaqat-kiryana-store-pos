// lib/screens/stock/stock_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../models/product_model.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.stockManagement),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.shopping_cart), text: loc.purchase),
            Tab(icon: const Icon(Icons.remove_shopping_cart), text: loc.sales),
            Tab(icon: const Icon(Icons.inventory), text: loc.stockView),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PurchaseTab(),
          SalesTab(),
          StockViewTab(), // NOW FIXED & DYNAMIC
        ],
      ),
    );
  }
}

// ==================== Purchase Tab ====================
class PurchaseTab extends StatefulWidget {
  const PurchaseTab({super.key});

  @override
  State<PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<PurchaseTab> {
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  late final SuppliersRepository _suppliersRepository;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    // Note: If you have thousands of suppliers, this dropdown should strictly 
    // be replaced with a Searchable Dialog. For <500 suppliers, this is fine.
    final data = await _suppliersRepository.getSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.newPurchase,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.selectSupplier),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: loc.chooseSupplier,
                    ),
                    value: _selectedSupplierId,
                    items: _suppliers.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'].toString(),
                        child: Text("${s['name_english']} (${s['contact_primary'] ?? ''})"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                    },
                    disabledHint: Text(loc.noSuppliersFound), 
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Placeholder for future Items/Cart logic
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(loc.items, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(loc.addItem),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Table(
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Colors.grey),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.item, style: const TextStyle(color: Colors.white))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.quantity, style: const TextStyle(color: Colors.white))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.price, style: const TextStyle(color: Colors.white))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.total, style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // Save Logic to be implemented
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[700],
              ),
              child: Text(loc.savePurchase, style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Sales Tab ====================
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          Text(loc.salesRecord, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(loc.salesHistoryNote, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/sales'),
            child: Text(loc.newSale),
          ),
        ],
      ),
    );
  }
}

// ==================== Stock View Tab (FIXED) ====================
class StockViewTab extends StatefulWidget {
  const StockViewTab({super.key});

  @override
  State<StockViewTab> createState() => _StockViewTabState();
}

class _StockViewTabState extends State<StockViewTab> {
  // Repository
  final ItemsRepository _itemsRepository = ItemsRepository();
  
  // Pagination State
  List<Product> items = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;

  // Stats State
  int _totalItemsCount = 0;
  double _totalStockValue = 0.0;

  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadStats();
    _firstLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _hasNextPage) {
      _loadMore();
    }
  }

  Future<void> _loadStats() async {
    final count = await _itemsRepository.getTotalProductsCount();
    final value = await _itemsRepository.getTotalStockValue();
    if (mounted) {
      setState(() {
        _totalItemsCount = count;
        _totalStockValue = value;
      });
    }
  }

  Future<void> _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 0;
      _hasNextPage = true;
      items = [];
    });

    try {
      final query = _searchController.text.trim();
      
      List<Product> result;
      
      if (query.isNotEmpty) {
        result = await _itemsRepository.searchProducts(query);
      } else {
        result = await _itemsRepository.getAllProducts();
      }

      if (!mounted) return;
      setState(() {
        items = result.length > _limit ? result.sublist(0, _limit) : result;
        _isFirstLoadRunning = false;
        if (result.length < _limit) _hasNextPage = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isFirstLoadRunning = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;
    setState(() => _isLoadMoreRunning = true);

    try {
      final query = _searchController.text.trim();
      _page++;
      final offset = _page * _limit;

      List<Product> result;
      if (query.isNotEmpty) {
        result = await _itemsRepository.searchProducts(query);
      } else {
        result = await _itemsRepository.getAllProducts();
      }

      // Implement client-side pagination
      final startIndex = offset;
      final endIndex = (offset + _limit).clamp(0, result.length);
      final paginatedResult = startIndex < result.length 
          ? result.sublist(startIndex, endIndex) 
          : <Product>[];

      if (!mounted) return;
      setState(() {
        if (paginatedResult.isNotEmpty) {
          items.addAll(paginatedResult);
        } else {
          _hasNextPage = false;
        }
        if (paginatedResult.length < _limit) _hasNextPage = false;
        _isLoadMoreRunning = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadMoreRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // 1. Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => _firstLoad(),
            decoration: InputDecoration(
              labelText: loc.searchStock,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(loc.totalItems, style: TextStyle(color: Colors.green[800], fontSize: 12)),
                        Text(
                          '$_totalItemsCount',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(loc.stockValue, style: TextStyle(color: Colors.blue[800], fontSize: 12)),
                        Text(
                          'Rs ${_totalStockValue.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Paginated List
          Expanded(
            child: _isFirstLoadRunning
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(child: Text(loc.noItemsFound))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final stock = (item.currentStock as num?)?.toDouble() ?? 0.0;
                                const minStock = 10.0; // Default alert threshold
                                final price = ((item.salePrice as num?)?.toDouble() ?? 0.0) / 100.0;
                                final totalVal = stock * price; // Or cost price if available

                                // Highlight low stock
                                final isLow = stock <= minStock;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      side: isLow ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    title: Text(
                                      item.nameEnglish,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${loc.price}: $price | ${loc.total}: ${totalVal.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLow ? Colors.red[100] : Colors.green[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$stock',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isLow ? Colors.red[900] : Colors.green[900],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_isLoadMoreRunning)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}