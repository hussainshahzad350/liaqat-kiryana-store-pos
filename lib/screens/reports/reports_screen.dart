import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/reports/reports_bloc.dart';
import '../../bloc/reports/reports_event.dart';
import '../../bloc/reports/reports_state.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../domain/entities/money.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => ReportsBloc(
        invoiceRepository: context.read<InvoiceRepository>(),
      ),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(loc.reports, style: TextStyle(color: colorScheme.onPrimary)),
          backgroundColor: colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: colorScheme.onPrimary,
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
      ),
    );
  }
}

// ==================== Sales Report Tab ====================
class SalesReportTab extends StatefulWidget {
  const SalesReportTab({super.key});

  @override
  State<SalesReportTab> createState() => _SalesReportTabState();
}

class _SalesReportTabState extends State<SalesReportTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsBloc>().add(LoadSalesReport(startDate: _startDate, endDate: _endDate));
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      if (!context.mounted) return;
      context.read<ReportsBloc>().add(LoadSalesReport(
            startDate: _startDate,
            endDate: _endDate,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final startDateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_startDate));
    final endDateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_endDate));

    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        final totalSales = state.salesReportData.fold<int>(0, (sum, invoice) => sum + invoice.totalAmount);
        final avgDailySales = state.salesReportData.isNotEmpty ? totalSales / state.salesReportData.length : 0;
        final totalBills = state.salesReportData.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Date Range Selector
              Card(
                color: colorScheme.surface,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.selectDate,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startDateController,
                              readOnly: true,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: loc.startDate,
                                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                                suffixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
                                filled: true,
                                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(loc.to, style: TextStyle(fontSize: 18, color: colorScheme.onSurface)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: endDateController,
                              readOnly: true,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: loc.endDate,
                                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                                suffixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
                                filled: true,
                                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              ),
                              onTap: () => _selectDate(context, false),
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
                      value: Money(totalSales).toString(),
                      color: colorScheme.primary,
                      icon: Icons.currency_rupee,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryCard(
                      title: loc.avgDaily,
                      value: Money(avgDailySales.toInt()).toString(),
                      color: colorScheme.secondary,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryCard(
                      title: loc.totalBills,
                      value: totalBills.toString(),
                      color: colorScheme.tertiary,
                      icon: Icons.receipt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sales Table
              Card(
                color: colorScheme.surface,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loc.detailedSales,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.download, color: colorScheme.primary),
                            onPressed: () {},
                            tooltip: loc.downloadReport,
                          ),
                          IconButton(
                            icon: Icon(Icons.print, color: colorScheme.primary),
                            onPressed: () {},
                            tooltip: loc.printReport,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (state.status == ReportStatus.loading)
                        const Center(child: CircularProgressIndicator())
                      else if (state.status == ReportStatus.error)
                        Center(child: Text(state.errorMessage ?? 'Failed to load data'))
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(colorScheme.primary),
                            headingTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                            columns: [
                              DataColumn(label: Text(loc.date)),
                              DataColumn(label: Text(loc.billNo)),
                              DataColumn(label: Text(loc.customer)),
                              DataColumn(label: Text(loc.total)),
                            ],
                            rows: state.salesReportData.map((invoice) {
                              return DataRow(cells: [
                                DataCell(Text(DateFormat('yyyy-MM-dd').format(invoice.date), style: TextStyle(color: colorScheme.onSurface))),
                                DataCell(Text(invoice.invoiceNumber, style: TextStyle(color: colorScheme.onSurface))),
                                DataCell(Text(invoice.customerName ?? loc.walkInCustomer, style: TextStyle(color: colorScheme.onSurface))),
                                DataCell(Text(Money(invoice.totalAmount).toString(), style: TextStyle(color: colorScheme.onSurface))),
                              ]);
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ... (rest of the file remains the same)
// ==================== Profit Report Tab ====================
class ProfitReportTab extends StatelessWidget {
  const ProfitReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profit Summary
          Card(
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.profitSummary,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfitCard(
                          title: loc.totalSales,
                          value: 'Rs 154,200',
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.totalCost,
                          value: 'Rs 120,000',
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.netProfit,
                          value: 'Rs 34,200',
                          color: colorScheme.tertiary,
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
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: loc.avgProfitPerBill,
                          value: 'Rs 140',
                          color: colorScheme.tertiaryContainer,
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
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.expenseDetails,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 100, color: colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            loc.purchaseReport,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            loc.purchaseHistoryNote,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Outstanding Summary
          Card(
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.customerBalanceSummary,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalBalance,
                          value: 'Rs 45,200',
                          color: colorScheme.error,
                          icon: Icons.money_off,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.customers,
                          value: '24',
                          color: colorScheme.primary,
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.avgBalance,
                          value: 'Rs 1,883',
                          color: colorScheme.tertiary,
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
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.balanceAging,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  AgingItem(days: '0-30 ${loc.days}', amount: 'Rs 25,000', color: colorScheme.primary),
                  AgingItem(days: '31-60 ${loc.days}', amount: 'Rs 12,000', color: colorScheme.tertiary),
                  AgingItem(days: '61-90 ${loc.days}', amount: 'Rs 5,200', color: colorScheme.secondary),
                  AgingItem(days: '90+ ${loc.days}', amount: 'Rs 3,000', color: colorScheme.error),
                  const SizedBox(height: 10),
                  const Divider(),
                  AgingItem(days: loc.total, amount: 'Rs 45,200', color: colorScheme.onSurface),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Top Customers
          Card(
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.topCustomersBalance,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  CustomerBalanceItem(
                    name: 'Ali Khan',
                    balance: const Money(1250000),
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stock Value Summary
          Card(
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.stockValueSummary,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalStockValue,
                          value: 'Rs 450,000',
                          color: colorScheme.primary,
                          icon: Icons.warehouse,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.totalItems,
                          value: '145',
                          color: colorScheme.secondary,
                          icon: Icons.inventory,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: loc.avgPrice,
                          value: 'Rs 3,103',
                          color: colorScheme.tertiary,
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
            color: colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.stockByCategory,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
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
            color: colorScheme.errorContainer,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        loc.lowStockItems,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.error,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
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
    final colorScheme = Theme.of(context).colorScheme;
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
            Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurface), textAlign: TextAlign.center),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: TextStyle(color: colorScheme.onSurface))),
          Text(amount, style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(4)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(days, style: TextStyle(color: colorScheme.onSurface))),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class CustomerBalanceItem extends StatelessWidget {
  final String name;
  final Money balance;
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(Icons.person, color: colorScheme.error, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  Text(phone, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(balance.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.error)),
                Text(days, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(category, style: TextStyle(color: colorScheme.onSurface))),
          Text('$items ${loc.items}', style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(width: 20),
          Text(value, style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(4)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning, size: 16, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: TextStyle(color: colorScheme.onSurface))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${loc.current}: $current', style: TextStyle(color: colorScheme.onSurface)),
                Text('${loc.required}: $min', style: TextStyle(color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(width: 12),
            Text(difference, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error)),
          ],
        ),
      ),
    );
  }
}
