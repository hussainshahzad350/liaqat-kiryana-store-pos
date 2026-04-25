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
// Canonical route registry (ordered). All index/route lookups derive from this.
// ---------------------------------------------------------------------------

final Map<String, Widget Function(BuildContext)> _kRouteBuilders = {
  AppRoutes.home: (_) => const HomeScreen(),
  AppRoutes.sales: (ctx) => BlocProvider(
        create: (context) => SalesBloc(
          invoiceRepository: context.read<InvoiceRepository>(),
          itemsRepository: context.read<ItemsRepository>(),
          customersRepository: context.read<CustomersRepository>(),
          settingsRepository: context.read<SettingsRepository>(),
          receiptRepository: context.read<ReceiptRepository>(),
        ),
        child: const SalesScreen(),
      ),
  AppRoutes.stock: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => StockUiCubit()),
          BlocProvider(
            create: (context) =>
                StockOverviewBloc(context.read<StockRepository>())
                  ..add(const LoadStockOverview()),
          ),
          BlocProvider(
            create: (context) => StockFilterBloc(
              context.read<SuppliersRepository>(),
              context.read<CategoriesRepository>(),
            )..add(LoadFilters()),
          ),
          BlocProvider(
            create: (context) => StockActivityBloc(
              context.read<StockActivityRepository>(),
              context.read<ItemsRepository>(),
              context.read<PurchaseRepository>(),
              context.read<InvoiceRepository>(),
            )..add(const LoadStockActivities()),
          ),
        ],
        child: const StockScreen(),
      ),
  AppRoutes.purchase: (ctx) => BlocProvider(
        create: (context) => PurchaseBloc(
          purchaseRepository: context.read<PurchaseRepository>(),
          suppliersRepository: context.read<SuppliersRepository>(),
          itemsRepository: context.read<ItemsRepository>(),
        )..add(InitializePurchase()),
        child: const PurchaseScreen(),
      ),
  AppRoutes.items: (_) => const ItemsScreen(),
  AppRoutes.customers: (_) => const CustomersScreen(),
  AppRoutes.suppliers: (_) => const SuppliersScreen(),
  AppRoutes.categories: (_) => const CategoriesScreen(),
  AppRoutes.units: (ctx) => BlocProvider(
        create: (context) =>
            UnitsBloc(context.read<UnitsRepository>())..add(LoadUnits()),
        child: const UnitsScreen(),
      ),
  AppRoutes.reports: (_) => const ReportsScreen(),
  AppRoutes.cashLedger: (_) => const CashLedgerScreen(),
  AppRoutes.settings: (_) => const SettingsScreen(),
  AppRoutes.about: (_) => const AboutScreen(),
};

final List<String> _kRoutes = List.unmodifiable(_kRouteBuilders.keys);

/// Routes whose BlocProviders use one-shot `..add(...)` initializations.
/// These screens are evicted from [_AppShellState._screenCache] and rebuilt
/// on every navigation so their blocs always start with fresh data.
const Set<String> _kNoCacheRoutes = {
  AppRoutes.stock,
  AppRoutes.purchase,
  AppRoutes.units,
};

int? _routeToIndex(String route) {
  final index = _kRoutes.indexOf(route);
  return index >= 0 ? index : null;
}

String _indexToRoute(int index) {
  if (index >= 0 && index < _kRoutes.length) {
    return _kRoutes[index];
  }
  return AppRoutes.home;
}

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

    final index = _routeToIndex(route);
    if (index == null) return;

    state._setIndex(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  final Map<int, Widget> _screenCache = {};

  /// Per-route rebuild generation counter for [_kNoCacheRoutes].
  /// Incrementing a route's count forces [_buildScreen] to produce a widget
  /// with a new [ValueKey], which tells Flutter to dispose the old subtree
  /// (and its BlocProviders/blocs) and mount a completely fresh one.
  final Map<String, int> _refreshCounts = {};

  /// Incremented every time the Home tab (index 0) becomes the active tab.
  /// Passed to [HomeScreen] so it can trigger a data refresh via listener.
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _currentIndex = _routeToIndex(widget.initialRoute) ?? 0;
  }

  @override
  void dispose() {
    _homeRefreshNotifier.dispose();
    super.dispose();
  }

  void _setIndex(int index) {
    if (index == _currentIndex) return;
    final route = _indexToRoute(index);
    if (_kNoCacheRoutes.contains(route)) {
      // Evict the stale cached widget so _buildScreen runs again with a new
      // generation key, causing Flutter to fully dispose the old BlocProvider
      // subtree and create fresh blocs with their one-shot ..add() calls.
      _refreshCounts[route] = (_refreshCounts[route] ?? 0) + 1;
      _screenCache.remove(index);
    }
    setState(() => _currentIndex = index);
    // Notify HomeScreen so it can refresh its dashboard data.
    if (index == (_routeToIndex(AppRoutes.home) ?? 0)) {
      _homeRefreshNotifier.value++;
    }
  }

  String get _currentRoute => _indexToRoute(_currentIndex);

  Widget _getOrCreateScreen(int index, BuildContext context) {
    return _screenCache.putIfAbsent(index, () => _buildScreen(index, context));
  }

  // ── Keyboard shortcuts ──────────────────────────────────────────────────
  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyN, control: true): _NewSaleIntent(),
    SingleActivator(LogicalKeyboardKey.keyB, control: true):
        _ToggleSidebarIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewSaleIntent: CallbackAction<_NewSaleIntent>(onInvoke: (_) {
            final salesIndex = _routeToIndex(AppRoutes.sales);
            if (salesIndex != null) {
              _setIndex(salesIndex);
            }
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
                            _kRoutes.length,
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
  /// For [_kNoCacheRoutes], the returned widget is wrapped in a [KeyedSubtree]
  /// whose key includes the current generation counter; when the counter
  /// increments (in [_setIndex]) Flutter sees a new key and fully tears down
  /// and remounts the subtree, re-running every BlocProvider `create:` callback
  /// and every chained `..add(...)` initialization.
  Widget _buildScreen(int index, BuildContext context) {
    final route = _indexToRoute(index);
    // HomeScreen receives the refresh notifier so it can reload dashboard data
    // whenever the home tab becomes active (e.g. after completing a sale).
    if (route == AppRoutes.home) {
      return HomeScreen(refreshSignal: _homeRefreshNotifier);
    }
    final builder = _kRouteBuilders[route];
    if (builder == null) {
      return const HomeScreen();
    }
    final child = builder(context);
    if (_kNoCacheRoutes.contains(route)) {
      final generation = _refreshCounts[route] ?? 0;
      return KeyedSubtree(
        key: ValueKey('$route-$generation'),
        child: child,
      );
    }
    return child;
  }
}

// ---------------------------------------------------------------------------
// Intent classes (keyboard shortcuts)
// ---------------------------------------------------------------------------

class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}
