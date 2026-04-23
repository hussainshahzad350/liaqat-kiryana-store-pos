// lib/widgets/app_shell.dart
//
// Single persistent shell that hosts the sidebar, header, and an IndexedStack
// of all post-login screens.  Only the active screen's content is repainted
// when the user navigates; the sidebar and header are NEVER rebuilt or disposed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/purchase/purchase_bloc.dart';
import '../bloc/purchase/purchase_event.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/stock/stock_activity/stock_activity_bloc.dart';
import '../bloc/stock/stock_activity/stock_activity_event.dart';
import '../bloc/stock/stock_filter/stock_filter_bloc.dart';
import '../bloc/stock/stock_filter/stock_filter_event.dart';
import '../bloc/stock/stock_overview/stock_overview_bloc.dart';
import '../bloc/stock/stock_overview/stock_overview_event.dart';
import '../bloc/stock/stock_ui/stock_ui_cubit.dart';
import '../bloc/units/units_bloc.dart';
import '../bloc/units/units_event.dart';
import '../core/cubits/sidebar_cubit.dart';
import '../core/repositories/categories_repository.dart';
import '../core/repositories/customers_repository.dart';
import '../core/repositories/invoice_repository.dart';
import '../core/repositories/items_repository.dart';
import '../core/repositories/purchase_repository.dart';
import '../core/repositories/receipt_repository.dart';
import '../core/repositories/settings_repository.dart';
import '../core/repositories/stock_activity_repository.dart';
import '../core/repositories/stock_repository.dart';
import '../core/repositories/suppliers_repository.dart';
import '../core/repositories/units_repository.dart';
import '../core/routes/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../screens/about/about_screen.dart';
import '../screens/cash_ledger/cash_ledger_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/items/items_screen.dart';
import '../screens/purchase/purchase_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stock/stock_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/units/units_screen.dart';
import 'app_header.dart';
import 'app_navigation_sidebar.dart';

// ---------------------------------------------------------------------------
// Route → index mapping (used by both AppShell and AppNavigationSidebar)
// ---------------------------------------------------------------------------

const _kRouteIndex = <String, int>{
  AppRoutes.home: 0,
  AppRoutes.sales: 1,
  AppRoutes.stock: 2,
  AppRoutes.purchase: 3,
  AppRoutes.items: 4,
  AppRoutes.customers: 5,
  AppRoutes.suppliers: 6,
  AppRoutes.categories: 7,
  AppRoutes.units: 8,
  AppRoutes.reports: 9,
  AppRoutes.cashLedger: 10,
  AppRoutes.settings: 11,
  AppRoutes.about: 12,
};

const _kIndexRoute = <int, String>{
  0: AppRoutes.home,
  1: AppRoutes.sales,
  2: AppRoutes.stock,
  3: AppRoutes.purchase,
  4: AppRoutes.items,
  5: AppRoutes.customers,
  6: AppRoutes.suppliers,
  7: AppRoutes.categories,
  8: AppRoutes.units,
  9: AppRoutes.reports,
  10: AppRoutes.cashLedger,
  11: AppRoutes.settings,
  12: AppRoutes.about,
};

