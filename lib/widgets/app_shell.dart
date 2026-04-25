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
  final String initialRoute;

  const AppShell({
    super.key,
    this.initialRoute = AppRoutes.home,
  });

  // ── Static navigation helper ────────────────────────────────────────────
  /// Called by [AppNavigationSidebar] instead of Navigator.pushReplacementNamed.
  /// Uses the InheritedWidget trick to reach [_AppShellState] from anywhere
  /// below the shell in the tree.
  static void navigateTo(BuildContext context, String route) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    if (state == null) return;

    final index = _kRouteIndex[route];
    if (index == null) return;

    state._setIndex(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  final Map<int, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = _kRouteIndex[widget.initialRoute] ?? 0;
  }

  void _setIndex(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  String get _currentRoute => _kIndexRoute[_currentIndex] ?? AppRoutes.home;

  Widget _getOrCreateScreen(int index, BuildContext context) {
    return _screenCache.putIfAbsent(index, () => _buildScreen(index, context));
  }

  // ── Keyboard shortcuts ──────────────────────────────────────────────────
  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyN, control: true): _NewSaleIntent(),
    SingleActivator(LogicalKeyboardKey.keyR, control: true): _RefreshIntent(),
    SingleActivator(LogicalKeyboardKey.keyB, control: true):
        _ToggleSidebarIntent(),
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
          _ToggleSidebarIntent:
              CallbackAction<_ToggleSidebarIntent>(onInvoke: (_) {
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
                          children: List.generate(
                            _kIndexRoute.length,
                            (index) {
                              if (index == _currentIndex) {
                                return _getOrCreateScreen(index, context);
                              }
                              return _screenCache[index] ??
                                  const SizedBox.shrink();
                            },
                          ),
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

  /// Lazily builds one screen wrapped in its required BlocProviders.
  /// Each screen is created only on first visit and then kept in [_screenCache].
  Widget _buildScreen(int index, BuildContext context) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return BlocProvider(
          create: (ctx) => SalesBloc(
            invoiceRepository: ctx.read<InvoiceRepository>(),
            itemsRepository: ctx.read<ItemsRepository>(),
            customersRepository: ctx.read<CustomersRepository>(),
            settingsRepository: ctx.read<SettingsRepository>(),
            receiptRepository: ctx.read<ReceiptRepository>(),
          ),
          child: const SalesScreen(),
        );
      case 2:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => StockUiCubit()),
            BlocProvider(
              create: (ctx) => StockOverviewBloc(ctx.read<StockRepository>())
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
        );
      case 3:
        return BlocProvider(
          create: (ctx) => PurchaseBloc(
            purchaseRepository: ctx.read<PurchaseRepository>(),
            suppliersRepository: ctx.read<SuppliersRepository>(),
            itemsRepository: ctx.read<ItemsRepository>(),
          )..add(InitializePurchase()),
          child: const PurchaseScreen(),
        );
      case 4:
        return const ItemsScreen();
      case 5:
        return const CustomersScreen();
      case 6:
        return const SuppliersScreen();
      case 7:
        return const CategoriesScreen();
      case 8:
        return BlocProvider(
          create: (ctx) =>
              UnitsBloc(ctx.read<UnitsRepository>())..add(LoadUnits()),
          child: const UnitsScreen(),
        );
      case 9:
        return const ReportsScreen();
      case 10:
        return const CashLedgerScreen();
      case 11:
        return const SettingsScreen();
      case 12:
        return const AboutScreen();
      default:
        return const HomeScreen();
    }
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
