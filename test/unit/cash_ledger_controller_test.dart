// test/unit/cash_ledger_controller_test.dart
import 'dart:async';

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
  PaymentMode paymentMode = PaymentMode.cash,
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
    when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: any(named: 'paymentModeFilter'),
        )).thenAnswer((_) async => []);
    when(() => mockRepo.searchCashLedger(
          any(),
          paymentModeFilter: any(named: 'paymentModeFilter'),
        )).thenAnswer((_) async => []);

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

    test('sets hasNextPage false when repository returns fewer than limit',
        () async {
      // Returns 5 entries (less than the internal limit of 20)
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(5, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      expect(controller.hasNextPage, false);
    });

    test('sets hasNextPage true when repository returns full page', () async {
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      expect(controller.hasNextPage, true);
    });

    test('ignores stale stats from an earlier refresh', () async {
      final firstBalance = Completer<Money>();
      var balanceCallCount = 0;

      when(() => mockRepo.getPhysicalCashBalance()).thenAnswer((_) {
        balanceCallCount++;
        if (balanceCallCount == 1) {
          return firstBalance.future;
        }
        return Future.value(Money.fromPaisas(9000));
      });

      final firstRefresh = controller.refresh();
      await Future<void>.delayed(Duration.zero);

      final secondRefresh = controller.refresh();
      await secondRefresh;

      expect(controller.cashInDrawer.paisas, 9000);

      firstBalance.complete(Money.fromPaisas(1000));
      await firstRefresh;

      expect(controller.cashInDrawer.paisas, 9000);
    });

    test('ignores stale transaction data from an earlier refresh', () async {
      final firstEntries = Completer<List<CashLedger>>();
      var ledgerCallCount = 0;

      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer((_) {
        ledgerCallCount++;
        if (ledgerCallCount == 1) {
          return firstEntries.future;
        }
        return Future.value([_makeEntry(id: 99)]);
      });

      final firstRefresh = controller.refresh();
      await Future<void>.delayed(Duration.zero);

      final secondRefresh = controller.refresh();
      await secondRefresh;

      expect(controller.allEntries.map((entry) => entry.id), [99]);
      expect(controller.hasNextPage, false);

      firstEntries.complete(List.generate(20, (i) => _makeEntry(id: i + 1)));
      await firstRefresh;

      expect(controller.allEntries.map((entry) => entry.id), [99]);
      expect(controller.hasNextPage, false);
    });
  });

  // ---------------------------------------------------------------------------
  // _loadStats() – tested indirectly via refresh()
  // ---------------------------------------------------------------------------
  group('Stats computation (_loadStats)', () {
    test('computes totalInflow as sum of all inflow amounts for today',
        () async {
      final today = DateTime.now();
      final entries = [
        _makeEntry(
            id: 1,
            type: 'IN',
            amount: 3000,
            paymentMode: PaymentMode.cash,
            date: today),
        _makeEntry(
            id: 2,
            type: 'IN',
            amount: 2000,
            paymentMode: PaymentMode.bank,
            date: today),
        _makeEntry(
            id: 3,
            type: 'OUT',
            amount: 1000,
            paymentMode: PaymentMode.cash,
            date: today),
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
        _makeEntry(
            id: 1,
            type: 'IN',
            amount: 3000,
            paymentMode: PaymentMode.cash,
            date: today),
        _makeEntry(
            id: 2,
            type: 'IN',
            amount: 2000,
            paymentMode: PaymentMode.bank,
            date: today),
        _makeEntry(
            id: 3,
            type: 'IN',
            amount: 1500,
            paymentMode: PaymentMode.easyPaisa,
            date: today),
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
        _makeEntry(
            id: 1,
            type: 'OUT',
            amount: 5000,
            paymentMode: PaymentMode.cash,
            date: today),
        _makeEntry(
            id: 2,
            type: 'OUT',
            amount: 3000,
            paymentMode: PaymentMode.bank,
            date: today),
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
        _makeEntry(
            id: 1,
            type: 'OPENING',
            amount: 10000,
            paymentMode: PaymentMode.cash,
            date: today),
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
        _makeEntry(id: 1, paymentMode: PaymentMode.cash),
        _makeEntry(id: 2, paymentMode: PaymentMode.bank),
        _makeEntry(id: 3, paymentMode: PaymentMode.easyPaisa),
      ];

      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer((_) async => entries);

      controller.paymentModeFilter = 'ALL';
      await controller.refresh();

      expect(controller.allEntries.length, 3);
    });

    test('CASH filter keeps only CASH entries', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: PaymentMode.cash),
        _makeEntry(id: 2, paymentMode: PaymentMode.bank),
        _makeEntry(id: 3, paymentMode: PaymentMode.cash),
        _makeEntry(id: 4, paymentMode: PaymentMode.easyPaisa),
      ];
      final cashOnly = [entries[0], entries[2]];

      when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: 'CASH')).thenAnswer((_) async => cashOnly);

      controller.paymentModeFilter = 'CASH';
      await controller.refresh();

      expect(controller.allEntries.length, 2);
      expect(controller.allEntries.every((e) => e.paymentMode.isCash), true);
    });

    test('DIGITAL filter keeps only non-CASH entries', () async {
      final entries = [
        _makeEntry(id: 1, paymentMode: PaymentMode.cash),
        _makeEntry(id: 2, paymentMode: PaymentMode.bank),
        _makeEntry(id: 3, paymentMode: PaymentMode.card),
        _makeEntry(id: 4, paymentMode: PaymentMode.cash),
      ];
      final digitalOnly = [entries[1], entries[2]];

      when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: 'DIGITAL')).thenAnswer((_) async => digitalOnly);

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      expect(controller.allEntries.length, 2);
      expect(controller.allEntries.every((e) => !e.paymentMode.isCash), true);
    });

    test('DIGITAL filter with all CASH entries results in empty list',
        () async {
      when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: 'DIGITAL')).thenAnswer((_) async => []);

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      expect(controller.allEntries, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Date filter (updateDate)
  // ---------------------------------------------------------------------------
  group('updateDate()', () {
    test('setting a date triggers refresh and uses getCashLedgerByDateRange',
        () async {
      final entries = [_makeEntry(id: 1)];
      when(() => mockRepo.getCashLedgerByDateRange(any(), any(),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer((_) async => entries);

      controller.updateDate(DateTime(2024, 3, 15));

      // Give async operations time to complete
      await Future.delayed(Duration.zero);

      expect(controller.selectedDate, DateTime(2024, 3, 15));
      verify(() => mockRepo.getCashLedgerByDateRange(any(), any(),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .called(greaterThan(0));
    });

    test(
        'setting date to null clears selectedDate and reverts to paginated view',
        () async {
      controller.selectedDate = DateTime(2024, 3, 15);
      controller.updateDate(null);

      await Future.delayed(Duration.zero);

      expect(controller.selectedDate, isNull);
    });

    test('date filter disables further pagination (hasNextPage = false)',
        () async {
      when(() => mockRepo.getCashLedgerByDateRange(any(), any(),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(50, (i) => _makeEntry(id: i + 1)));

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
    test('non-empty query uses searchCashLedger instead of getCashLedger',
        () async {
      final entries = [_makeEntry(id: 1)];
      when(() => mockRepo.searchCashLedger('sale',
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer((_) async => entries);

      controller.setSearchQuery('sale');
      await Future.delayed(Duration.zero);

      verify(() => mockRepo.searchCashLedger('sale',
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .called(greaterThan(0));
    });

    test('non-empty query sets hasNextPage to false', () async {
      when(() => mockRepo.searchCashLedger(any(),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(50, (i) => _makeEntry(id: i + 1)));

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
            paymentModeFilter: any(named: 'paymentModeFilter'),
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
        _makeEntry(id: 1, paymentMode: PaymentMode.cash),
        _makeEntry(id: 2, paymentMode: PaymentMode.bank),
      ];
      final digitalEntries = [allEntries[1]];

      when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: 'ALL')).thenAnswer((_) async => allEntries);
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: 'DIGITAL'))
          .thenAnswer((_) async => digitalEntries);

      await controller.refresh();
      expect(controller.allEntries.length, 2);

      controller.setPaymentModeFilter('DIGITAL');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.allEntries.every((e) => !e.paymentMode.isCash), true);
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
          paymentModeFilter: any(named: 'paymentModeFilter'),
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
            paymentModeFilter: any(named: 'paymentModeFilter'),
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
      when(() => mockRepo.searchCashLedger(any(),
              paymentModeFilter: any(named: 'paymentModeFilter')))
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
      expect(
          controller.isLoadMoreRunning, true); // Still true, we short-circuited
    });

    test('appends entries from next page and preserves existing entries',
        () async {
      final page0 = List.generate(20, (i) => _makeEntry(id: i + 1));
      final page1 = List.generate(10, (i) => _makeEntry(id: i + 21));

      var callCount = 0;
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
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

    test('sets hasNextPage false when loaded page is less than limit',
        () async {
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(5, (i) => _makeEntry(id: i + 21)));

      await controller.loadMore();

      expect(controller.hasNextPage, false);
    });

    test('sets isLoadMoreRunning back to false after completion', () async {
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();
      await controller.loadMore();

      expect(controller.isLoadMoreRunning, false);
    });

    test('sets isLoadMoreRunning to false even on error', () async {
      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenAnswer(
              (_) async => List.generate(20, (i) => _makeEntry(id: i + 1)));

      await controller.refresh();

      when(() => mockRepo.getCashLedger(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              paymentModeFilter: any(named: 'paymentModeFilter')))
          .thenThrow(Exception('Load more error'));

      await controller.loadMore();

      expect(controller.isLoadMoreRunning, false);
      expect(controller.errorMessage, contains('Load more error'));
    });

    test('applies paymentMode filter to appended entries', () async {
      final filteredPage0 = List.generate(
          20, (i) => _makeEntry(id: i + 1, paymentMode: PaymentMode.bank));
      final filteredPage1 = [
        _makeEntry(id: 21, paymentMode: PaymentMode.bank),
      ];

      var callCount = 0;
      when(() => mockRepo.getCashLedger(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          paymentModeFilter: 'DIGITAL')).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return filteredPage0;
        return filteredPage1;
      });

      controller.paymentModeFilter = 'DIGITAL';
      await controller.refresh();

      expect(controller.allEntries.length, 20);

      await controller.loadMore();

      expect(controller.allEntries.length, 21);
      expect(controller.allEntries.last.id, 21);
    });
  });

  // ---------------------------------------------------------------------------
  // notifyListeners() coverage
  // ---------------------------------------------------------------------------
  group('notifyListeners integration', () {
    test('refresh notifies listeners at least twice (loading then loaded)',
        () async {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.refresh();

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
