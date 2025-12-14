import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: Text(loc.reports),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.shopping_bag), text: loc.sales),
            Tab(icon: const Icon(Icons.trending_up), text: loc.profit),
            Tab(icon: const Icon(Icons.shopping_cart), text: loc.purchase),
            Tab(icon: const Icon(Icons.people), text: loc.customerBalance),
            Tab(icon: const Icon(Icons.inventory), text: loc.stock),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesReportTab(),
          ProfitReportTab(),
          PurchaseReportTab(),
          CustomerReportTab(),
          StockReportTab(),
        ],
      ),
    );
  }
}

// ==================== Sales Report Tab ====================
class SalesReportTab extends StatelessWidget {
  const SalesReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Range Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.selectDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: loc.startDate,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            // Date picker logic
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(loc.to, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: loc.endDate,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            // Date picker logic
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: loc.comparison,
                          ),
                          items: [
                            loc.thisMonthVsLast,
                            loc.thisWeekVsLast,
                            loc.thisYearVsLast,
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: loc.totalSales,
                  value: 'Rs 154,200',
                  color: Colors.green,
                  icon: Icons.currency_rupee,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: loc.avgDaily,
                  value: 'Rs 5,140',
                  color: Colors.blue,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: loc.totalBills,
                  value: '245',
                  color: Colors.orange,
                  icon: Icons.receipt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sales Chart Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.salesGraph,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        loc.graphPlaceholder,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sales Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        loc.detailedSales,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {},
                        tooltip: loc.downloadReport,
                      ),
                      IconButton(
                        icon: const Icon(Icons.print),
                        onPressed: () {},
                        tooltip: loc.printReport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(loc.date)),
                        DataColumn(label: Text(loc.billNo)),
                        DataColumn(label: Text(loc.customer)),
                        DataColumn(label: Text(loc.total)),
                        DataColumn(label: Text(loc.cash)),
                        DataColumn(label: Text(loc.bank)),
                        DataColumn(label: Text(loc.credit)),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('01 Dec')),
                          DataCell(Text('#2451')),
                          DataCell(Text('Ali Khan')),
                          DataCell(Text('Rs 5,200')),
                          DataCell(Text('Rs 3,200')),
                          DataCell(Text('Rs 1,000')),
                          DataCell(Text('Rs 1,000')),
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

// ==================== Profit Report Tab ====================
class ProfitReportTab extends StatelessWidget {
  const ProfitReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profit Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.profitSummary,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfitCard(
                          title: loc.totalSales,
                          value: 'Rs 154,200',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.totalCost,
                          value: 'Rs 120,000',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.netProfit,
                          value: 'Rs 34,200',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ProfitCard(
                          title: loc.profitPercentage,
                          value: '22.2%',
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.avgProfitPerBill,
                          value: 'Rs 140',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Expenses Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.expenseDetails,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ExpenseItem(name: loc.purchaseCost, amount: 'Rs 120,000', percentage: '78%'),
                  ExpenseItem(name: loc.transport, amount: 'Rs 5,000', percentage: '3.2%'),
                  ExpenseItem(name: loc.labor, amount: 'Rs 3,000', percentage: '1.9%'),
                  ExpenseItem(name: loc.otherExpenses, amount: 'Rs 2,000', percentage: '1.3%'),
                  const SizedBox(height: 10),
                  const Divider(),
                  ExpenseItem(name: loc.totalExpenses, amount: 'Rs 130,000', percentage: '84.4%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Purchase Report Tab ====================
class PurchaseReportTab extends StatelessWidget {
  const PurchaseReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            loc.purchaseReport,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            loc.purchaseHistoryNote,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: Text(loc.downloadReport),
          ),
        ],
      ),
    );
  }
}

// ==================== Customer Report Tab ====================
class CustomerReportTab extends StatelessWidget {
  const CustomerReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Outstanding Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.customerBalanceSummary,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalBalance,
                          value: 'Rs 45,200',
                          color: Colors.red,
                          icon: Icons.money_off,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.customers,
                          value: '24',
                          color: Colors.blue,
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.avgBalance,
                          value: 'Rs 1,883',
                          color: Colors.orange,
                          icon: Icons.calculate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Aging Analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.balanceAging,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  AgingItem(days: '0-30 ${loc.days}', amount: 'Rs 25,000', color: Colors.green),
                  AgingItem(days: '31-60 ${loc.days}', amount: 'Rs 12,000', color: Colors.yellow),
                  AgingItem(days: '61-90 ${loc.days}', amount: 'Rs 5,200', color: Colors.orange),
                  AgingItem(days: '90+ ${loc.days}', amount: 'Rs 3,000', color: Colors.red),
                  const SizedBox(height: 10),
                  const Divider(),
                  AgingItem(days: loc.total, amount: 'Rs 45,200', color: Colors.blue),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Top Customers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.topCustomersBalance,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  CustomerBalanceItem(
                    name: 'Ali Khan',
                    balance: 'Rs 12,500',
                    phone: '0300-1111111',
                    days: '15 ${loc.daysOld}',
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

// ==================== Stock Report Tab ====================
class StockReportTab extends StatelessWidget {
  const StockReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stock Value Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.stockValueSummary,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalStockValue,
                          value: 'Rs 450,000',
                          color: Colors.green,
                          icon: Icons.warehouse,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalItems,
                          value: '145',
                          color: Colors.blue,
                          icon: Icons.inventory,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.avgPrice,
                          value: 'Rs 3,103',
                          color: Colors.orange,
                          icon: Icons.calculate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category-wise Stock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.stockByCategory,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const StockCategoryItem(
                    category: 'Rice',
                    value: 'Rs 150,000',
                    items: '12',
                    percentage: '33%',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Low Stock Items
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        loc.lowStockItems,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(loc.fullReport),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const LowStockItem(
                    name: 'Rice',
                    current: '5 KG',
                    min: '50 KG',
                    difference: '-45 KG',
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

// ==================== Helper Widgets ====================

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ProfitCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const ProfitCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ExpenseItem extends StatelessWidget {
  final String name;
  final String amount;
  final String percentage;

  const ExpenseItem({
    super.key,
    required this.name,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(amount),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(percentage),
          ),
        ],
      ),
    );
  }
}

class AgingItem extends StatelessWidget {
  final String days;
  final String amount;
  final Color color;

  const AgingItem({
    super.key,
    required this.days,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(days)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CustomerBalanceItem extends StatelessWidget {
  final String name;
  final String balance;
  final String phone;
  final String days;

  const CustomerBalanceItem({
    super.key,
    required this.name,
    required this.balance,
    required this.phone,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Icon(Icons.person, color: Colors.red, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(balance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                Text(days, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StockCategoryItem extends StatelessWidget {
  final String category;
  final String value;
  final String items;
  final String percentage;

  const StockCategoryItem({
    super.key,
    required this.category,
    required this.value,
    required this.items,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(category)),
          Text('$items ${loc.items}'),
          const SizedBox(width: 20),
          Text(value),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(percentage),
          ),
        ],
      ),
    );
  }
}

class LowStockItem extends StatelessWidget {
  final String name;
  final String current;
  final String min;
  final String difference;

  const LowStockItem({
    super.key,
    required this.name,
    required this.current,
    required this.min,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(name)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${loc.current}: $current'),
                Text('${loc.required}: $min'),
              ],
            ),
            const SizedBox(width: 12),
            Text(difference, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}