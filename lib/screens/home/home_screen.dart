// lib/screens/home/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Added for dynamic date formatting
import '../../l10n/app_localizations.dart'; // ✅ Added Localizations import
import '../../core/database/database_helper.dart';
import '../master_data/items_screen.dart';
import '../master_data/suppliers_screen.dart';
import '../sales/sales_screen.dart';
import '../stock/stock_screen.dart';
import '../master_data/customers_screen.dart';
import '../master_data/categories_screen.dart';
import '../master_data/units_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../cash_ledger/cash_ledger_screen.dart';
import '../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentTime = '';
  String currentDate = '';
  Timer? timer;
  Timer? dataTimer;

  double todaySales = 0.0;
  List<Map<String, dynamic>> todayCustomers = [];
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> recentSales = [];

  @override
  void initState() {
    super.initState();
    // Note: We cannot call _updateTime() here immediately if it depends on context for localization
    // It will be called by the timer or didChangeDependencies.
    _loadData();

    // Update time every minute
    timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) _updateTime();
    });

    // Refresh dashboard data every 30 seconds
    dataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Initialize time immediately when context/dependencies are available
    _updateTime();
  }

  @override
  void dispose() {
    timer?.cancel();
    dataTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    DateTime now = DateTime.now();
    
    // ✅ FIXED: Use DateFormat with the current locale (context)
    // This removes the hardcoded Urdu arrays and supports both English and Urdu automatically.
    final localeCode = Localizations.localeOf(context).languageCode;
    
    setState(() {
      currentTime = DateFormat.jm(localeCode).format(now); // e.g., 5:30 PM
      currentDate = DateFormat.yMMMMEEEEd(localeCode).format(now); // e.g., Sunday, January 14, 2024
    });
  }

  Future<void> _loadData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      // Parallel execution for faster loading
      final results = await Future.wait([
        dbHelper.getTodaySales(),
        dbHelper.getTodayCustomers(),
        dbHelper.getLowStockItems(),
        dbHelper.getRecentSales(),
      ]);

      if (!mounted) return;

      setState(() {
        todaySales = results[0] as double;
        todayCustomers = results[1] as List<Map<String, dynamic>>;
        lowStockItems = results[2] as List<Map<String, dynamic>>;
        recentSales = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Helper for accessing translations
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: _buildNavigationDrawer(localizations),
      body: Column(
        children: [
          // Top Bar with Menu, Title, Time, and Bill Button
          Container(
            height: 120, // Height to accommodate two rows
            color: Colors.green[700],
            child: Column(
              children: [
                // Row 1: Menu + Title + Time
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          // ✅ UPDATED: Use localized App Title
                          child: Text(
                            localizations.appTitle,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currentTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(currentDate, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Row 2: Generate Bill Button
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesScreen())).then((_) => _loadData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green[700],
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.receipt_long, size: 20),
                        // ✅ UPDATED: Use localized 'Generate Bill'
                        label: Text(localizations.generateBill, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashboard Cards
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Sales Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.currency_rupee, color: Colors.green, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rs ${todaySales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  // ✅ UPDATED: Use localized 'Today's Sales'
                                  Text(localizations.todaySales, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customers Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.people, color: Colors.blue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                // ✅ UPDATED: Localized 'Today's Customers'
                                Text('${localizations.todayCustomers}: ${todayCustomers.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (todayCustomers.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Table(
                                columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Colors.grey),
                                    children: [
                                      // ✅ UPDATED: Localized headers
                                      Padding(padding: const EdgeInsets.all(8), child: Text(localizations.customer, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(localizations.amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                    ],
                                  ),
                                  for (var customer in todayCustomers)
                                    TableRow(
                                      children: [
                                        // Shows Urdu name if available, else English
                                        Padding(padding: const EdgeInsets.all(8), child: Text(customer['name_urdu'] ?? customer['name_english'] ?? 'Unknown', style: const TextStyle(fontSize: 14))),
                                        Padding(padding: const EdgeInsets.all(8), child: Text('Rs ${(customer['total_amount'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 14))),
                                      ],
                                    ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              // ✅ UPDATED: Localized 'No customers'
                              Center(child: Text(localizations.noCustomersToday, style: const TextStyle(color: Colors.grey))),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Low Stock Card
                    Card(
                      elevation: 4,
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.warning, color: Colors.red, size: 24),
                                ),
                                const SizedBox(width: 12),
                                // ✅ UPDATED: Localized 'Low Stock'
                                Text(' ${localizations.lowStock}: ${lowStockItems.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            if (lowStockItems.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(color: Colors.red),
                              const SizedBox(height: 8),
                              Table(
                                columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Colors.red),
                                    children: [
                                      // ✅ UPDATED: Localized headers
                                      Padding(padding: const EdgeInsets.all(8), child: Text(localizations.item, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(localizations.current, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(localizations.required, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                    ],
                                  ),
                                  for (var item in lowStockItems)
                                    TableRow(
                                      children: [
                                        Padding(padding: const EdgeInsets.all(8), child: Text(item['name_urdu'] ?? item['name_english'] ?? 'Unknown', style: const TextStyle(fontSize: 14))),
                                        Padding(padding: const EdgeInsets.all(8), child: Text('${item['current_stock']}', style: const TextStyle(fontSize: 14))),
                                        Padding(padding: const EdgeInsets.all(8), child: Text('${item['min_stock_alert']}', style: const TextStyle(fontSize: 14))),
                                      ],
                                    ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              // ✅ UPDATED: Localized 'All in stock'
                              Center(child: Text(localizations.allStockAvailable, style: const TextStyle(color: Colors.green))),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Sales Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt, color: Colors.green),
                                const SizedBox(width: 8),
                                // ✅ UPDATED: Localized 'Recent Sales'
                                Text(localizations.recentSales, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (recentSales.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              for (var sale in recentSales)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Center(child: Text(sale['bill_number']?.toString().replaceAll('SALE-', '') ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(sale['customer_name']?.toString() ?? 'Cash', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                            Text(sale['sale_time'] != null && (sale['sale_time'] as String).length >= 5? (sale['sale_time'] as String).substring(0, 5): sale['sale_time']?.toString() ?? '',style: const TextStyle(fontSize: 12, color: Colors.grey),),
                                          ],
                                        ),
                                      ),
                                      Text('Rs ${(sale['grand_total'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              const SizedBox(height: 20),
                              // ✅ UPDATED: Localized 'No sales yet'
                              Center(child: Text(localizations.noSalesYet, style: const TextStyle(color: Colors.grey))),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildNavigationDrawer(AppLocalizations localizations) {
    return Drawer(
      width: 280,
      child: Column(
        children: [
          Container(
            height: 180,
            color: Colors.green[700],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                // ✅ UPDATED: Localized App Title
                Text(localizations.appTitle, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                // ✅ UPDATED: Localized Version
                Text(localizations.posVersion, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ✅ UPDATED: All Drawer items use localizations keys
                _buildDrawerItem(icon: Icons.dashboard, title: localizations.home, onTap: () => Navigator.pop(context)),
                _buildDrawerItem(icon: Icons.shopping_cart, title: localizations.salesPos, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesScreen()));
                }),
                _buildDrawerItem(icon: Icons.inventory, title: localizations.stockManagement, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
                }),
                ExpansionTile(
                  leading: const Icon(Icons.data_usage, color: Colors.green),
                  title: Text(localizations.masterData),
                  children: [
                    ListTile(leading: const Icon(Icons.inventory, size: 20), title: Text(localizations.items), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemsScreen()));
                    }),
                    ListTile(leading: const Icon(Icons.people, size: 20), title: Text(localizations.customers), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersScreen()));
                    }),
                    ListTile(leading: const Icon(Icons.business, size: 20), title: Text(localizations.suppliers), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SuppliersScreen()));
                    }),
                    ListTile(leading: const Icon(Icons.category, size: 20), title: Text(localizations.categories), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
                    }),
                    ListTile(leading: const Icon(Icons.square_foot, size: 20), title: Text(localizations.units), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitsScreen()));
                    }),
                  ],
                ),
                _buildDrawerItem(icon: Icons.analytics, title: localizations.reports, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                }),
                _buildDrawerItem(icon: Icons.attach_money, title: localizations.cashLedger, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CashLedgerScreen()));
                }),
                _buildDrawerItem(icon: Icons.settings, title: localizations.settings, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
                const Divider(),
                _buildDrawerItem(icon: Icons.info, title: localizations.aboutApp, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                }),
                _buildDrawerItem(icon: Icons.logout, title: localizations.logout, color: Colors.red, onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text('© 2024 Liaqat Kiryana Store', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.green[700]),
      title: Text(title, style: TextStyle(fontSize: 16, color: color ?? Colors.grey[800])),
      onTap: onTap,
    );
  }
}