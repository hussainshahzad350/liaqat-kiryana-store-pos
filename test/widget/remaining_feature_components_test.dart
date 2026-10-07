import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/bloc/units/units_bloc.dart';
import 'package:liaqat_store/bloc/units/units_event.dart';
import 'package:liaqat_store/bloc/units/units_state.dart';
import 'package:liaqat_store/core/theme/app_ui_theme.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/screens/items/widgets/items_table.dart';
import 'package:liaqat_store/screens/units/units_screen.dart';
import 'package:liaqat_store/widgets/app_state_view.dart';
import 'package:mocktail/mocktail.dart';

class _UnitsBloc extends MockBloc<UnitsEvent, UnitsState>
    implements UnitsBloc {}

Widget app(Widget child, String language, Brightness brightness) => MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppUiTheme.build('green', brightness, isRTL: language == 'ur'),
    home: Scaffold(body: child));

void main() {
  setUpAll(() => registerFallbackValue(LoadUnits()));
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'catalog $language $brightness errors, paging and readable rows',
          (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        var retries = 0;
        Widget table(List<Product> items) => ItemsTable(
            items: items,
            categoryNames: const {},
            subCategoryNames: const {},
            scrollController: scroll,
            isInitialLoading: false,
            isLoadingMore: false,
            hasNextPage: true,
            onEditItem: (_) {},
            onDeleteItem: (_) {},
            errorMessage: 'catalog error',
            onRetry: () => retries++);
        await tester.pumpWidget(app(table([]), language, brightness));
        await tester.pumpAndSettle();
        final loc =
            AppLocalizations.of(tester.element(find.byType(ItemsTable)))!;
        expect(find.byType(AppStateView), findsOneWidget);
        await tester.tap(find.text(loc.retry));
        expect(retries, 1);
        await tester.pumpWidget(app(
            table([
              Product(id: 1, nameEnglish: 'Rice', nameUrdu: 'لمبے نام والی چیز')
            ]),
            language,
            brightness));
        await tester.pumpAndSettle();
        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text('Rice'), findsOneWidget);
        await tester.tap(find.text(loc.retry));
        expect(retries, 2);
        expect(
            tester.widget<DataTable>(find.byType(DataTable)).dataRowMaxHeight,
            double.infinity);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('units $language $brightness error can reload',
          (tester) async {
        tester.view.physicalSize = const Size(720, 550);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bloc = _UnitsBloc();
        whenListen(bloc, const Stream<UnitsState>.empty(),
            initialState: const UnitsError('fixture error'));
        await tester.pumpWidget(app(
            BlocProvider<UnitsBloc>.value(
                value: bloc, child: const UnitsScreen()),
            language,
            brightness));
        await tester.pumpAndSettle();
        final loc =
            AppLocalizations.of(tester.element(find.byType(UnitsScreen)))!;
        await tester.tap(find.text(loc.retry));
        verify(() => bloc.add(any(that: isA<LoadUnits>()))).called(1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
