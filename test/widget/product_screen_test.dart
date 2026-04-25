import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/cubits/sidebar_cubit.dart';
import 'package:liaqat_store/core/repositories/categories_repository.dart';
import 'package:liaqat_store/core/repositories/units_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/product/product_screen.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _buildLocalizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Product screen tab routing', () {
    void setDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('opens the requested initial tab index', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CategoriesRepository>(
              create: (_) => CategoriesRepository(),
            ),
            RepositoryProvider<UnitsRepository>(
              create: (_) => UnitsRepository(),
            ),
          ],
          child: _buildLocalizedApp(const ProductScreen(initialTabIndex: 2)),
        ),
      );
      await tester.pump();

      final tabBarElement = tester.element(find.byType(TabBar));
      final tabController = DefaultTabController.of(tabBarElement);
      expect(tabController.index, 2);
    });

    testWidgets('legacy /units route opens Product with units tab',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CategoriesRepository>(
              create: (_) => CategoriesRepository(),
            ),
            RepositoryProvider<UnitsRepository>(
              create: (_) => UnitsRepository(),
            ),
          ],
          child: BlocProvider(
            create: (_) => SidebarCubit(),
            child: _buildLocalizedApp(const AppShell(initialRoute: '/units')),
          ),
        ),
      );
      await tester.pump();

      final tabBarElement = tester.element(find.byType(TabBar));
      final tabController = DefaultTabController.of(tabBarElement);
      expect(tabController.index, 2);
    });
  });
}