// ---------------------------------------------------------------------------
// AppShell
// ---------------------------------------------------------------------------

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  // ── Static navigation helper ────────────────────────────────────────────
  /// Called by [AppNavigationSidebar] instead of Navigator.pushReplacementNamed.
  /// Uses the InheritedWidget trick to reach [_AppShellState] from anywhere
  /// below the shell in the tree.
  static void navigateTo(BuildContext context, String route) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    assert(state != null, 'AppShell.navigateTo called outside AppShell tree');
    final index = _kRouteIndex[route];
    if (index != null) state!._setIndex(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _setIndex(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  String get _currentRoute => _kIndexRoute[_currentIndex] ?? AppRoutes.home;

  // ── Keyboard shortcuts ──────────────────────────────────────────────────
  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyN, control: true): _NewSaleIntent(),
    SingleActivator(LogicalKeyboardKey.keyR, control: true): _RefreshIntent(),
    SingleActivator(LogicalKeyboardKey.keyB, control: true): _ToggleSidebarIntent(),
  };

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewSaleIntent: CallbackAction<_NewSaleIntent>(onInvoke: (_) {
            _setIndex(_kRouteIndex[AppRoutes.sales]!);
            return null;
          }),
          _RefreshIntent: CallbackAction<_RefreshIntent>(onInvoke: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.refreshingData,
                  style: TextStyle(color: colorScheme.onInverseSurface),
                ),
                backgroundColor: colorScheme.inverseSurface,
              ),
            );
            return null;
          }),
          _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(
              onInvoke: (_) {
            context.read<SidebarCubit>().toggle();
            return null;
          }),
        },
        child: FocusTraversalGroup(
          child: Scaffold(
            body: Row(
              children: [
                // ── Sidebar — built ONCE, never disposed on navigation ───
                AppNavigationSidebar(currentRoute: _currentRoute),

                // ── Main area ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Header — built ONCE
                      AppHeader(currentRoute: _currentRoute),

                      // Screen content — only this swaps
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _buildScreens(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds all screen widgets wrapped in their required BlocProviders.
  /// IndexedStack keeps all children alive but only paints the active one,
  /// so BLoC/Cubits for every screen are created once at shell startup.
  List<Widget> _buildScreens(BuildContext context) {
    return [
      // 0 — Home
      const HomeScreen(),

      // 1 — Sales
      BlocProvider(
        create: (ctx) => SalesBloc(
          invoiceRepository: ctx.read<InvoiceRepository>(),
          itemsRepository: ctx.read<ItemsRepository>(),
          customersRepository: ctx.read<CustomersRepository>(),
          settingsRepository: ctx.read<SettingsRepository>(),
          receiptRepository: ctx.read<ReceiptRepository>(),
        ),
        child: const SalesScreen(),
      ),

      // 2 — Stock
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => StockUiCubit()),
          BlocProvider(
            create: (ctx) =>
                StockOverviewBloc(ctx.read<StockRepository>())
                  ..add(const LoadStockOverview()),
          ),
          BlocProvider(
            create: (ctx) => StockFilterBloc(
              ctx.read<SuppliersRepository>(),
              ctx.read<CategoriesRepository>(),
            )..add(LoadFilters()),
          ),
          BlocProvider(
            create: (ctx) => StockActivityBloc(
              ctx.read<StockActivityRepository>(),
              ctx.read<ItemsRepository>(),
              ctx.read<PurchaseRepository>(),
              ctx.read<InvoiceRepository>(),
            )..add(const LoadStockActivities()),
          ),
        ],
        child: const StockScreen(),
      ),

      // 3 — Purchase
      BlocProvider(
        create: (ctx) => PurchaseBloc(
          purchaseRepository: ctx.read<PurchaseRepository>(),
          suppliersRepository: ctx.read<SuppliersRepository>(),
          itemsRepository: ctx.read<ItemsRepository>(),
        )..add(InitializePurchase()),
        child: const PurchaseScreen(),
      ),

      // 4 — Items
      const ItemsScreen(),

      // 5 — Customers
      const CustomersScreen(),

      // 6 — Suppliers
      const SuppliersScreen(),

      // 7 — Categories
      const CategoriesScreen(),

      // 8 — Units
      BlocProvider(
        create: (ctx) =>
            UnitsBloc(ctx.read<UnitsRepository>())..add(LoadUnits()),
        child: const UnitsScreen(),
      ),

      // 9 — Reports
      const ReportsScreen(),

      // 10 — Cash Ledger
      const CashLedgerScreen(),

      // 11 — Settings
      const SettingsScreen(),

      // 12 — About
      const AboutScreen(),
    ];
  }
}

// ---------------------------------------------------------------------------
// Intent classes (keyboard shortcuts)
// ---------------------------------------------------------------------------

class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}
