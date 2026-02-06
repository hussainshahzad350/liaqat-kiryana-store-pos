import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/bloc/stock/stock_filter/stock_filter_bloc.dart';
import 'package:liaqat_store/bloc/stock/stock_filter/stock_filter_event.dart';
import 'package:liaqat_store/bloc/stock/stock_filter/stock_filter_state.dart';
import 'package:liaqat_store/core/repositories/categories_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';

class _MockSuppliersRepository extends Mock implements SuppliersRepository {}

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late SuppliersRepository suppliersRepository;
  late CategoriesRepository categoriesRepository;

  setUp(() {
    suppliersRepository = _MockSuppliersRepository();
    categoriesRepository = _MockCategoriesRepository();
  });

  StockFilterBloc buildBloc() =>
      StockFilterBloc(suppliersRepository, categoriesRepository);

  group('Stock Search Debounce', () {
    blocTest<StockFilterBloc, StockFilterState>(
      'latest search input wins; older delayed event does not override newer input',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(SetSearchQuery('r'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(SetSearchQuery('rice'));
      },
      wait: const Duration(milliseconds: 450),
      expect: () => [
        isA<StockFilterState>().having(
          (s) => s.searchQuery,
          'searchQuery',
          'rice',
        ),
      ],
    );
  });
}
