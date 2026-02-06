import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/bloc/stock/stock_activity/stock_activity_bloc.dart';
import 'package:liaqat_store/bloc/stock/stock_activity/stock_activity_event.dart';
import 'package:liaqat_store/bloc/stock/stock_activity/stock_activity_state.dart';
import 'package:liaqat_store/core/entity/stock_activity_entity.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/stock_activity_repository.dart';

class _MockStockActivityRepository extends Mock
    implements StockActivityRepository {}

class _MockItemsRepository extends Mock implements ItemsRepository {}

class _MockPurchaseRepository extends Mock implements PurchaseRepository {}

class _MockInvoiceRepository extends Mock implements InvoiceRepository {}

void main() {
  late StockActivityRepository stockActivityRepository;
  late ItemsRepository itemsRepository;
  late PurchaseRepository purchaseRepository;
  late InvoiceRepository invoiceRepository;

  setUp(() {
    stockActivityRepository = _MockStockActivityRepository();
    itemsRepository = _MockItemsRepository();
    purchaseRepository = _MockPurchaseRepository();
    invoiceRepository = _MockInvoiceRepository();

    when(() => stockActivityRepository.getActivities(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => <StockActivityEntity>[]);
  });

  StockActivityBloc buildBloc() => StockActivityBloc(
        stockActivityRepository,
        itemsRepository,
        purchaseRepository,
        invoiceRepository,
      );

  group('Stock Adjustment Success', () {
    blocTest<StockActivityBloc, StockActivityState>(
      'dispatching AdjustStock emits success flow exactly once',
      build: () {
        when(() => itemsRepository.adjustStock(
              any(),
              any(),
              reason: any(named: 'reason'),
              reference: any(named: 'reference'),
            )).thenAnswer((_) async => 1);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        AdjustStock(
          productId: 10,
          quantityChange: 2,
          reason: 'manual',
          reference: 'ref-1',
        ),
      ),
      expect: () => [
        isA<StockActivityActionSuccess>(),
        isA<StockActivityLoading>(),
        isA<StockActivityLoaded>(),
      ],
      verify: (_) {
        verify(() => itemsRepository.adjustStock(
              10,
              2,
              reason: 'manual',
              reference: 'ref-1',
            )).called(1);
      },
    );
  });

  group('Stock Adjustment Failure', () {
    blocTest<StockActivityBloc, StockActivityState>(
      'repository exception emits StockActivityActionError for safe UI handling',
      build: () {
        when(() => itemsRepository.adjustStock(
              any(),
              any(),
              reason: any(named: 'reason'),
              reference: any(named: 'reference'),
            )).thenThrow(Exception('adjust failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        AdjustStock(
          productId: 10,
          quantityChange: -999,
          reason: 'manual',
          reference: 'ref-2',
        ),
      ),
      expect: () => [
        isA<StockActivityActionError>(),
      ],
      verify: (_) {
        verify(() => itemsRepository.adjustStock(
              10,
              -999,
              reason: 'manual',
              reference: 'ref-2',
            )).called(1);
      },
    );
  });
}
