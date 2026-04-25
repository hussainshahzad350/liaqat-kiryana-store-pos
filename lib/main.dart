import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'core/cubits/sidebar_cubit.dart';
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
import 'screens/auth/login_screen.dart';
import 'widgets/app_shell.dart';

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
        BlocProvider(create: (_) => SidebarCubit()),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(settingsRepository)),
        RepositoryProvider(create: (context) => settingsRepository),
        RepositoryProvider(create: (context) => ItemsRepository()),
        RepositoryProvider(create: (context) => CustomersRepository()),
        RepositoryProvider(
            create: (context) =>
                InvoiceRepository(context.read<ItemsRepository>())),
        RepositoryProvider(create: (context) => ReceiptRepository()),
        RepositoryProvider(create: (context) => UnitsRepository()),
        RepositoryProvider(create: (context) => StockRepository()),
        RepositoryProvider(create: (context) => StockActivityRepository()),
        RepositoryProvider(
            create: (context) =>
                PurchaseRepository(context.read<ItemsRepository>())),
        RepositoryProvider(create: (context) => SuppliersRepository()),
        RepositoryProvider(create: (context) => CategoriesRepository()),
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
            // Single post-login shell route — feature navigation happens
            // inside AppShell so sidebar/header/blocs stay alive.
            AppRoutes.home: (context) => const AppShell(
                  initialRoute: AppRoutes.home,
                ),
            AppRoutes.logout: (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
