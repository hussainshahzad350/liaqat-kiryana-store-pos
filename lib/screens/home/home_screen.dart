// lib/screens/home/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../sales/sales_screen.dart';
import '../stock/stock_screen.dart';
import '../items/items_screen.dart';
import '../customers/customers_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../categories/categories_screen.dart';
import '../units/units_screen.dart';
import '../reports/reports_screen.dart';
import '../cash_ledger/cash_ledger_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  String currentTime = '';
  String currentDate = '';
  Timer? timer;
  Timer? dataTimer;
  bool isSidebarExpanded = true;
  bool _isRefreshing = false;
  
  // Data variables
  double todaySales = 0.0;
  List<Map<String, dynamic>> todayCustomers = [];
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> recentSales = [];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
    dataTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    _loadData();
  }

  @override
  void dispose() {
    timer?.cancel();
    dataTimer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    if (!mounted) return;
    setState(() {
      final now = DateTime.now();
      currentTime = DateFormat('hh:mm a').format(now);
      currentDate = DateFormat('dd MMM yyyy').format(now);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final results = await Future.wait([
        dbHelper.getTodaySales(),
        dbHelper.getTodayCustomers(),
        dbHelper.getLowStockItems(),
        dbHelper.getRecentActivities(limit: 10),
      ]);

      if (!mounted) return;

      setState(() {
        todaySales = results[0] as double;
        todayCustomers = results[1] as List<Map<String, dynamic>>;
        lowStockItems = results[2] as List<Map<String, dynamic>>;
        recentSales = results[3] as List<Map<String, dynamic>>;
        _isRefreshing = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  double _calculatePendingCredits() {
    double total = 0.0;
    for (var customer in todayCustomers) {
      total += (customer['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewSaleIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _RefreshIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _ToggleSidebarIntent(),
      },
      actions: {
        _NewSaleIntent: CallbackAction<_NewSaleIntent>(
          onInvoke: (_) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesScreen()),
            );
            return null;
          },
        ),
        _RefreshIntent: CallbackAction<_RefreshIntent>(
          onInvoke: (_) {
            _loadData();
            return null;
          },
        ),
        _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(
          onInvoke: (_) {
            setState(() {
              isSidebarExpanded = !isSidebarExpanded;
            });
            return null;
          },
        ),
      },
      child: Scaffold(
        body: Row(
          children: [
            // LEFT: Navigation Sidebar
            _buildNavigationSidebar(localizations),
            
            // RIGHT: Main Content Area
            Expanded(
              child: Column(
                children: [
                  // 1. Header Bar
                  _buildHeaderBar(localizations),
                  
                  // 2. Action Bar
                  _buildActionBar(localizations),
                  
                  // 3. Dashboard Content
                  Expanded(
                    child: Column(
                      children: [
                        // FIXED SECTION (Doesn't scroll)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // KPI Grid (Fixed at top)
                              _buildKPIGrid(localizations),
                              const SizedBox(height: 16),
                              
                              // Details Grid - Customers + Low Stock (Fixed)
                              _buildDetailsGrid(localizations),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // SCROLLABLE SECTION (Only Recent Activities)
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _buildRecentSalesCard(localizations),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 4. Footer Bar
                  _buildFooterBar(localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // NAVIGATION SIDEBAR
  // ========================================================================
  
  Widget _buildNavigationSidebar(AppLocalizations localizations) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSidebarExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(
          end: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(localizations),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: localizations.home,
                  isActive: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.shopping_cart,
                  title: localizations.salesPos,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.warehouse,
                  title: localizations.stockManagement,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.inventory,
                  title: localizations.items,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemsScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: localizations.customers,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.business,
                  title: localizations.suppliers,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SuppliersScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.category,
                  title: localizations.categories,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.square_foot,
                  title: localizations.units,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitsScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: localizations.reports,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.attach_money,
                  title: localizations.cashLedger,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CashLedgerScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: localizations.settings,
                  isActive: false,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: localizations.logout,
                  isActive: false,
                  color: Colors.red,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
          _buildSidebarFooter(localizations),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(AppLocalizations localizations) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green[700]!, Colors.green[600]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSidebarExpanded ? 50 : 35,
            height: isSidebarExpanded ? 50 : 35,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.store,
              size: isSidebarExpanded ? 28 : 20,
              color: Colors.green[700],
            ),
          ),
          if (isSidebarExpanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                localizations.appTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: Colors.green[700]!, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isSidebarExpanded ? 12.0 : 0),
              child: Icon(
                icon,
                size: 22,
                color: color ?? (isActive ? Colors.green[700] : Colors.grey[700]),
              ),
            ),
            if (isSidebarExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: color ?? (isActive ? Colors.green[900] : Colors.grey[800]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSidebarExpanded) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          localizations.systemOnline,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  isSidebarExpanded = !isSidebarExpanded;
                });
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
                ),
                child: Icon(
                  isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // HEADER BAR
  // ========================================================================
  
  Widget _buildHeaderBar(AppLocalizations localizations) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.green[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // LEFT: Dashboard Label
          SizedBox(
            width: 100,
            child: Text(
              localizations.dashboard,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          
          // CENTER: Shop Name
          Expanded(
            child: Center(
              child: Text(
                localizations.appTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // RIGHT: Clock + Profile
          SizedBox(
            width: 280,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 6),
                          Text(
                            currentTime,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentDate,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                  tooltip: localizations.settings,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // ACTION BAR
  // ========================================================================
  
  Widget _buildActionBar(AppLocalizations localizations) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Primary Action: New Sale Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              ).then((_) => _loadData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.2),
              side: BorderSide(color: Colors.green[700]!, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) return Colors.green[50];
                  return null;
                },
              ),
              elevation: MaterialStateProperty.resolveWith<double>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) return 6;
                  return 3;
                },
              ),
            ),
            icon: Icon(Icons.add_shopping_cart, size: 22, color: Colors.green[700]),
            label: Text(
              localizations.generateBill,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 2. Quick Action: Reports
          _buildQuickActionButton(
            icon: Icons.bar_chart,
            label: localizations.reports,
            color: Colors.green[700]!,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
            },
          ),
          
          const SizedBox(width: 8),
          
          // 3. Quick Action: Stock
          _buildQuickActionButton(
            icon: Icons.inventory_2,
            label: localizations.stockManagement,
            color: Colors.green[700]!,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
            },
          ),
          
          const SizedBox(width: 8),
          
          // 4. Quick Action: Cash Ledger
          _buildQuickActionButton(
            icon: Icons.account_balance_wallet,
            label: localizations.cashLedger,
            color: Colors.green[700]!,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CashLedgerScreen()));
            },
          ),
          
          const Spacer(),
          
          // 5. Search Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.green[50],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green[700]!, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.search, size: 20, color: Colors.green[700]),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 6. Refresh Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isRefreshing ? null : _loadData,
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.green[50],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isRefreshing ? Colors.grey[400]! : Colors.green[700]!,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green[700],
                          ),
                        )
                      : Icon(Icons.refresh, size: 20, color: Colors.green[700]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) return Colors.green[50];
              if (states.contains(MaterialState.pressed)) return Colors.green[100];
              return null;
            },
          ),
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) return 4;
              return 2;
            },
          ),
          side: MaterialStateProperty.resolveWith<BorderSide>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return BorderSide(color: color, width: 2);
              }
              return BorderSide(color: color, width: 1.5);
            },
          ),
        ),
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(AppLocalizations localizations) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 1400 ? 1.8 : 1.5,
          children: [
            _buildKPICard(
              title: localizations.todaySales,
              value: 'Rs ${todaySales.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              color: Colors.green,
              trend: '+12%',
              trendUp: true,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
              },
            ),
            _buildKPICard(
              title: localizations.pendingAmount,
              value: 'Rs ${_calculatePendingCredits().toStringAsFixed(0)}',
              icon: Icons.credit_card,
              color: Colors.orange,
              subtitle: '${todayCustomers.length} ${localizations.customers}',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersScreen()));
              },
            ),
            _buildKPICard(
              title: localizations.lowStock,
              value: '${lowStockItems.length}',
              icon: Icons.warning_amber,
              color: Colors.red,
              subtitle: localizations.itemsNeedRestock,
              isAlert: lowStockItems.length > 5,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
              },
            ),
            _buildKPICard(
              title: localizations.totalCustomers,
              value: '${todayCustomers.length}',
              icon: Icons.people,
              color: Colors.blue,
              subtitle: localizations.activeToday,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // HELPER METHOD FOR LOCALIZATION - MISSING
  // ========================================================================
  
  String _buildOnlyLeftText(AppLocalizations localizations, dynamic stock, String unit) {
    // Handle the onlyLeft localization safely
    try {
      final text = localizations.onlyLeft;
      if (text is String) {
        return _buildOnlyLeftText(localizations, stock, unit);
      }
      return 'Only $stock $unit left';
    } catch (e) {
      return 'Only $stock $unit left';
    }
  }

  // ========================================================================
  // KPI GRID
  // ========================================================================
  
   Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? trend,
    bool trendUp = true,
    bool isAlert = false,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const Spacer(),
                    if (trend != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: trendUp
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: trendUp ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              trend,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: trendUp ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isAlert && trend == null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // DETAILS GRID (CUSTOMERS + LOW STOCK)
  // ========================================================================
  
  Widget _buildDetailsGrid(AppLocalizations localizations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCustomersCard(localizations)),
        const SizedBox(width: 16),
        Expanded(child: _buildLowStockCard(localizations)),
      ],
    );
  }

  Widget _buildCustomersCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  localizations.todaysCustomers,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (todayCustomers.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...todayCustomers.take(5).map((customer) {
                final name = customer['name_english']?.toString() ?? 
                             customer['name_urdu']?.toString() ?? 
                             localizations.cashSale;
                final amount = (customer['total_amount'] as num?)?.toDouble() ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        radius: 18,
                        child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rs ${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        localizations.noCustomersToday,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  localizations.lowStock,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...lowStockItems.take(5).map((item) {
                final name = item['name_english']?.toString() ?? 
                            item['name_urdu']?.toString() ?? 
                            'Unknown Item';
                final stock = item['current_stock'] ?? 0;
                final unit = item['unit_type']?.toString() ?? 'units';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2, size: 18, color: Colors.red[700]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _buildOnlyLeftText(localizations, stock, unit),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green[400]),
                      const SizedBox(height: 8),
                      Text(
                        'All items in stock',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // RECENT ACTIVITIES
  // ========================================================================
  
  Widget _buildRecentSalesCard(AppLocalizations localizations) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED HEADER (Doesn't scroll)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.timeline, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                localizations.recentActivities,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // TABLE HEADER (Fixed)
        if (recentSales.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    localizations.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    localizations.activityType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    localizations.time,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    localizations.status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        
        // SCROLLABLE ACTIVITIES LIST
        if (recentSales.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: recentSales.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final activity = recentSales[index];
                return _buildActivityRow(activity, localizations);
              },
            ),
          )
        else
          // EMPTY STATE
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    localizations.noActivitiesYet,
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  }
  // NEW METHOD: Build individual activity row
  Widget _buildActivityRow(Map<String, dynamic> activity, AppLocalizations localizations) {
  final activityType = activity['activity_type']?.toString();
  final status = activity['status']?.toString();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      children: [
        // Column 1: Bill Number / Title with Icon
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getActivityColor(activityType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activityType),
                  color: _getActivityColor(activityType),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title']?.toString() ?? localizations.unknown,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity['customer_name'] != null)
                      Text(
                        activity['customer_name'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Column 2: Activity Type (Translated)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActivityDescription(activity, localizations),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getActivityDetails(activity, localizations),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Column 3: Time
        Expanded(
          flex: 2,
          child: Text(
            _getRelativeTime(activity['timestamp']?.toString(), localizations),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Column 4: Status Badge
        Expanded(
          flex: 2,
          child: Center(
            child: _buildStatusBadge(status, localizations),
          ),
        ),
      ],
    ),
  );
  }

  // NEW METHOD: Build status badge
Widget _buildStatusBadge(String? status, AppLocalizations localizations) {
  Color bgColor;
  Color textColor;
  String label;
  
  switch (status?.toUpperCase()) {
    case 'CANCELLED':
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red[700]!;
      label = localizations.cancelled;
      break;
    case 'COMPLETED':
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green[700]!;
      label = localizations.completed;
      break;
    case 'URGENT':
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange[700]!;
      label = localizations.urgent;
      break;
    case 'PENDING':
      bgColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue[700]!;
      label = localizations.pending;
      break;
    default:
      bgColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey[700]!;
      label = localizations.completed;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    ),
  );
  }

  // Helper methods for activities
  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'SALE':
        return Icons.receipt;
      case 'PAYMENT':
        return Icons.payments;
      case 'ALERT':
        return Icons.warning_amber;
      case 'CUSTOMER':
        return Icons.person_add;
      case 'STOCK':
        return Icons.inventory;
      default:
        return Icons.circle;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'SALE':
        return Colors.green;
      case 'PAYMENT':
        return Colors.blue;
      case 'ALERT':
        return Colors.red;
      case 'CUSTOMER':
        return Colors.purple;
      case 'STOCK':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActivityDescription(Map<String, dynamic> activity, AppLocalizations localizations) {
    final type = activity['activity_type']?.toString();
    switch (type) {
      case 'SALE':
        return localizations.billCreated;
      case 'PAYMENT':
        return localizations.paymentReceived;
      case 'ALERT':
        return localizations.lowStockAlert;
      case 'CUSTOMER':
        return localizations.newCustomerAdded;
      case 'STOCK':
        return localizations.stockUpdated;
      default:
        return 'Activity';
    }
  }

  String _getActivityDetails(Map<String, dynamic> activity, AppLocalizations localizations) {
    final type = activity['activity_type']?.toString();
    switch (type) {
      case 'SALE':
        final amount = (activity['amount'] as num?)?.toDouble() ?? 0.0;
        final customer = activity['customer_name']?.toString() ?? localizations.cashSale;
        return '$customer - Rs ${amount.toStringAsFixed(0)}';
      case 'PAYMENT':
        final amount = (activity['amount'] as num?)?.toDouble() ?? 0.0;
        return 'Rs ${amount.toStringAsFixed(0)}';
      case 'ALERT':
        final stock = activity['stock_level'];
        final unit = activity['unit_name']?.toString() ?? 'units';
        return _buildOnlyLeftText(localizations, stock, unit);
      default:
        return '';
    }
  }

  String _getRelativeTime(String? timestamp, AppLocalizations localizations) {
  if (timestamp == null || timestamp.isEmpty) return '';
  
  try {
    final activityTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(activityTime);

    if (difference.inMinutes < 1) {
      return localizations.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${localizations.minAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${localizations.hrAgo}';
    } else {
      return '${difference.inDays} ${localizations.daysAgo}';
    }
  } catch (e) {
    return '';
  }
}

  // ========================================================================
  // FOOTER BAR
  // ========================================================================
  
  Widget _buildFooterBar(AppLocalizations localizations) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.storage, size: 14, color: Colors.green[700]),
          const SizedBox(width: 6),
          Text(
            localizations.databaseConnected,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          const SizedBox(width: 20),
          Icon(Icons.backup, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            '${localizations.lastBackup}: 2 hrs ago',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            'v1.0.0',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            localizations.systemOk,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KEYBOARD SHORTCUT INTENTS
// ============================================================================

class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}