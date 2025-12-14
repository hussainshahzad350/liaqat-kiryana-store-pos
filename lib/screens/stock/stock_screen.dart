// lib/screens/stock/stock_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';

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
          StockViewTab(),
        ],
      ),
    );
  }
}

// ==================== Purchase Tab (Refactored) ====================
class PurchaseTab extends StatefulWidget {
  const PurchaseTab({super.key});

  @override
  State<PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<PurchaseTab> {
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final data = await DatabaseHelper.instance.getSuppliers();
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
          
          // Supplier Selection (Dynamic)
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
                    // If list is empty, show a disabled item
                    disabledHint: Text(loc.noSuppliersFound), 
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Items List (Placeholder for future functionality)
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
          // Additional Charges
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.additionalCharges, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(decoration: InputDecoration(labelText: loc.transport, prefixText: 'Rs '))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(decoration: InputDecoration(labelText: loc.labor, prefixText: 'Rs '))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
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

// ==================== Stock View Tab ====================
class StockViewTab extends StatelessWidget {
  const StockViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // TODO: Dynamic Data for Stock View (Task 3.2)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: loc.searchStock,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
              IconButton(icon: const Icon(Icons.print), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 20),
          // Summary
          Row(
            children: [
              Expanded(child: Card(color: Colors.green[50], child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(loc.totalItems, style: const TextStyle(color: Colors.green)), const Text('145', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))])))),
              const SizedBox(width: 10),
              Expanded(child: Card(color: Colors.blue[50], child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(loc.stockValue, style: const TextStyle(color: Colors.blue)), const Text('Rs 450,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))])))),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.stockDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(loc.item)),
                        DataColumn(label: Text(loc.current)),
                        DataColumn(label: Text(loc.unit)),
                        DataColumn(label: Text(loc.price)),
                        DataColumn(label: Text(loc.total)),
                        DataColumn(label: Text(loc.action)),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Rice')),
                          const DataCell(Text('50')),
                          const DataCell(Text('KG')),
                          const DataCell(Text('Rs 180')),
                          const DataCell(Text('Rs 9,000')),
                          DataCell(IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {})),
                        ]),
                      ],
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