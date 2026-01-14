// lib/screens/home/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/repositories/sales_repository.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/desktop_dimensions.dart';
import '../../domain/entities/money.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  final CustomersRepository _customersRepository = CustomersRepository();
  final ItemsRepository _itemsRepository = ItemsRepository();
  // State variables
  final ScrollController _leftPanelScroller = ScrollController();
  final ScrollController _activitiesScroller = ScrollController();
  Timer? dataTimer;

  bool _isRefreshing = false;
  
  // Data variables
  int todaySales = 0;
  List<Map<String, dynamic>> todayCustomers = [];
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> recentSales = [];

  @override
  void initState() {
    super.initState();
    dataTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    _loadData();
  }

  @override
  void dispose() {
    _leftPanelScroller.dispose();
    _activitiesScroller.dispose();
    dataTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final results = await Future.wait([
        _salesRepository.getTodaySales(),
        _customersRepository.getTodayCustomers(),
        _itemsRepository.getLowStockItems(),
        _salesRepository.getRecentActivities(limit: 10),
      ]);

      if (!mounted) return;

      setState(() {
        todaySales = results[0] as int;
        todayCustomers = results[1] as List<Map<String, dynamic>>;
        lowStockItems = results[2] as List<Map<String, dynamic>>;
        recentSales = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to load dashboard data: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  int _calculatePendingCredits() {
    int total = 0;
    for (var customer in todayCustomers) {
      total += (customer['total_amount'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

    @override
    Widget build(BuildContext context) {
      final localizations = AppLocalizations.of(context)!;
      final colorScheme = Theme.of(context).colorScheme;

      return Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.f5): _RefreshIntent(),
          SingleActivator(LogicalKeyboardKey.keyN, control: true): _NewSaleIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _RefreshIntent: CallbackAction<_RefreshIntent>(
              onInvoke: (intent) => _loadData(),
            ),
            _NewSaleIntent: CallbackAction<_NewSaleIntent>(
              onInvoke: (intent) {
                Navigator.pushNamed(context, AppRoutes.sales).then((_) => _loadData());
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                // 1. Header (Fixed 64px)
                const SizedBox(
                  height: 64,
                  child: HeaderBar(),
                ),
                
                // 2. Main Content (Left + Right)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT PANEL: Main Dashboard (Action Bar + KPIs + Details)
                      Expanded(
                        child: Column(
                          children: [
                            // Action Bar
                            _buildActionBar(localizations, colorScheme),
                            
                            // Scrollable Content
                            Expanded(
                              child: Scrollbar(
                                controller: _leftPanelScroller,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _leftPanelScroller,
                                  padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
                                  child: Column(
                                    children: [
                                      // KPI Grid
                                      _buildKPIGrid(localizations, colorScheme),
                                      const SizedBox(height: DesktopDimensions.spacingMedium),
                                      // Details Grid
                                      _buildDetailsGrid(localizations, colorScheme),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),

                      // RIGHT PANEL: Sidebar (Fixed 400px)
                      SizedBox(
                        width: 480,
                        child: Container(
                          color: colorScheme.surface.withOpacity(0.5),
                          padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildRecentSalesCard(localizations, colorScheme),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Footer Bar (Fixed 32px)
                SizedBox(
                  height: 32,
                  child: _buildFooterBar(localizations, colorScheme),
                ),
              ],
            ),
          ),
        ),
      );
    }
  void _showKeyboardShortcutsDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard),
            SizedBox(width: DesktopDimensions.spacingSmall),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutItem('New Sale', 'Ctrl + N', colorScheme),
            _buildShortcutItem('Refresh Dashboard', 'F5', colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String label, String shortcut, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurface)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // ACTION BAR
  // ========================================================================
  
  Widget _buildActionBar(AppLocalizations localizations, ColorScheme colorScheme) {
    return Container(
      height: DesktopDimensions.actionBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesktopDimensions.spacingLarge, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
              Navigator.pushNamed(context, AppRoutes.sales).then((_) => _loadData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 3,
              shadowColor: colorScheme.shadow.withOpacity(0.2),
              side: BorderSide(color: colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) return colorScheme.primaryContainer;
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
            icon: Icon(Icons.add_shopping_cart, size: 22, color: colorScheme.primary),
            label: Text(
              '${localizations.generateBill} (Ctrl+N)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          
          const SizedBox(width: DesktopDimensions.spacingSmall),
          
          // 2. Quick Action: Reports
          Tooltip(
            message: localizations.reports,
            child: _buildQuickActionButton(
              icon: Icons.bar_chart,
              label: localizations.reports,
              color: colorScheme.primary,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.reports);
              },
              colorScheme: colorScheme,
            ),
          ),
          
          const SizedBox(width: DesktopDimensions.spacingSmall),
          
          // 3. Quick Action: Stock
          Tooltip(
            message: localizations.stockManagement,
            child: _buildQuickActionButton(
              icon: Icons.inventory_2,
              label: localizations.stockManagement,
              color: colorScheme.primary,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.stock);
              },
              colorScheme: colorScheme,
            ),
          ),
          
          const SizedBox(width: DesktopDimensions.spacingSmall),
          
          // 4. Quick Action: Cash Ledger
          Tooltip(
            message: localizations.cashLedger,
            child: _buildQuickActionButton(
              icon: Icons.account_balance_wallet,
              label: localizations.cashLedger,
              color: colorScheme.primary,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.cashLedger);
              },
              colorScheme: colorScheme,
            ),
          ),
          
          const Spacer(),
          
          // Keyboard Shortcuts Button
          Tooltip(
            message: 'Keyboard Shortcuts',
            child: _HoverableActionIcon(
              icon: Icon(Icons.keyboard, size: 20, color: colorScheme.primary),
              color: colorScheme.primary,
              onTap: _showKeyboardShortcutsDialog,
            ),
          ),
          
          const SizedBox(width: DesktopDimensions.spacingSmall),
          
          // 5. Search Button
          _HoverableActionIcon(
            icon: Icon(Icons.search, size: 20, color: colorScheme.primary),
            color: colorScheme.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!'), duration: Duration(seconds: 2)),
              );
            },
          ),
          
          const SizedBox(width: DesktopDimensions.spacingSmall),
          
          // 6. Refresh Button
          _HoverableActionIcon(
            color: colorScheme.primary,
            onTap: _isRefreshing ? null : _loadData,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                  )
                : Icon(Icons.refresh, size: 20, color: colorScheme.primary),
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
    required ColorScheme colorScheme,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) return colorScheme.primaryContainer;
              if (states.contains(MaterialState.pressed)) return colorScheme.primaryContainer.withOpacity(0.8);
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(AppLocalizations localizations, ColorScheme colorScheme) {
    // Using SizedBox to constrain height for the Spacer() inside cards
    // Row + Expanded ensures equal width distribution without aspect ratio issues
    return SizedBox(
      height: DesktopDimensions.kpiHeight,
      child: FocusTraversalGroup(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildKPICard(
                title: localizations.todaySales,
                value: Money(todaySales).formattedNoDecimal,
                icon: Icons.attach_money,
                color: colorScheme.primary,
                trend: '+12%',
                trendUp: true,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.reports);
                },
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: DesktopDimensions.spacingMedium),
            Expanded(
              child: _buildKPICard(
                title: localizations.pendingAmount,
                value: Money(_calculatePendingCredits()).formattedNoDecimal,
                icon: Icons.credit_card,
                color: colorScheme.secondary,
                subtitle: '${todayCustomers.length} ${localizations.customers}',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.customers);
                },
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: DesktopDimensions.spacingMedium),
            Expanded(
              child: _buildKPICard(
                title: localizations.lowStock,
                value: '${lowStockItems.length}',
                icon: Icons.warning_amber,
                color: colorScheme.error,
                subtitle: localizations.itemsNeedRestock,
                isAlert: lowStockItems.length > 5,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.stock);
                },
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: DesktopDimensions.spacingMedium),
            Expanded(
              child: _buildKPICard(
                title: localizations.totalCustomers,
                value: '${todayCustomers.length}',
                icon: Icons.people,
                color: colorScheme.tertiary,
                subtitle: localizations.activeToday,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.customers);
                },
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD FOR LOCALIZATION - MISSING
  // ========================================================================
  
  String _buildOnlyLeftText(AppLocalizations localizations, dynamic stock, String unit) {
    try {
      return localizations.onlyLeft(stock, unit);
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
    required ColorScheme colorScheme,
  }) {
    return _HoverableCard(
      onTap: onTap,
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingMedium,
          vertical: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: DesktopDimensions.kpiIconSize),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendUp
                          ? colorScheme.primary.withOpacity(0.1)
                          : colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: trendUp ? colorScheme.primary : colorScheme.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trendUp ? colorScheme.primary : colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isAlert && trend == null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.priority_high, color: colorScheme.onError, size: 12),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: DesktopDimensions.kpiValueSize,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: DesktopDimensions.captionSize, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // DETAILS GRID (CUSTOMERS + LOW STOCK)
  // ========================================================================
  
  Widget _buildDetailsGrid(AppLocalizations localizations, ColorScheme colorScheme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT COLUMN: Customer summaries, Sales summaries
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildCustomersCard(localizations, colorScheme)),
              ],
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          // RIGHT COLUMN: Low stock, Alerts or secondary cards
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildLowStockCard(localizations, colorScheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersCard(AppLocalizations localizations, ColorScheme colorScheme) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation ?? DesktopDimensions.cardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: colorScheme.tertiary, size: 28),
                const SizedBox(width: DesktopDimensions.spacingStandard),
                Text(
                  localizations.todaysCustomers,
                  style: TextStyle(fontSize: DesktopDimensions.headingSize, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
            if (todayCustomers.isNotEmpty) ...[
              const SizedBox(height: DesktopDimensions.spacingMedium),
              const Divider(),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              ...todayCustomers.take(5).map((customer) {
                final name = customer['name_english']?.toString() ?? 
                             customer['name_urdu']?.toString() ?? 
                             localizations.cashSale;
                final amount = (customer['total_amount'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.tertiaryContainer,
                        radius: 18,
                        child: Icon(Icons.person, size: 18, color: colorScheme.onTertiaryContainer),
                      ),
                      const SizedBox(width: DesktopDimensions.spacingStandard),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: DesktopDimensions.bodySize, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Money(amount).formattedNoDecimal,
                        style: TextStyle(
                          fontSize: DesktopDimensions.bodySize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        localizations.noCustomersToday,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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

  Widget _buildLowStockCard(AppLocalizations localizations, ColorScheme colorScheme) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation ?? DesktopDimensions.cardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: colorScheme.error, size: 28),
                const SizedBox(width: DesktopDimensions.spacingStandard),
                Text(
                  localizations.lowStock,
                  style: TextStyle(fontSize: DesktopDimensions.headingSize, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ],
            ),
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: DesktopDimensions.spacingMedium),
              const Divider(),
              const SizedBox(height: DesktopDimensions.spacingStandard),
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
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2, size: 18, color: colorScheme.onErrorContainer),
                      ),
                      const SizedBox(width: DesktopDimensions.spacingStandard),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(fontSize: DesktopDimensions.bodySize, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _buildOnlyLeftText(localizations, stock, unit),
                              style: TextStyle(fontSize: DesktopDimensions.captionSize, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.outline),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        'All items in stock',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
  
  Widget _buildRecentSalesCard(AppLocalizations localizations, ColorScheme colorScheme) {
  return Card(
    elevation: Theme.of(context).cardTheme.elevation ?? DesktopDimensions.cardElevation,
    color: colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED HEADER (Doesn't scroll)
        Padding(
          padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
          child: Row(
            children: [
              Icon(Icons.timeline, color: colorScheme.primary, size: 28),
              const SizedBox(width: DesktopDimensions.spacingStandard),
              Text(
                localizations.recentActivities,
                style: TextStyle(fontSize: DesktopDimensions.headingSize, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const Spacer(),
              if (_isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
            ],
          ),
        ),
        
        _buildDivider(colorScheme),
        
        // TABLE HEADER (Fixed)
        if (recentSales.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesktopDimensions.cardPadding, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    localizations.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    localizations.activityType,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 85,
                  child: Text(
                    localizations.time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    localizations.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        
        // SCROLLABLE ACTIVITIES LIST
        if (recentSales.isNotEmpty)
          Expanded(
            child: Scrollbar(
              controller: _activitiesScroller,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _activitiesScroller,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: recentSales.length,
                separatorBuilder: (context, index) => _buildDivider(colorScheme, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final activity = recentSales[index];
                  return _buildActivityRow(activity, localizations, colorScheme);
                },
              ),
            ),
          )
        else
          // EMPTY STATE
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(DesktopDimensions.spacingLarge * 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timeline_outlined, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      localizations.noActivitiesYet,
                      style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
  }
  // NEW METHOD: Build individual activity row
  Widget _buildActivityRow(Map<String, dynamic> activity, AppLocalizations localizations, ColorScheme colorScheme) {
  final activityType = activity['activity_type']?.toString();
  final status = activity['status']?.toString();
  
  return _HoverableListItem(
    child: Container(
    padding: const EdgeInsets.symmetric(horizontal: DesktopDimensions.cardPadding, vertical: 8),
    child: Row(
      children: [
        // Column 1: Bill Number / Title with Icon
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getActivityColor(activityType, colorScheme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activityType),
                  color: _getActivityColor(activityType, colorScheme),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title']?.toString() ?? localizations.unknown,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity['customer_name'] != null)
                      Text(
                        activity['customer_name'].toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
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
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActivityDescription(activity, localizations),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getActivityDetails(activity, localizations),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Column 3: Time
        SizedBox(
          width: 85,
          child: Text(
            _getRelativeTime(activity['timestamp']?.toString(), localizations),
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Column 4: Status Badge
        SizedBox(
          width: 100,
          child: Center(
            child: _buildStatusBadge(status, localizations, colorScheme),
          ),
        ),
      ],
    ),
    ),
  );
  }

  // NEW METHOD: Build status badge
Widget _buildStatusBadge(String? status, AppLocalizations localizations, ColorScheme colorScheme) {
  Color bgColor;
  Color textColor;
  String label;
  
  switch (status?.toUpperCase()) {
    case 'CANCELLED':
      bgColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      label = localizations.cancelled;
      break;
    case 'COMPLETED':
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      label = localizations.completed;
      break;
    case 'URGENT':
      bgColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      label = localizations.urgent;
      break;
    case 'PENDING':
      bgColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
      label = localizations.pending;
      break;
    default:
      bgColor = colorScheme.surfaceVariant;
      textColor = colorScheme.onSurfaceVariant;
      label = localizations.completed;
  }
  
  return Container(
    constraints: const BoxConstraints(minWidth: 85),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
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

  Color _getActivityColor(String? type, ColorScheme colorScheme) {
    switch (type) {
      case 'SALE':
        return colorScheme.primary;
      case 'PAYMENT':
        return colorScheme.tertiary;
      case 'ALERT':
        return colorScheme.error;
      case 'CUSTOMER':
        return colorScheme.secondary;
      case 'STOCK':
        return colorScheme.outline;
      default:
        return colorScheme.outline;
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
        final amount = (activity['amount'] as num?)?.toInt() ?? 0;
        final customer = activity['customer_name']?.toString() ?? localizations.cashSale;
        return '$customer - ${Money(amount).formattedNoDecimal}';
      case 'PAYMENT':
        final amount = (activity['amount'] as num?)?.toInt() ?? 0;
        return Money(amount).formattedNoDecimal;
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

  Widget _buildDivider(ColorScheme colorScheme, {double indent = 0, double endIndent = 0}) {
    return Divider(
      height: 1,
      color: colorScheme.outlineVariant,
      indent: indent,
      endIndent: endIndent,
    );
  }

  // ========================================================================
  // FOOTER BAR
  // ========================================================================
  
  Widget _buildFooterBar(AppLocalizations localizations, ColorScheme colorScheme) {
    return Container(
      height: DesktopDimensions.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesktopDimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.storage, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            localizations.databaseConnected,
            style: TextStyle(fontSize: DesktopDimensions.captionSize, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: DesktopDimensions.spacingLarge),
          Icon(Icons.backup, size: 14, color: colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(
            '${localizations.lastBackup}: 2 hrs ago',
            style: TextStyle(fontSize: DesktopDimensions.captionSize, color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            'v1.0.0',
            style: TextStyle(fontSize: DesktopDimensions.captionSize, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: DesktopDimensions.spacingStandard),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            localizations.systemOk,
            style: TextStyle(
              fontSize: DesktopDimensions.captionSize,
              color: colorScheme.onSurfaceVariant,
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

// ignore: unused_element
class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

// ignore: unused_element
class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

// ignore: unused_element
class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}

// ============================================================================
// REUSABLE HOVER WIDGETS
// ============================================================================

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: DesktopDimensions.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesktopDimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // LEFT: Dashboard Label
          SizedBox(
            width: 100, // Keeping fixed width for alignment
            child: Text(
              localizations.dashboard,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ),
          
          // CENTER: Shop Name
          Expanded(
            child: Center(
              child: Text(
                localizations.appTitle,
                style: TextStyle(
                  fontSize: DesktopDimensions.appTitleSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
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
                const LiveClock(),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.account_circle, color: colorScheme.onPrimary, size: 28),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                  tooltip: localizations.settings,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm a').format(now);
      _currentDate = DateFormat('dd MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: DesktopDimensions.clockWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.onPrimary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 14, color: colorScheme.onPrimary.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(
                _currentTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _currentDate,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;

  const _HoverableCard({
    required this.child,
    required this.onTap,
    required this.color,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHoveredOrFocused = _isHovered || _isFocused;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isHoveredOrFocused ? 0.15 : 0.05),
              blurRadius: isHoveredOrFocused ? 8 : 2,
              offset: Offset(0, isHoveredOrFocused ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: isHoveredOrFocused ? widget.color.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _isFocused = value),
            borderRadius: BorderRadius.circular(12),
            hoverColor: widget.color.withOpacity(0.05),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _HoverableActionIcon extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final Color color;

  const _HoverableActionIcon({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<_HoverableActionIcon> createState() => _HoverableActionIconState();
}

class _HoverableActionIconState extends State<_HoverableActionIcon> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isHoveredOrFocused = _isHovered || _isFocused;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => _isFocused = value),
          borderRadius: BorderRadius.circular(8),
          hoverColor: widget.color.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHoveredOrFocused ? widget.color : widget.color.withOpacity(0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isHoveredOrFocused ? widget.color.withOpacity(0.05) : Colors.transparent,
            ),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}

class _HoverableListItem extends StatefulWidget {
  final Widget child;

  const _HoverableListItem({required this.child});

  @override
  State<_HoverableListItem> createState() => _HoverableListItemState();
}

class _HoverableListItemState extends State<_HoverableListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? colorScheme.surfaceVariant.withOpacity(0.3) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: _isHovered ? colorScheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}