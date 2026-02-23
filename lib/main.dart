import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'bloc/purchase/purchase_bloc.dart';
import 'bloc/purchase/purchase_event.dart';
import 'bloc/sales/sales_bloc.dart';
import 'bloc/stock/stock_activity/stock_activity_bloc.dart';
import 'bloc/stock/stock_activity/stock_activity_event.dart';
import 'bloc/stock/stock_bloc.dart';
import 'bloc/stock/stock_filter/stock_filter_bloc.dart';
import 'bloc/stock/stock_filter/stock_filter_event.dart';
import 'bloc/stock/stock_overview/stock_overview_bloc.dart';
import 'bloc/stock/stock_overview/stock_overview_event.dart';
import 'bloc/units/units_bloc.dart';
import 'bloc/units/units_event.dart';
import 'core/providers/sidebar_provider.dart';
import 'core/repositories/categories_repository.dart';
import 'core/repositories/customers_repository.dart';
import 'core/repositories/invoice_repository.dart';
import 'core/repositories/items_repository.dart';
import 'core/repositories/purchase_repository.dart';
import 'core/repositories/receipt_repository.dart';
import 'core/repositories/settings_repository.dart';
import 'core/repositories/stock_activity_repository.dart';
import 'core/repositories/stock_repository.dart';
import 'core/repositories/suppliers_repository.dart';
import 'core/repositories/units_repository.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/cash_ledger/cash_ledger_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/items/items_screen.dart';
import 'screens/purchase/purchase_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/stock/stock_screen.dart';
import 'screens/suppliers/suppliers_screen.dart';
import 'screens/units/units_screen.dart';
import 'widgets/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1366, 768),
      minimumSize: Size(1024, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final SettingsRepository settingsRepository = SettingsRepository();
  final initialPrefs = await settingsRepository.getAppPreferences();
  final String languageCode = initialPrefs['languageCode'] ?? 'en';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(settingsRepository)),
        RepositoryProvider(create: (context) => settingsRepository),
        RepositoryProvider(create: (context) => ItemsRepository()),
        RepositoryProvider(create: (context) => CustomersRepository()),
        RepositoryProvider(create: (context) => InvoiceRepository()),
        RepositoryProvider(create: (context) => ReceiptRepository()),
        RepositoryProvider(create: (context) => UnitsRepository()),
        RepositoryProvider(create: (context) => StockRepository()),
        RepositoryProvider(create: (context) => StockActivityRepository()),
        RepositoryProvider(create: (context) => PurchaseRepository()),
        RepositoryProvider(create: (context) => SuppliersRepository()),
        RepositoryProvider(create: (context) => CategoriesRepository()),
        BlocProvider(
          create: (context) => StockBloc(
            itemsRepository: context.read<ItemsRepository>(),
          ),
        ),
      ],
      child: LiaqatStoreApp(initialLanguage: languageCode),
    ),
  );
}

class LiaqatStoreApp extends StatefulWidget {
  final String initialLanguage;
  const LiaqatStoreApp({super.key, required this.initialLanguage});

  static void setLocale(BuildContext context, Locale newLocale) {
    _LiaqatStoreAppState? state =
        context.findAncestorStateOfType<_LiaqatStoreAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<LiaqatStoreApp> createState() => _LiaqatStoreAppState();
}

class _LiaqatStoreAppState extends State<LiaqatStoreApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLanguage);
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    
    // Sync theme with language change
    if (mounted) {
      context.read<ThemeProvider>().setTextDirection(
        isRTL: locale.languageCode == 'ur',
      );
    }
    
    final repo = SettingsRepository();
    await repo.updateAppPreferences({'languageCode': locale.languageCode});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Liaqat Kiryana Store',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: _locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ur', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            AppRoutes.home: (context) => const MainLayout(
                currentRoute: AppRoutes.home, child: HomeScreen()),
            AppRoutes.sales: (context) => MainLayout(
                  currentRoute: AppRoutes.sales,
                  child: BlocProvider(
                    create: (context) => SalesBloc(
                      invoiceRepository: context.read<InvoiceRepository>(),
                      itemsRepository: context.read<ItemsRepository>(),
                      customersRepository: context.read<CustomersRepository>(),
                      settingsRepository: context.read<SettingsRepository>(),
                      receiptRepository: context.read<ReceiptRepository>(),
                      stockBloc: context.read<StockBloc>(), // Injected here
                    ),
                    child: const SalesScreen(),
                  ),
                ),
            AppRoutes.stock: (context) => MainLayout(
                  currentRoute: AppRoutes.stock,
                  child: MultiBlocProvider(
                    providers: [
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
                        )..add(LoadStockActivities()),
                      ),
                    ],
                    child: const StockScreen(),
                  ),
                ),
            AppRoutes.purchase: (context) => MainLayout(
                  currentRoute: AppRoutes.stock,
                  child: BlocProvider(
                    create: (context) => PurchaseBloc(
                      purchaseRepository: context.read<PurchaseRepository>(),
                      suppliersRepository: context.read<SuppliersRepository>(),
                      itemsRepository: context.read<ItemsRepository>(),
                    )..add(InitializePurchase()),
                    child: const PurchaseScreen(),
                  ),
                ),
            AppRoutes.items: (context) => const MainLayout(
                currentRoute: AppRoutes.items, child: ItemsScreen()),
            AppRoutes.customers: (context) => const MainLayout(
                currentRoute: AppRoutes.customers, child: CustomersScreen()),
            AppRoutes.suppliers: (context) => const MainLayout(
                currentRoute: AppRoutes.suppliers, child: SuppliersScreen()),
            AppRoutes.categories: (context) => const MainLayout(
                currentRoute: AppRoutes.categories, child: CategoriesScreen()),
            AppRoutes.units: (context) => MainLayout(
                  currentRoute: AppRoutes.units,
                  child: BlocProvider(
                    create: (context) =>
                        UnitsBloc(context.read<UnitsRepository>())
                          ..add(LoadUnits()),
                    child: const UnitsScreen(),
                  ),
                ),
            AppRoutes.reports: (context) => const MainLayout(
                currentRoute: AppRoutes.reports, child: ReportsScreen()),
            AppRoutes.cashLedger: (context) => const MainLayout(
                currentRoute: AppRoutes.cashLedger, child: CashLedgerScreen()),
            AppRoutes.settings: (context) => const MainLayout(
                currentRoute: AppRoutes.settings, child: SettingsScreen()),
            AppRoutes.about: (context) => const MainLayout(
                currentRoute: AppRoutes.about, child: AboutScreen()),
          },
        );
      },
    );
  }
}
