import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/cubits/sidebar_cubit.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/theme/app_ui_theme.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/widgets/app_header.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';

void main() {
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      testWidgets('$language $brightness rail resizing preserves user choice',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1008, 681);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = SidebarCubit();
        addTearDown(cubit.close);
        await tester.pumpWidget(BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme:
                AppUiTheme.build('green', brightness, isRTL: language == 'ur'),
            home: const Scaffold(
              body: Row(children: [
                AppNavigationSidebar(currentRoute: AppRoutes.product),
                Expanded(
                    child: Column(children: [
                  AppHeader(currentRoute: AppRoutes.product),
                  Expanded(child: SizedBox()),
                ])),
              ]),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final sidebar = find.byType(AppNavigationSidebar);
        expect(tester.getSize(sidebar).width, 64);
        expect(cubit.isExpanded, isTrue);
        final loc = AppLocalizations.of(tester.element(sidebar))!;
        expect(
            find.widgetWithText(Tooltip, loc.productsAndStock), findsNothing);
        expect(find.byTooltip(loc.productsAndStock), findsOneWidget);
        expect(find.byTooltip(loc.cashLedger), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(1350, 729);
        await tester.pumpAndSettle();
        expect(tester.getSize(sidebar).width, 224);
        expect(find.text(loc.productsAndStock), findsOneWidget);
        cubit.collapse();
        await tester.pumpAndSettle();
        expect(tester.getSize(sidebar).width, 64);
        tester.view.physicalSize = const Size(1008, 681);
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(1350, 729);
        await tester.pumpAndSettle();
        expect(cubit.isExpanded, isFalse);
        expect(tester.getSize(sidebar).width, 64);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
