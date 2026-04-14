// test/unit/cash_ledger_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import 'package:liaqat_store/models/cash_ledger_model.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/screens/cash_ledger/controller/cash_ledger_controller.dart';

class MockCashRepository extends Mock implements CashRepository {}

/// Helper to build a CashLedger entry for testing.
CashLedger _makeEntry({
  int id = 1,
  String type = 'IN',
  int amount = 1000,
  String paymentMode = 'CASH',
  DateTime? date,
}) {
  return CashLedger(
    id: id,
    transactionDate: date ?? DateTime(2024, 6, 1),
    transactionTime: '10:00 AM',
    description: 'Test entry $id',
    type: type,
    amount: amount,
    balanceAfter: amount,
    paymentMode: paymentMode,
  );
}

void main() {
  late MockCashRepository mockRepo;
  late CashLedgerController controller;

  setUp(() {
    mockRepo = MockCashRepository();

    // Default stubs used by refresh() -> _loadStats() + _loadTransactions()
    when(() => mockRepo.getPhysicalCashBalance())
        .thenAnswer((_) async => Money.fromPaisas(5000));
    when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
        .thenAnswer((_) async => []);
    when(() => mockRepo.searchCashLedger(any()))
        .thenAnswer((_) async => []);

    controller = CashLedgerController(mockRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------
  group('Initial state', () {
    test('starts in loading state before init()', () {
      expect(controller.state, CashLedgerState.loading);
      expect(controller.allEntries, isEmpty);
      expect(controller.paymentModeFilter, 'ALL');
      expect(controller.searchQuery, '');
      expect(controller.selectedDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // refresh()
  // ---------------------------------------------------------------------------
  group('refresh()', () {
    test('transitions to loaded state on success', () async {
      await controller.refresh();
      expect(controller.state, CashLedgerState.loaded);
    });

    test('calls getPhysicalCashBalance and stores result', () async {
      when(() => mockRepo.getPhysicalCashBalance())
          .thenAnswer((_) async => Money.fromPaisas(9999));

      await controller.refresh();

      expect(controller.cashInDrawer.paisas, 9999);
      verify(() => mockRepo.getPhysicalCashBalance()).called(greaterThan(0));
    });

    test('transitions to error state when repository throws', () async {
      when(() => mockRepo.getPhysicalCashBalance())
          .thenThrow(Exception('DB error'));

      await controller.refresh();

      expect(controller.state, CashLedgerState.error);
      expect(controller.errorMessage, contains('DB error'));
    });

    test('resets allEntries and page on each refresh', () async {
      // Pre-populate entries
      controller.allEntries = [_makeEntry()];

      await controller.refresh();

      // After refresh they are re-loaded (empty in this test scenario)
      expect(controller.allEntries, isEmpty);
    });

    test('sets hasNextPage false when repository returns fewer than limit', () async {
      // Returns 5 entries (less than the internal limit of 20)
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(5, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      expect(controller.hasNextPage, false);
    });

    test('sets hasNextPage true when repository returns full page', () async {
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      expect(controller.hasNextPage, true);
    });
  });

  // ---------------------------------------------------------------------------
  // _loadStats() – tested indirectly via refresh()
  // ---------------------------------------------------------------------------
  group('Stats computation (_loadStats)', () {
    test('computes totalInflow as sum of all inflow amounts for today', () async {
      final today = DateTime.now();
      final entries = [
        _makeEntry(id: 1, type: 'IN', amount: 3000, paymentMode: 'CASH', date: today),
        _makeEntry(id: 2, type: 'IN', amount: 2000, paymentMode: 'BANK', date: today),
        _makeEntry(id: 3, type: 'OUT', amount: 1000, paymentMode: 'CASH', date: today),
      ];

      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => entries);

      await controller.refresh();

      // totalInflow = cash IN + digital IN = 3000 + 2000 = 5000
      expect(controller.totalInflow.paisas, 5000);
    });

    test('computes totalDigitalIn as sum of non-CASH inflow amounts', () async {
      final today = DateTime.now();
      final entries = [
        _makeEntry(id: 1, type: 'IN', amount: 3000, paymentMode: 'CASH', date: today),
        _makeEntry(id: 2, type: 'IN', amount: 2000, paymentMode: 'BANK', date: today),
        _makeEntry(id: 3, type: 'IN', amount: 1500, paymentMode: 'EASYPAISA', date: today),
      ];

      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => entries);

      await controller.refresh();

      // totalDigitalIn = 2000 + 1500 = 3500
      expect(controller.totalDigitalIn.paisas, 3500);
    });

    test('OUT entries do not affect totalInflow', () async {
      final today = DateTime.now();
      final entries = [
        _makeEntry(id: 1, type: 'OUT', amount: 5000, paymentMode: 'CASH', date: today),
        _makeEntry(id: 2, type: 'OUT', amount: 3000, paymentMode: 'BANK', date: today),
      ];

      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => entries);

      await controller.refresh();

      expect(controller.totalInflow.paisas, 0);
      expect(controller.totalDigitalIn.paisas, 0);
    });

    test('OPENING type entries are counted as inflow in stats', () async {
      final today = DateTime.now();
      final entries = [
        _makeEntry(id: 1, type: 'OPENING', amount: 10000, paymentMode: 'CASH', date: today),
      ];

      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => entries);

      await controller.refresh();

      expect(controller.totalInflow.paisas, 10000);
    });
  });

  // ---------------------------------------------------------------------------
  // _applyPaymentModeFilter
  // ---------------------------------------------------------------------------
  group('Payment mode filtering', () {
    test('ALL filter keeps all entries regardless of payment mode', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: 'CASH'),
        _makeEntry(id: 2, paymentMode: 'BANK'),
        _makeEntry(id: 3, paymentMode: 'EASYPAISA'),
      ];

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => entries);

      controller.paymentModeFilter = 'ALL';
      await controller.refresh();

      expect(controller.allEntries.length, 3);
    });

    test('CASH filter keeps only CASH entries', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: 'CASH'),
        _makeEntry(id: 2, paymentMode: 'BANK'),
        _makeEntry(id: 3, paymentMode: 'CASH'),
        _makeEntry(id: 4, paymentMode: 'EASYPAISA'),
      ];

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => entries);

      controller.paymentModeFilter = 'CASH';
      await controller.refresh();

      expect(controller.allEntries.length, 2);
      expect(controller.allEntries.every((e) => e.paymentMode == 'CASH'), true);
    });

    test('DIGITAL filter keeps only non-CASH entries', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: 'CASH'),
        _makeEntry(id: 2, paymentMode: 'BANK'),
        _makeEntry(id: 3, paymentMode: 'CARD'),
        _makeEntry(id: 4, paymentMode: 'CASH'),
      ];

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => entries);

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      expect(controller.allEntries.length, 2);
      expect(controller.allEntries.every((e) => e.paymentMode != 'CASH'), true);
    });

    test('DIGITAL filter with all CASH entries results in empty list', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: 'CASH'),
        _makeEntry(id: 2, paymentMode: 'CASH'),
      ];

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => entries);

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      expect(controller.allEntries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Date filter (updateDate)
  // ---------------------------------------------------------------------------
  group('updateDate()', () {
    test('setting a date triggers refresh and uses getCashLedgerByDateRange', () async {
      final entries = [_makeEntry(id: 1)];
      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => entries);

      controller.updateDate(DateTime(2024, 3, 15));

      // Give async operations time to complete
      await Future.delayed(Duration.zero);

      expect(controller.selectedDate, DateTime(2024, 3, 15));
      verify(() => mockRepo.getCashLedgerByDateRange(any(), any())).called(greaterThan(0));
    });

    test('setting date to null clears selectedDate and reverts to paginated view', () async {
      controller.selectedDate = DateTime(2024, 3, 15);
      controller.updateDate(null);

      await Future.delayed(Duration.zero);

      expect(controller.selectedDate, isNull);
    });

    test('date filter disables further pagination (hasNextPage = false)', () async {
      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => List.generate(50, (i) => _makeEntry(id: i + 1)));

      await controller.init();
      controller.updateDate(DateTime(2024, 6, 1));
      await Future.delayed(Duration.zero);
      // Wait for the refresh triggered by updateDate
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.hasNextPage, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Search filter (setSearchQuery)
  // ---------------------------------------------------------------------------
  group('setSearchQuery()', () {
    test('non-empty query uses searchCashLedger instead of getCashLedger', () async {
      final entries = [_makeEntry(id: 1)];
      when(() => mockRepo.searchCashLedger('sale'))
          .thenAnswer((_) async => entries);

      controller.setSearchQuery('sale');
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.searchCashLedger('sale')).called(greaterThan(0));
    });

    test('non-empty query sets hasNextPage to false', () async {
      when(() => mockRepo.searchCashLedger(any()))
          .thenAnswer((_) async => List.generate(50, (i) => _makeEntry(id: i + 1)));

      await controller.init();
      controller.setSearchQuery('some query');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.hasNextPage, false);
    });

    test('empty query reverts to paginated getCashLedger', () async {
      controller.setSearchQuery('');
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.getCashLedger(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).called(greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // setPaymentModeFilter()
  // ---------------------------------------------------------------------------
  group('setPaymentModeFilter()', () {
    test('updates paymentModeFilter and triggers refresh', () async {
      await controller.init();
      controller.setPaymentModeFilter('CASH');
      await Future.delayed(Duration.zero);

      expect(controller.paymentModeFilter, 'CASH');
    });

    test('switching from ALL to DIGITAL removes CASH entries', () async {
      final allEntries = [
        _makeEntry(id: 1, paymentMode: 'CASH'),
        _makeEntry(id: 2, paymentMode: 'BANK'),
      ];

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => allEntries);

      await controller.refresh();
      expect(controller.allEntries.length, 2);

      controller.setPaymentModeFilter('DIGITAL');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.allEntries.every((e) => e.paymentMode != 'CASH'), true);
    });
  });

  // ---------------------------------------------------------------------------
  // loadMore()
  // ---------------------------------------------------------------------------
  group('loadMore()', () {
    test('does nothing when hasNextPage is false', () async {
      await controller.refresh();
      controller.hasNextPage = false;

      await controller.loadMore();

      // getCashLedger should not be called again beyond the initial load
      final callsBeforeLoadMore = verify(
        () => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).callCount;
      // Just verify no crash and state unchanged
      expect(controller.state, CashLedgerState.loaded);
      expect(callsBeforeLoadMore, greaterThanOrEqualTo(1));
    });

    test('does nothing when state is not loaded', () async {
      // Don't call refresh – controller is still in loading state
      expect(controller.state, CashLedgerState.loading);

      await controller.loadMore();

      verifyNever(() => mockRepo.getCashLedger(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ));
    });

    test('does nothing when selectedDate is set', () async {
      when(() => mockRepo.getCashLedgerByDateRange(any(), any()))
          .thenAnswer((_) async => [_makeEntry()]);

      await controller.init();
      controller.selectedDate = DateTime(2024, 1, 1);
      final entriesBeforeLoadMore = controller.allEntries.length;

      await controller.loadMore();

      expect(controller.allEntries.length, entriesBeforeLoadMore);
    });

    test('does nothing when searchQuery is non-empty', () async {
      when(() => mockRepo.searchCashLedger(any()))
          .thenAnswer((_) async => [_makeEntry()]);

      controller.searchQuery = 'test';
      await controller.refresh();
      final entriesBeforeLoadMore = controller.allEntries.length;

      await controller.loadMore();

      expect(controller.allEntries.length, entriesBeforeLoadMore);
    });

    test('does nothing when isLoadMoreRunning is true', () async {
      await controller.refresh();
      controller.isLoadMoreRunning = true;

      await controller.loadMore();

      // No additional calls beyond the initial refresh
      expect(controller.isLoadMoreRunning, true); // Still true, we short-circuited
    });

    test('appends entries from next page and preserves existing entries', () async {
      final page0 = List.generate(20, (i) => _makeEntry(id: i + 1));
      final page1 = List.generate(10, (i) => _makeEntry(id: i + 21));

      var callCount = 0;
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return page0;
        return page1;
      });

      await controller.refresh();
      expect(controller.allEntries.length, 20);
      expect(controller.hasNextPage, true);

      await controller.loadMore();

      expect(controller.allEntries.length, 30);
      expect(controller.hasNextPage, false); // page1 has 10 < 20
    });

    test('sets hasNextPage false when loaded page is less than limit', () async {
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(5, (i) => _makeEntry(id: i + 21)));

      await controller.loadMore();

      expect(controller.hasNextPage, false);
    });

    test('sets isLoadMoreRunning back to false after completion', () async {
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();
      await controller.loadMore();

      expect(controller.isLoadMoreRunning, false);
    });

    test('sets isLoadMoreRunning to false even on error', () async {
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenThrow(Exception('Load more error'));

      await controller.loadMore();

      expect(controller.isLoadMoreRunning, false);
      expect(controller.errorMessage, contains('Load more error'));
    });

    test('applies paymentMode filter to appended entries', () async {
      final page0 = List.generate(20, (i) => _makeEntry(id: i + 1, paymentMode: 'CASH'));
      final page1 = [
        _makeEntry(id: 21, paymentMode: 'BANK'),
        _makeEntry(id: 22, paymentMode: 'CASH'),
      ];

      var callCount = 0;
      when(() => mockRepo.getCashLedger(limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return page0;
        return page1;
      });

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      // page0 all CASH, DIGITAL filter => 0 entries
      expect(controller.allEntries, isEmpty);

      await controller.loadMore();

      // From page1, only id=21 (BANK) passes filter
      expect(controller.allEntries.length, 1);
      expect(controller.allEntries.first.id, 21);
    });
  });

  // ---------------------------------------------------------------------------
  // notifyListeners() coverage
  // ---------------------------------------------------------------------------
  group('notifyListeners integration', () {
    test('refresh notifies listeners at least twice (loading then loaded)', () async {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.refresh();

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}