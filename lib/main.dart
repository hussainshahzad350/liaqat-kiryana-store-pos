import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/repositories/settings_repository.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/stock/stock_screen.dart';
import 'screens/items/items_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/suppliers/suppliers_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/units/units_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/cash_ledger/cash_ledger_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/about/about_screen.dart';
import 'core/routes/app_routes.dart';
import 'l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'widgets/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1366, 768),
      minimumSize: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
     );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }
    );
  }
    
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final SettingsRepository settingsRepository = SettingsRepository();
  final initialPrefs = await settingsRepository.getAppPreferences();
  final String languageCode = initialPrefs['languageCode'] ?? 'en';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(settingsRepository),
      child: LiaqatStoreApp(initialLanguage: languageCode),
    ),
  );
}

class LiaqatStoreApp extends StatefulWidget {
  final String initialLanguage;
  const LiaqatStoreApp({super.key, required this.initialLanguage});

  static void setLocale(BuildContext context, Locale newLocale) {
    _LiaqatStoreAppState? state = context.findAncestorStateOfType<_LiaqatStoreAppState>();
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
          theme: themeProvider.themeData.copyWith(
            textTheme: themeProvider.themeData.textTheme.apply(
              fontFamily: _locale.languageCode == 'ur' ? 'NooriNastaleeq' : null,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: themeProvider.themeData.colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: themeProvider.themeData.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: themeProvider.themeData.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: themeProvider.themeData.colorScheme.primary, width: 2),
              ),
              labelStyle: TextStyle(color: themeProvider.themeData.colorScheme.onSurfaceVariant),
              prefixIconColor: themeProvider.themeData.colorScheme.onSurfaceVariant,
              suffixIconColor: themeProvider.themeData.colorScheme.onSurfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: MaterialStateProperty.all(true),
              trackVisibility: MaterialStateProperty.all(true),
              thumbColor: MaterialStateProperty.all(themeProvider.themeData.colorScheme.onSurfaceVariant.withOpacity(0.4)),
              radius: const Radius.circular(10),
              thickness: MaterialStateProperty.all(8),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: themeProvider.themeData.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            cardTheme: CardThemeData(
              color: themeProvider.themeData.colorScheme.surface,
              elevation: 2,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
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
            AppRoutes.home: (context) => const MainLayout(currentRoute: AppRoutes.home, child: HomeScreen()),
            AppRoutes.sales: (context) => const MainLayout(currentRoute: AppRoutes.sales, child: SalesScreen()),
            AppRoutes.stock: (context) => const MainLayout(currentRoute: AppRoutes.stock, child: StockScreen()),
            AppRoutes.items: (context) => const MainLayout(currentRoute: AppRoutes.items, child: ItemsScreen()),
            AppRoutes.customers: (context) => const MainLayout(currentRoute: AppRoutes.customers, child: CustomersScreen()),
            AppRoutes.suppliers: (context) => const MainLayout(currentRoute: AppRoutes.suppliers, child: SuppliersScreen()),
            AppRoutes.categories: (context) => const MainLayout(currentRoute: AppRoutes.categories, child: CategoriesScreen()),
            AppRoutes.units: (context) => const MainLayout(currentRoute: AppRoutes.units, child: UnitsScreen()),
            AppRoutes.reports: (context) => const MainLayout(currentRoute: AppRoutes.reports, child: ReportsScreen()),
            AppRoutes.cashLedger: (context) => const MainLayout(currentRoute: AppRoutes.cashLedger, child: CashLedgerScreen()),
            AppRoutes.settings: (context) => const MainLayout(currentRoute: AppRoutes.settings, child: SettingsScreen()),
            AppRoutes.about: (context) => const MainLayout(currentRoute: AppRoutes.about, child: AboutScreen()),
          },
        );
      },
    );
  }
}