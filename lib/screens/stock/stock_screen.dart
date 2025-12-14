import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart'; // ✅ Import Localizations

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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.stockManagement), // ✅ Localized
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: localizations.purchase, // ✅ Localized
            ),
            Tab(
              icon: const Icon(Icons.remove_shopping_cart),
              text: localizations.sales, // ✅ Localized
            ),
            Tab(
              icon: const Icon(Icons.inventory),
              text: localizations.stockView, // ✅ Localized
            ),
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

// ==================== Purchase Tab ====================
class PurchaseTab extends StatelessWidget {
  const PurchaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.newPurchase, // ✅ Localized
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Supplier Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations.selectSupplier), // ✅ Localized
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: localizations.chooseSupplier, // ✅ Localized
                    ),
                    items: [
                      'Ali Traders',
                      'Sami Store',
                      'Raheem Mart',
                    ].map((supplier) {
                      return DropdownMenuItem(
                        value: supplier,
                        child: Text(supplier),
                      );
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Items List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        localizations.items, // ✅ Localized
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(localizations.addItem), // ✅ Localized
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  
                  // Items Table
                  Table(
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Colors.grey),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(localizations.item, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(localizations.quantity, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(localizations.price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(localizations.total, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
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
                  Text(
                    localizations.additionalCharges, // ✅ Localized
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: localizations.transport, // ✅ Localized
                            prefixText: 'Rs ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: localizations.labor, // ✅ Localized
                            prefixText: 'Rs ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[700],
              ),
              child: Text(
                localizations.savePurchase, // ✅ Localized
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
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
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            localizations.salesRecord, // ✅ Localized
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.salesHistoryNote, // ✅ Localized
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sales');
            },
            child: Text(localizations.newSale), // ✅ Localized
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
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: localizations.searchStock, // ✅ Localized
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stock Summary
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          localizations.totalItems, // ✅ Localized
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '145',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
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
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          localizations.stockValue, // ✅ Localized
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Rs 450,000',
                          style: TextStyle(
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
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stock Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.stockDetails, // ✅ Localized
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(localizations.item)),
                        DataColumn(label: Text(localizations.current)),
                        DataColumn(label: Text(localizations.unit)),
                        DataColumn(label: Text(localizations.price)),
                        DataColumn(label: Text(localizations.total)),
                        DataColumn(label: Text(localizations.action)),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Rice')),
                          const DataCell(Text('50')),
                          const DataCell(Text('KG')),
                          const DataCell(Text('Rs 180')),
                          const DataCell(Text('Rs 9,000')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          )),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(localizations.adjustStock), // ✅ Localized
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(localizations.downloadReport), // ✅ Localized
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}