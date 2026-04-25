// lib/screens/home/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/res/app_tokens.dart';
import '../../domain/entities/money.dart';
import '../../models/invoice_model.dart';
import '../../widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.todaySalesLoader,
    this.todayCustomersLoader,
    this.lowStockItemsLoader,
    this.recentSalesLoader,
    this.invoiceRepository,
    this.customersRepository,
    this.itemsRepository,
    this.refreshSignal,
  });

  final Future<int> Function()? todaySalesLoader;
  final Future<List<Map<String, dynamic>>> Function()? todayCustomersLoader;
  final Future<List<Map<String, dynamic>>> Function()? lowStockItemsLoader;
  final Future<List<Map<String, dynamic>>> Function()? recentSalesLoader;

  final InvoiceRepository? invoiceRepository;
  final CustomersRepository? customersRepository;
  final ItemsRepository? itemsRepository;

  /// Optional [Listenable] that signals the dashboard to reload its data.
  /// [AppShell] increments this notifier each time the Home tab becomes active,
  /// ensuring the dashboard is always fresh after navigating away and back
  /// (e.g. after completing a sale on the Sales screen).
  final Listenable? refreshSignal;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final InvoiceRepository _invoiceRepository;
  late final CustomersRepository _customersRepository;
  late final ItemsRepository _itemsRepository;

  // State variables
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
    _invoiceRepository =
        widget.invoiceRepository ?? context.read<InvoiceRepository>();
    _customersRepository =
        widget.customersRepository ?? context.read<CustomersRepository>();
    _itemsRepository =
        widget.itemsRepository ?? context.read<ItemsRepository>();

    dataTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    widget.refreshSignal?.addListener(_onRefreshSignal);
    _loadData();
  }

  void _onRefreshSignal() => _loadData();

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshSignal);
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
        (widget.todaySalesLoader ?? _invoiceRepository.getTodaySalesTotal)(),
        (widget.todayCustomersLoader ??
            _customersRepository.getTodayCustomers)(),
        (widget.lowStockItemsLoader ?? _itemsRepository.getLowStockItems)(),
        (widget.recentSalesLoader ?? _loadRecentSales)(),
      ]);

      if (!mounted) return;

      setState(() {
        todaySales = results[0] as int;
        todayCustomers = results[1] as List<Map<String, dynamic>>;
        lowStockItems = results[2] as List<Map<String, dynamic>>;
        recentSales = results[3] as List<Map<String, dynamic>>;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: AppTokens.spacingStandard),
                Expanded(
                    child: Text(AppLocalizations.of(context)!
                        .failedToLoadDashboardData(e.toString()))),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              textColor: Theme.of(context).colorScheme.onError,
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

  Future<List<Map<String, dynamic>>> _loadRecentSales() async {
    final invoices =
        await _invoiceRepository.getRecentInvoicesWithCustomer(limit: 10);
    return invoices
        .map(
          (Invoice invoice) => {
            'activity_type': 'SALE',
            'title': invoice.invoiceNumber,
            'customer_name': invoice.customerName,
            'amount': invoice.totalAmount,
            'timestamp': invoice.date.toIso8601String(),
            'status': invoice.status,
          },
        )
        .toList();
  }

  int _calculatePendingCredits() {
    int total = 0;
    for (var customer in todayCustomers) {
      total += (customer['total_amount'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  void _navigateTo(String route) {
    AppShell.navigateTo(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f5): _RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _NewSaleIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (intent) => _loadData(),
          ),
          _NewSaleIntent: CallbackAction<_NewSaleIntent>(
            onInvoke: (intent) {
              _navigateTo(AppRoutes.sales);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // 2. Action Bar (Full Width)
              _buildActionBar(localizations, colorScheme),

              // 3. Main Content (Left + Right with Responsive Layout)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildResponsiveLayout(
                        constraints, localizations, colorScheme);
                  },
                ),
              ),

              // 3. Footer Bar
              _buildFooterBar(localizations, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // RESPONSIVE LAYOUT METHODS
  // ========================================================================

  Widget _buildResponsiveLayout(
    BoxConstraints constraints,
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    if (constraints.maxWidth >= AppTokens.breakpointLarge) {
      return _buildSideBySideLayout(
        sidebarWidth: AppTokens.sidebarWidthLarge,
        localizations: localizations,
        colorScheme: colorScheme,
      );
    } else if (constraints.maxWidth >= AppTokens.breakpointMedium) {
      return _buildSideBySideLayout(
        sidebarWidth: AppTokens.sidebarWidthMedium,
        localizations: localizations,
        colorScheme: colorScheme,
      );
    } else if (constraints.maxWidth >= AppTokens.breakpointSmall) {
      return _buildSideBySideLayout(
        sidebarWidth: AppTokens.sidebarWidthSmall,
        localizations: localizations,
        colorScheme: colorScheme,
      );
    } else {
      return _buildStackedLayout(localizations, colorScheme);
    }
  }

  Widget _buildSideBySideLayout({
    required double sidebarWidth,
    required AppLocalizations localizations,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT PANEL: Main Dashboard (KPIs + Details)
        Expanded(
          child: Column(
            children: [
              // Scrollable Content
              Expanded(
                child: Scrollbar(
                  controller: _leftPanelScroller,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _leftPanelScroller,
                    padding: const EdgeInsets.all(AppTokens.spacingLarge),
                    child: Column(
                      children: [
                        // KPI Grid
                        _buildKPIGrid(localizations, colorScheme),
                        const SizedBox(height: AppTokens.spacingLarge),
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
        VerticalDivider(
            width: 1, thickness: 1, color: colorScheme.outlineVariant),

        // RIGHT PANEL: Sidebar
        SizedBox(
          width: sidebarWidth,
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(AppTokens.spacingMedium),
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
    );
  }

  Widget _buildStackedLayout(
      AppLocalizations localizations, ColorScheme colorScheme) {
    return Column(
      children: [
        // Scrollable All Content
        Expanded(
          child: Scrollbar(
            controller: _leftPanelScroller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _leftPanelScroller,
              padding: const EdgeInsets.all(AppTokens.spacingMedium),
              child: Column(
                children: [
                  // KPI Grid
                  _buildKPIGrid(localizations, colorScheme),
                  const SizedBox(height: AppTokens.spacingMedium),

                  // Details Grid
                  _buildDetailsGrid(localizations, colorScheme),
                  const SizedBox(height: AppTokens.spacingMedium),

                  // Recent Activity (Previously in sidebar)
                  // We give it a fixed height so it scrolls within the main scroller
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6),
                    child: _buildRecentSalesCard(localizations, colorScheme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showKeyboardShortcutsDialog() {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.keyboard),
            const SizedBox(width: AppTokens.spacingSmall),
            Text(localizations.keyboardShortcuts),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutItem(localizations.newSale,
                localizations.shortcutCtrlN, colorScheme),
            _buildShortcutItem(localizations.refreshDashboard,
                localizations.shortcutF5, colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(
      String label, String shortcut, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingSmall,
              vertical: AppTokens.spacingXSmall,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.smallBorderRadius),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              shortcut,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildActionBar(
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMedium,
          vertical: AppTokens.spacingStandard),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. Primary Action: New Sale Button
            ElevatedButton.icon(
              onPressed: () {
                _navigateTo(AppRoutes.sales);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space24,
                    vertical: AppTokens.spacingStandard),
                elevation: 3,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
                side: BorderSide(color: colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radius8)),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return colorScheme.primaryContainer;
                    }
                    return null;
                  },
                ),
                elevation: WidgetStateProperty.resolveWith<double>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) return 6;
                    return 3;
                  },
                ),
              ),
              icon: Icon(Icons.add_shopping_cart,
                  size: 22, color: colorScheme.primary),
              label: Text(
                localizations.generateBillWithShortcut,
                style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),

            const SizedBox(width: AppTokens.spacingSmall),

            // 2. Quick Action: Reports
            Tooltip(
              message: localizations.reports,
              child: _buildQuickActionButton(
                icon: Icons.bar_chart,
                label: localizations.reports,
                color: colorScheme.primary,
                onPressed: () {
                  _navigateTo(AppRoutes.reports);
                },
                colorScheme: colorScheme,
              ),
            ),

            const SizedBox(width: AppTokens.spacingSmall),

            // 3. Quick Action: Stock
            Tooltip(
              message: localizations.stockManagement,
              child: _buildQuickActionButton(
                icon: Icons.inventory_2,
                label: localizations.stockManagement,
                color: colorScheme.primary,
                onPressed: () {
                  _navigateTo(AppRoutes.stock);
                },
                colorScheme: colorScheme,
              ),
            ),

            const SizedBox(width: AppTokens.spacingSmall),

            // 4. Quick Action: Cash Ledger
            Tooltip(
              message: localizations.cashLedger,
              child: _buildQuickActionButton(
                icon: Icons.account_balance_wallet,
                label: localizations.cashLedger,
                color: colorScheme.primary,
                onPressed: () {
                  _navigateTo(AppRoutes.cashLedger);
                },
                colorScheme: colorScheme,
              ),
            ),

            const SizedBox(width: AppTokens.spacingLarge),

            // Keyboard Shortcuts Button
            Tooltip(
              message: localizations.keyboardShortcuts,
              child: _HoverableActionIcon(
                icon:
                    Icon(Icons.keyboard, size: 20, color: colorScheme.primary),
                color: colorScheme.primary,
                onTap: _showKeyboardShortcutsDialog,
              ),
            ),

            const SizedBox(width: AppTokens.spacingSmall),

            // 5. Search Button
            _HoverableActionIcon(
              icon: Icon(Icons.search, size: 20, color: colorScheme.primary),
              color: colorScheme.primary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(localizations.searchFeatureComingSoon),
                      duration: const Duration(seconds: 2)),
                );
              },
            ),

            const SizedBox(width: AppTokens.spacingSmall),

            // 6. Refresh Button
            _HoverableActionIcon(
              color: colorScheme.primary,
              onTap: _isRefreshing ? null : _loadData,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.primary),
                    )
                  : Icon(Icons.refresh, size: 20, color: colorScheme.primary),
            ),
          ],
        ),
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
    final textTheme = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMedium,
              vertical: AppTokens.spacingStandard),
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius8)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return colorScheme.primaryContainer;
              }
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primaryContainer.withValues(alpha: 0.8);
              }
              return null;
            },
          ),
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) return 4;
              return 2;
            },
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: color, width: 2);
              }
              return BorderSide(color: color, width: 1.5);
            },
          ),
        ),
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(
      AppLocalizations localizations, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // Narrow: 2x2 Grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      title: localizations.todaySales,
                      value: Money(todaySales).formattedNoDecimal,
                      icon: Icons.attach_money,
                      color: colorScheme.primary,
                      trend: '+12%',
                      trendUp: true,
                      onTap: () => _navigateTo(AppRoutes.reports),
                      colorScheme: colorScheme,
                      localizations: localizations,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  Expanded(
                    child: _buildKPICard(
                      title: localizations.pendingAmount,
                      value:
                          Money(_calculatePendingCredits()).formattedNoDecimal,
                      icon: Icons.credit_card,
                      color: colorScheme.secondary,
                      subtitle:
                          '${todayCustomers.length} ${localizations.customers}',
                      onTap: () => _navigateTo(AppRoutes.customers),
                      colorScheme: colorScheme,
                      localizations: localizations,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      title: localizations.lowStock,
                      value: '${lowStockItems.length}',
                      icon: Icons.warning_amber,
                      color: colorScheme.error,
                      subtitle: localizations.itemsNeedRestock,
                      isAlert: lowStockItems.length > 5,
                      onTap: () => _navigateTo(AppRoutes.stock),
                      colorScheme: colorScheme,
                      localizations: localizations,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  Expanded(
                    child: _buildKPICard(
                      title: localizations.totalCustomers,
                      value: '${todayCustomers.length}',
                      icon: Icons.people,
                      color: colorScheme.tertiary,
                      subtitle: localizations.activeToday,
                      onTap: () => _navigateTo(AppRoutes.customers),
                      colorScheme: colorScheme,
                      localizations: localizations,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Wide: Standard Single Row
        return SizedBox(
          height: AppTokens.kpiHeight,
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
                  onTap: () => _navigateTo(AppRoutes.reports),
                  colorScheme: colorScheme,
                  localizations: localizations,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: _buildKPICard(
                  title: localizations.pendingAmount,
                  value: Money(_calculatePendingCredits()).formattedNoDecimal,
                  icon: Icons.credit_card,
                  color: colorScheme.secondary,
                  subtitle:
                      '${todayCustomers.length} ${localizations.customers}',
                  onTap: () => _navigateTo(AppRoutes.customers),
                  colorScheme: colorScheme,
                  localizations: localizations,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: _buildKPICard(
                  title: localizations.lowStock,
                  value: '${lowStockItems.length}',
                  icon: Icons.warning_amber,
                  color: colorScheme.error,
                  subtitle: localizations.itemsNeedRestock,
                  isAlert: lowStockItems.length > 5,
                  onTap: () => _navigateTo(AppRoutes.stock),
                  colorScheme: colorScheme,
                  localizations: localizations,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: _buildKPICard(
                  title: localizations.totalCustomers,
                  value: '${todayCustomers.length}',
                  icon: Icons.people,
                  color: colorScheme.tertiary,
                  subtitle: localizations.activeToday,
                  onTap: () => _navigateTo(AppRoutes.customers),
                  colorScheme: colorScheme,
                  localizations: localizations,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================================================
  // HELPER METHOD FOR LOCALIZATION - MISSING
  // ========================================================================

  String _buildOnlyLeftText(
      AppLocalizations localizations, dynamic stock, String unit) {
    return localizations.onlyLeft(stock, unit);
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
    required AppLocalizations localizations,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return _HoverableCard(
      onTap: onTap,
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMedium,
          vertical: AppTokens.spacingSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacingSmall),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radius8),
                  ),
                  child: Icon(icon, color: color, size: AppTokens.kpiIconSize),
                ),
                const Spacer(),
                if (trend != null)
                  Tooltip(
                    message: localizations.trendTooltip(trend),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingSmall,
                          vertical: AppTokens.spacingXSmall),
                      decoration: BoxDecoration(
                        color: trendUp
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTokens.radius6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                            color: trendUp
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            trend,
                            style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: trendUp
                                    ? colorScheme.primary
                                    : colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isAlert && trend == null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.priority_high,
                        color: colorScheme.onError, size: 12),
                  ),
              ],
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.spacingXXSmall),
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTokens.spacingXXSmall),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // DETAILS GRID (CUSTOMERS + LOW STOCK)
  // ========================================================================

  Widget _buildDetailsGrid(
      AppLocalizations localizations, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: _buildCustomersCard(localizations, colorScheme),
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: _buildLowStockCard(localizations, colorScheme),
              ),
            ],
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCustomersCard(localizations, colorScheme)),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(child: _buildLowStockCard(localizations, colorScheme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomersCard(
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation:
          Theme.of(context).cardTheme.elevation ?? AppTokens.cardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: colorScheme.tertiary, size: 28),
                const SizedBox(width: AppTokens.spacingStandard),
                Expanded(
                  child: Text(
                    localizations.todaysCustomers,
                    style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (todayCustomers.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingMedium),
              const Divider(),
              const SizedBox(height: AppTokens.spacingStandard),
              ...todayCustomers.take(5).map((customer) {
                final name = customer['name_english']?.toString() ??
                    customer['name_urdu']?.toString() ??
                    localizations.cashSale;
                final amount = (customer['total_amount'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTokens.spacingStandard),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.tertiaryContainer,
                        radius: 18,
                        child: Icon(Icons.person,
                            size: 18, color: colorScheme.onTertiaryContainer),
                      ),
                      const SizedBox(width: AppTokens.spacingStandard),
                      Expanded(
                        child: Text(
                          name,
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Money(amount).formattedNoDecimal,
                        style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: AppTokens.spacingMedium),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.cardPadding),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 48, color: colorScheme.outline),
                      const SizedBox(height: AppTokens.spacingSmall),
                      Text(
                        localizations.noCustomersToday,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
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

  Widget _buildLowStockCard(
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation:
          Theme.of(context).cardTheme.elevation ?? AppTokens.cardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: colorScheme.error, size: 28),
                const SizedBox(width: AppTokens.spacingStandard),
                Text(
                  localizations.lowStock,
                  style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
              ],
            ),
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingMedium),
              const Divider(),
              const SizedBox(height: AppTokens.spacingStandard),
              ...lowStockItems.take(5).map((item) {
                final name = item['name_english']?.toString() ??
                    item['name_urdu']?.toString() ??
                    localizations.unknownItem;
                final stock = item['current_stock'] ?? 0;
                final unit =
                    item['unit_type']?.toString() ?? localizations.units;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTokens.spacingStandard),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spacingSmall),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radius8),
                        ),
                        child: Icon(Icons.inventory_2,
                            size: 18, color: colorScheme.onErrorContainer),
                      ),
                      const SizedBox(width: AppTokens.spacingStandard),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _buildOnlyLeftText(localizations, stock, unit),
                              style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: colorScheme.outline),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: AppTokens.spacingMedium),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.cardPadding),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: colorScheme.primary),
                      const SizedBox(height: AppTokens.spacingSmall),
                      Text(
                        localizations.allStockAvailable,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
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

  Widget _buildRecentSalesCard(
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation:
          Theme.of(context).cardTheme.elevation ?? AppTokens.cardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIXED HEADER (Doesn't scroll)
          Padding(
            padding: const EdgeInsets.all(AppTokens.cardPadding),
            child: Row(
              children: [
                Icon(Icons.timeline, color: colorScheme.primary, size: 28),
                const SizedBox(width: AppTokens.spacingStandard),
                Expanded(
                  child: Text(
                    localizations.recentActivities,
                    style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isRefreshing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colorScheme.primary),
                  ),
              ],
            ),
          ),

          _buildDivider(colorScheme),

          // TABLE HEADER (Fixed)
          if (recentSales.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.cardPadding, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom:
                      BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      localizations.name,
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      localizations.activityType,
                      style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  SizedBox(
                    width: 85,
                    child: Text(
                      localizations.time,
                      style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      localizations.status,
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant),
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
                  separatorBuilder: (context, index) =>
                      _buildDivider(colorScheme, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final activity = recentSales[index];
                    return _buildActivityRow(
                        activity, localizations, colorScheme);
                  },
                ),
              ),
            )
          else
            // EMPTY STATE
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacingLarge * 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timeline_outlined,
                          size: 64, color: colorScheme.outline),
                      const SizedBox(height: AppTokens.spacingStandard),
                      Text(
                        localizations.noActivitiesYet,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
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
  Widget _buildActivityRow(Map<String, dynamic> activity,
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final activityType = activity['activity_type']?.toString();
    final status = activity['status']?.toString();

    return _HoverableListItem(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardPadding, vertical: 8),
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
                      color: _getActivityColor(activityType, colorScheme)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTokens.radius8),
                    ),
                    child: Icon(
                      _getActivityIcon(activityType),
                      color: _getActivityColor(activityType, colorScheme),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title']?.toString() ??
                              localizations.unknown,
                          style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (activity['customer_name'] != null)
                          Text(
                            activity['customer_name'].toString(),
                            style: textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                    style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getActivityDetails(activity, localizations),
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                _getRelativeTime(
                    activity['timestamp']?.toString(), localizations),
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
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
  Widget _buildStatusBadge(
      String? status, AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
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
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = localizations.completed;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 85),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingSmall,
          vertical: AppTokens.spacingXSmall),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radius12),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
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

  String _getActivityDescription(
      Map<String, dynamic> activity, AppLocalizations localizations) {
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
        return localizations.unknown;
    }
  }

  String _getActivityDetails(
      Map<String, dynamic> activity, AppLocalizations localizations) {
    final type = activity['activity_type']?.toString();
    switch (type) {
      case 'SALE':
        final amount = (activity['amount'] as num?)?.toInt() ?? 0;
        final customer =
            activity['customer_name']?.toString() ?? localizations.cashSale;
        return '$customer - ${Money(amount).formattedNoDecimal}';
      case 'PAYMENT':
        final amount = (activity['amount'] as num?)?.toInt() ?? 0;
        return Money(amount).formattedNoDecimal;
      case 'ALERT':
        final stock = activity['stock_level'];
        final unit = activity['unit_name']?.toString() ?? localizations.units;
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

  Widget _buildDivider(ColorScheme colorScheme,
      {double indent = 0, double endIndent = 0}) {
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

  Widget _buildFooterBar(
      AppLocalizations localizations, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: AppTokens.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.storage, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            localizations.databaseConnected,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppTokens.spacingLarge),
          Icon(Icons.backup, size: 14, color: colorScheme.tertiary),
          const SizedBox(width: 6),
          // TODO: Fetch and display the actual last backup time
          Text(
            localizations.lastBackupAt('...'),
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          // TODO: Fetch and display the actual app version
          Text(
            localizations.appVersion('...'),
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppTokens.spacingStandard),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: colorScheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            localizations.systemOk,
            style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600),
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
          borderRadius: BorderRadius.circular(AppTokens.radius12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow
                  .withValues(alpha: isHoveredOrFocused ? 0.15 : 0.05),
              blurRadius: isHoveredOrFocused ? 8 : 2,
              offset: Offset(0, isHoveredOrFocused ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: isHoveredOrFocused
                ? widget.color.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _isFocused = value),
            borderRadius: BorderRadius.circular(AppTokens.radius12),
            hoverColor: widget.color.withValues(alpha: 0.05),
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
          borderRadius: BorderRadius.circular(AppTokens.radius8),
          hoverColor: widget.color.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHoveredOrFocused
                    ? widget.color
                    : widget.color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radius8),
              color: isHoveredOrFocused
                  ? widget.color.withValues(alpha: 0.05)
                  : Colors.transparent,
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
          color: _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : Colors.transparent,
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
