// lib/screens/stock/stock_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../models/product_model.dart';
import '../../core/utils/currency_utils.dart';
import '../../domain/entities/money.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.stockManagement, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: colorScheme.onPrimary,
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
  final _suppliersRepository = SuppliersRepository();

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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.newPurchase,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 20),
          
          Card(
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.selectSupplier),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: loc.chooseSupplier,
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
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
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(loc.items, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
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
                        decoration: BoxDecoration(color: colorScheme.primaryContainer),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.item, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.quantity, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.price, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(loc.total, style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
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
              child: Text(loc.savePurchase, style: const TextStyle(fontSize: 16)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 100, color: colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(loc.salesRecord, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          Text(loc.salesHistoryNote, style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
  Money _totalStockValue = const Money(0);

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
        _totalStockValue = Money(value);
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

  void _showStockDialog(Product product) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController stockCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.adjustStock, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${loc.current}: ${product.currentStock}', style: TextStyle(color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: loc.quantity,
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), // Logic placeholder
            child: Text(loc.save),
          )
        ],
      ),
    ).then((_) => stockCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(loc.totalItems, style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 12)),
                        Text(
                          '$_totalItemsCount',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(loc.stockValue, style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 12)),
                        Text(
                          CurrencyUtils.formatNoDecimal(_totalStockValue),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
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
                    ? Center(child: Text(loc.noItemsFound, style: TextStyle(color: colorScheme.onSurface)))
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
                                final int pricePaisas = item.salePrice;
                                final int totalValPaisas = (stock * pricePaisas).round();

                                // Highlight low stock
                                final isLow = stock <= minStock;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: colorScheme.surface,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      side: isLow ? BorderSide(color: colorScheme.error, width: 1) : BorderSide.none,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    onTap: () => _showStockDialog(item),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    title: Text(
                                      item.nameEnglish,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                    ),
                                    subtitle: Text(
                                      '${loc.price}: ${CurrencyUtils.formatNoDecimal(Money(pricePaisas))} | ${loc.total}: ${CurrencyUtils.formatNoDecimal(Money(totalValPaisas))}',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLow ? colorScheme.errorContainer : colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$stock',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isLow ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
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