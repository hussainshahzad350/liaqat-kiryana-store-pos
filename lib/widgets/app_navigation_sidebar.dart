// lib/widgets/app_navigation_sidebar.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../screens/home/home_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/stock/stock_screen.dart';
import '../screens/items/items_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/units/units_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/cash_ledger/cash_ledger_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

class AppNavigationSidebar extends StatefulWidget {
  final String currentRoute;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AppNavigationSidebar({
    super.key,
    required this.currentRoute,
    this.isExpanded = true,
    required this.onToggle,
  });

  @override
  State<AppNavigationSidebar> createState() => _AppNavigationSidebarState();
}

class _AppNavigationSidebarState extends State<AppNavigationSidebar> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isExpanded ? 240 : 70,
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
            // Logo Section
            _buildSidebarHeader(localizations),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: localizations.home,
                    route: AppRoutes.home,
                    screen: const HomeScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.shopping_cart,
                    title: localizations.salesPos,
                    route: AppRoutes.sales,
                    screen: const SalesScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.warehouse,
                    title: localizations.stockManagement,
                    route: AppRoutes.stock,
                    screen: const StockScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: localizations.items,
                    route: AppRoutes.items,
                    screen: const ItemsScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.people,
                    title: localizations.customers,
                    route: AppRoutes.customers,
                    screen: const CustomersScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.business,
                    title: localizations.suppliers,
                    route: AppRoutes.suppliers,
                    screen: const SuppliersScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.category,
                    title: localizations.categories,
                    route: AppRoutes.categories,
                    screen: const CategoriesScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.square_foot,
                    title: localizations.units,
                    route: AppRoutes.units,
                    screen: const UnitsScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: localizations.reports,
                    route: AppRoutes.reports,
                    screen: const ReportsScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.attach_money,
                    title: localizations.cashLedger,
                    route: AppRoutes.cashLedger,
                    screen: const CashLedgerScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: localizations.settings,
                    route: AppRoutes.settings,
                    screen: const SettingsScreen(),
                  ),
                  
                  const Divider(height: 1),
                  
                  _buildMenuItem(
                    icon: Icons.info,
                    title: localizations.aboutApp,
                    route: AppRoutes.about,
                    screen: const AboutScreen(),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: localizations.logout,
                    route: '/logout',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            _buildSidebarFooter(localizations),
          ],
        ),
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
          colors: [
            Colors.green[700]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: widget.isExpanded ? 55 : 35,
            height: widget.isExpanded ? 55 : 35,
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
              size: widget.isExpanded ? 28 : 20,
              color: Colors.green[700],
            ),
          ),
          
          if (widget.isExpanded) ...[
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
    required String route,
    Widget? screen,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isActive = widget.currentRoute == route;
    
    return InkWell(
      onTap: onTap ?? () {
        if (screen != null && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => screen,
              settings: RouteSettings(name: route),
            ),
          );
        }
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.green[700]!, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded 
              ? MainAxisAlignment.start 
              : MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: widget.isExpanded ? 12.0 : 0),
              child: Icon(
                icon,
                size: 22,
                color: color ?? (isActive ? Colors.green[700] : Colors.grey[700]),
              ),
            ),
            
            if (widget.isExpanded) ...[
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
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isExpanded) ...[
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
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Icon(
                  widget.isExpanded 
                      ? Icons.chevron_left 
                      : Icons.chevron_right,
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
}