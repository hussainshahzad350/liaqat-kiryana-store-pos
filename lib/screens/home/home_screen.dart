// lib/screens/home/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../items/items_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../sales/sales_screen.dart';
import '../stock/stock_screen.dart';
import '../customers/customers_screen.dart';
import '../categories/categories_screen.dart';
import '../units/units_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../cash_ledger/cash_ledger_screen.dart';
import '../about/about_screen.dart';
import 'package:flutter/services.dart';

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
  
  // ✅ NEW: Sidebar collapse state
  bool isSidebarExpanded = true;
  bool _isRefreshing = false;

  double todaySales = 0.0;
  List<Map<String, dynamic>> todayCustomers = [];
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> recentSales = [];

  double _calculatePendingCredits() {
  double total = 0.0;
  for (var customer in todayCustomers) {
    total += (customer['total_amount'] as num?)?.toDouble() ?? 0.0;
  }
  return total;
  }

  @override
  void initState() {
    super.initState();
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
    
    final localeCode = Localizations.localeOf(context).languageCode;
    
    setState(() {
      currentTime = DateFormat.jm(localeCode).format(now);
      currentDate = DateFormat.yMMMMEEEEd(localeCode).format(now);
    });
  }

  Future<void> _loadData() async {
  setState(() {
    _isRefreshing = true;  // ← ADD THIS
  });
  
  try {
    final dbHelper = DatabaseHelper.instance;
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
      _isRefreshing = false;  // ← ADD THIS
    });
  } catch (e) {
    print('Error loading data: $e');
    setState(() {
      _isRefreshing = false;  // ← ADD THIS
    });
  }
 }

  String _formatTime(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      
      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  
  return FocusableActionDetector(
    autofocus: true,
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): 
          const _NewSaleIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): 
          const _RefreshIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): 
          const _ToggleSidebarIntent(),
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
                
                // 3. Dashboard Content (SCROLLABLE)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // KPI Grid (4 cards)
                          _buildKPIGrid(localizations),
                          
                          const SizedBox(height: 24),
                          
                          // Details Grid (Customers + Low Stock)
                          _buildDetailsGrid(localizations),
                          
                          const SizedBox(height: 24),
                          
                          // Recent Sales
                          _buildRecentSalesCard(localizations),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 4. Footer Bar
                _buildFooterBar(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
 }

  Widget _buildKPIGrid(AppLocalizations localizations) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,                // ← Always 4 columns (desktop)
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.8,            // ← Wider cards for desktop
    children: [
      // Card 1: Today's Sales
      _buildKPICard(
        title: localizations.todaySales,
        value: 'Rs ${todaySales.toStringAsFixed(0)}',
        icon: Icons.attach_money,
        color: Colors.green,
        trend: '+12%',
        trendUp: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        },
      ),
      
      // Card 2: Pending Credits
      _buildKPICard(
        title: 'Pending Credits',  // ← Hardcode for now (or use localizations)
        value: 'Rs ${_calculatePendingCredits().toStringAsFixed(0)}',
        icon: Icons.credit_card,
        color: Colors.orange,
        subtitle: '${todayCustomers.length} Customers',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomersScreen()),
          );
        },
      ),
      
      // Card 3: Low Stock Alert
      _buildKPICard(
        title: localizations.lowStock,
        value: '${lowStockItems.length}',
        icon: Icons.warning_amber,
        color: Colors.red,
        subtitle: 'Items need restock',
        isAlert: lowStockItems.length > 5,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockScreen()),
          );
        },
      ),
      
      // Card 4: Total Customers
      _buildKPICard(
        title: 'Total Customers',
        value: '${todayCustomers.length}',
        icon: Icons.people,
        color: Colors.blue,
        subtitle: 'Active today',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomersScreen()),
          );
        },
      ),
    ],
  );
  }

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
  return MouseRegion(                           // ← ADD THIS: Detects hover
    cursor: SystemMouseCursors.click,           // ← Changes cursor to pointer
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withOpacity(0.05),    // ← ADD THIS: Subtle hover color
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... rest of your existing code (don't change)
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
                      child: const Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 12,
                      ),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
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

  // ============================================================================
  // NAVIGATION SIDEBAR
  // ============================================================================
  
  Widget _buildNavigationSidebar(AppLocalizations localizations) {
    return AnimatedContainer(                      // ✅ CHANGED: Animated for smooth transition
      duration: const Duration(milliseconds: 200),
      width: isSidebarExpanded ? 240 : 70,         // ✅ DYNAMIC WIDTH
      decoration: BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(
          end: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: Column(
          children: [
          // 1. Logo Section (Top)
          _buildSidebarHeader(localizations),
        
          // 2. Menu Items (Scrollable middle section)
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SalesScreen()),
                    );
                  },
                ),
              
                _buildMenuItem(
                  icon: Icons.warehouse,
                  title: localizations.stockManagement,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StockScreen()),
                    );
                  },
                ),
              
                _buildMenuItem(
                  icon: Icons.inventory,
                  title: localizations.items,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ItemsScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.people,
                  title: localizations.customers,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomersScreen()),
                    );
                  },
              ),

                _buildMenuItem(
                  icon: Icons.business,
                  title: localizations.suppliers,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SuppliersScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.category,
                  title: localizations.categories,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.square_foot,
                  title: localizations.units,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UnitsScreen()),
                    );
                  },
                ),
              
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: localizations.reports,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportsScreen()),
                    );
                  },
                ),
              
                _buildMenuItem(
                  icon: Icons.attach_money,
                  title: localizations.cashLedger,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CashLedgerScreen()),
                    );
                  },
                ),
              
                _buildMenuItem(
                  icon: Icons.settings,
                  title: localizations.settings,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              
                const Divider(height: 1),
              
                _buildMenuItem(
                  icon: Icons.info,
                  title: localizations.aboutApp,
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              
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
        
          // 3. Footer (Bottom)
          _buildSidebarFooter(),
        ],
      ),
    )
  );
  }

  // ============================================================================
  // SIDEBAR COMPONENTS
  // ============================================================================

  Widget _buildSidebarHeader(AppLocalizations localizations) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 110,       // ✅ SHORTER WHEN COLLAPSED
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[700]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icon (always visible)
          Container(
            width: isSidebarExpanded ? 60 : 40,    // ✅ SMALLER WHEN COLLAPSED
            height: isSidebarExpanded ? 60 : 40,
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
              size: isSidebarExpanded ? 32 : 24,
              color: Colors.green[700],
            ),
          ),
        
          // Shop Name (only when expanded)
          if (isSidebarExpanded) ...[             // ✅ HIDDEN WHEN COLLAPSED
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                localizations.appTitle,
                style: const TextStyle(
                  fontSize: 14,
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
        height: 50, // Fixed height for consistency
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.green[700]!, width: 1.5)
              : null,
        ),
        child: Row(
          // Center content if collapsed, Start if expanded
          mainAxisAlignment: isSidebarExpanded 
              ? MainAxisAlignment.start 
              : MainAxisAlignment.center,
          children: [
            // 1. Icon (Always visible)
            Padding(
              padding: EdgeInsets.only(left: isSidebarExpanded ? 12.0 : 0),
              child: Icon(
                icon,
                size: 24,
                color: color ?? (isActive ? Colors.green[700] : Colors.grey[700]),
              ),
            ),
            
            // 2. Text (ONLY visible if Expanded)
            if (isSidebarExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildSidebarFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Info (only when expanded)
          if (isSidebarExpanded) ...[
            Container(
              constraints: const BoxConstraints(
              maxHeight: 40, // ✅ Limit height to prevent overflow
            ),
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
                            'System Online',
                              style: TextStyle(
                              fontSize: 10, // ✅ Smaller font
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
              style: TextStyle(
              fontSize: 9, // ✅ Even smaller font
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  ],
          
          // ✅ COLLAPSE/EXPAND BUTTON
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  isSidebarExpanded = !isSidebarExpanded;  // ✅ TOGGLE STATE
                });
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Icon(
                  isSidebarExpanded 
                      ? Icons.chevron_left     // ← when expanded
                      : Icons.chevron_right,   // → when collapsed
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

  // ============================================================================
  // HEADER & ACTION BAR
  // ============================================================================

  Widget _buildHeaderBar(AppLocalizations localizations) {
    return Container(
      height: 80,
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
          // Left: Shop Name
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.appTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Clock Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text(
                      currentTime,
                      style: const TextStyle(
                        fontSize: 18,
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
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: localizations.settings,
          ),
        ],
      ),
    );
  }
  // Action Bar with "New Sale" Button
  Widget _buildActionBar(AppLocalizations localizations) {
  return Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
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
        // 1. Primary Action: New Sale Button (LARGE)
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesScreen()),
            ).then((_) => _loadData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart, size: 22),
          label: Text(
            localizations.generateBill,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(width: 12),  // ← Spacing
        
        // 2. Quick Action: Reports
        _buildQuickActionButton(
          icon: Icons.bar_chart,
          label: localizations.reports,
          color: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsScreen()),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // 3. Quick Action: Stock
        _buildQuickActionButton(
          icon: Icons.inventory_2,
          label: localizations.stockManagement,
          color: Colors.orange,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StockScreen()),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // 4. Quick Action: Cash Ledger
        _buildQuickActionButton(
          icon: Icons.account_balance_wallet,
          label: localizations.cashLedger,
          color: Colors.purple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CashLedgerScreen()),
            );
          },
        ),
        
        const Spacer(),  // ← Push right-side buttons to the end
        
        // 5. Search Button (Future feature)
        IconButton(
          icon: const Icon(Icons.search, size: 24),
          tooltip: 'Search',
          onPressed: () {
            // TODO: Implement search functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          color: Colors.grey[700],
        ),
        
        const SizedBox(width: 4),
        
        // 6. Refresh Button
        IconButton(
          icon: _isRefreshing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 24),
          tooltip: 'Refresh Dashboard',
          onPressed: _isRefreshing ? null : _loadData, // ← Disable when loading
          color: Colors.grey[700],
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
  return OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,                    // ← Button text/icon color
      side: BorderSide(color: color, width: 1.5), // ← Border color
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    icon: Icon(icon, size: 18),
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  }

  // ============================================================================
  // DASHBOARD CARDS
  // ============================================================================

  // Customer Card
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  '${localizations.todayCustomers}: ${todayCustomers.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (todayCustomers.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          localizations.customer,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          localizations.amount,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  for (var customer in todayCustomers)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            customer['name_urdu'] ?? customer['name_english'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'Rs ${(customer['total_amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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

  // Low Stock Card
  Widget _buildLowStockCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  '${localizations.lowStock}: ${lowStockItems.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          
            // Stock List or Empty State
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.red),
              const SizedBox(height: 12),
            
              // Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(color: Colors.red),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          localizations.item,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          localizations.current,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          localizations.required,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                
                  // Data Rows
                  for (var item in lowStockItems)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item['name_urdu'] ?? item['name_english'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${item['current_stock']}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${item['min_stock_alert']}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
                        localizations.allStockAvailable,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
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

  //  Recent Sales Card
  Widget _buildRecentSalesCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  localizations.recentSales,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          
            // Sales List or Empty State
            if (recentSales.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
            
              for (var sale in recentSales)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sale['status'] == 'CANCELLED'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          sale['status'] == 'CANCELLED' ? Icons.cancel : Icons.receipt,
                          color: sale['status'] == 'CANCELLED' ? Colors.red : Colors.green,
                          size: 20,
                        ),
                      ),
                    
                      const SizedBox(width: 12),
                    
                      // Sale Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale['customer_name']?.toString() ?? 'Cash',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sale['bill_number']} • ${_formatTime(sale['sale_time']?.toString() ?? '')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                      // Amount
                      Text(
                        'Rs ${(sale['grand_total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: sale['status'] == 'CANCELLED'
                              ? TextDecoration.lineThrough
                              : null,
                          color: sale['status'] == 'CANCELLED'
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        localizations.noSalesYet,
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

  // Footer Bar
  Widget _buildFooterBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Database Status
          Icon(Icons.storage, size: 14, color: Colors.green[700]),
          const SizedBox(width: 6),
          Text(
            'Database: Connected',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        
          const SizedBox(width: 20),
        
          // Last Backup
          Icon(Icons.backup, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            'Last Backup: 2 hrs ago',                    // ← Can make dynamic later
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        
          const Spacer(),
        
          // Version
          Text(
            'v1.0.0',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        
          const SizedBox(width: 12),
        
          // Status Indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'System OK',
            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

}

class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}
