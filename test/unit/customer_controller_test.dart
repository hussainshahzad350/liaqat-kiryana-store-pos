// test/unit/customer_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/customers/controller/customer_controller.dart';

class MockCustomersRepository extends Mock implements CustomersRepository {}

/// Helper to create a test Customer.
Customer _makeCustomer({
  int id = 1,
  String name = 'Test Customer',
  bool isActive = true,
  int outstandingBalance = 0,
}) {
  return Customer(
    id: id,
    nameEnglish: name,
    outstandingBalance: outstandingBalance,
    isActive: isActive,
  );
}

/// Default stats map returned by mock.
Map<String, dynamic> _defaultStats({
  int countTotal = 5,
  int balTotal = 10000,
  int countActive = 3,
  int balActive = 7000,
  int countArchived = 2,
  int balArchived = 3000,
}) {
  return {
    'countTotal': countTotal,
    'balTotal': balTotal,
    'countActive': countActive,
    'balActive': balActive,
    'countArchived': countArchived,
    'balArchived': balArchived,
  };
}

void main() {
  late MockCustomersRepository mockRepo;
  late CustomerController controller;

  setUpAll(() {
    registerFallbackValue(_makeCustomer());
  });

  setUp(() {
    mockRepo = MockCustomersRepository();

    // Default stubs
    when(() => mockRepo.getCustomerStats()).thenAnswer((_) async => _defaultStats());
    when(() => mockRepo.getActiveCustomers())
        .thenAnswer((_) async => [_makeCustomer(id: 1), _makeCustomer(id: 2)]);
    when(() => mockRepo.getArchivedCustomers()).thenAnswer((_) async => []);
    when(() => mockRepo.searchCustomers(any(), activeOnly: any(named: 'activeOnly')))
        .thenAnswer((_) async => []);

    controller = CustomerController(mockRepo);
  });

  tearDown(() async {
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------
  group('Initial state', () {
    test('starts with isLoading true', () {
      expect(controller.isLoading, true);
    });

    test('starts with empty customer lists', () {
      expect(controller.activeCustomers, isEmpty);
      expect(controller.archivedCustomers, isEmpty);
    });

    test('starts with selectedIndex -1', () {
      expect(controller.selectedIndex, -1);
    });

    test('starts with showArchive false', () {
      expect(controller.showArchive, false);
    });

    test('starts with no ledger customer open', () {
      expect(controller.ledgerCustomer, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // init()
  // ---------------------------------------------------------------------------
  group('init()', () {
    test('sets isLoading=true then calls refresh', () async {
      await controller.init();
      expect(controller.isLoading, false);
      verify(() => mockRepo.getCustomerStats()).called(greaterThan(0));
      verify(() => mockRepo.getActiveCustomers()).called(greaterThan(0));
    });

    test('loads activeCustomers from repository', () async {
      when(() => mockRepo.getActiveCustomers()).thenAnswer((_) async => [
            _makeCustomer(id: 1, name: 'Alice'),
            _makeCustomer(id: 2, name: 'Bob'),
          ]);

      await controller.init();

      expect(controller.activeCustomers.length, 2);
      expect(controller.activeCustomers.first.nameEnglish, 'Alice');
    });

    test('does not load archived customers when showArchive is false', () async {
      await controller.init();
      verifyNever(() => mockRepo.getArchivedCustomers());
    });

    test('loads archived customers when showArchive is true before init', () async {
      controller.showArchive = true;
      when(() => mockRepo.getArchivedCustomers())
          .thenAnswer((_) async => [_makeCustomer(id: 10, isActive: false)]);

      await controller.init();

      verify(() => mockRepo.getArchivedCustomers()).called(greaterThan(0));
      expect(controller.archivedCustomers.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // loadStats()
  // ---------------------------------------------------------------------------
  group('loadStats()', () {
    test('populates all stat fields from repository', () async {
      when(() => mockRepo.getCustomerStats()).thenAnswer((_) async => _defaultStats(
            countTotal: 10,
            balTotal: 50000,
            countActive: 7,
            balActive: 30000,
            countArchived: 3,
            balArchived: 20000,
          ));

      await controller.loadStats();

      expect(controller.countTotal, 10);
      expect(controller.balTotal, 50000);
      expect(controller.countActive, 7);
      expect(controller.balActive, 30000);
      expect(controller.countArchived, 3);
      expect(controller.balArchived, 20000);
    });

    test('handles null values in stats gracefully (defaults to 0)', () async {
      when(() => mockRepo.getCustomerStats()).thenAnswer((_) async => {
            'countTotal': null,
            'balTotal': null,
            'countActive': null,
            'balActive': null,
            'countArchived': null,
            'balArchived': null,
          });

      await controller.loadStats();

      expect(controller.countTotal, 0);
      expect(controller.balTotal, 0);
      expect(controller.countActive, 0);
      expect(controller.balActive, 0);
    });

    test('sets errorMessage on exception', () async {
      when(() => mockRepo.getCustomerStats()).thenThrow(Exception('Stats DB error'));

      await controller.loadStats();

      expect(controller.errorMessage, contains('Stats DB error'));
    });
  });

  // ---------------------------------------------------------------------------
  // loadActiveCustomers()
  // ---------------------------------------------------------------------------
  group('loadActiveCustomers()', () {
    test('with empty query calls getActiveCustomers', () async {
      await controller.loadActiveCustomers(query: '');
      verify(() => mockRepo.getActiveCustomers()).called(1);
      verifyNever(() => mockRepo.searchCustomers(any(), activeOnly: any(named: 'activeOnly')));
    });

    test('with non-empty query calls searchCustomers with activeOnly=true', () async {
      await controller.loadActiveCustomers(query: 'Ali');
      verify(() => mockRepo.searchCustomers('Ali', activeOnly: true)).called(1);
      verifyNever(() => mockRepo.getActiveCustomers());
    });

    test('resets selectedIndex to -1 after loading', () async {
      controller.selectedIndex = 1;
      await controller.loadActiveCustomers();
      expect(controller.selectedIndex, -1);
    });

    test('clears errorMessage on success', () async {
      controller.errorMessage = 'Some previous error';
      await controller.loadActiveCustomers();
      expect(controller.errorMessage, isNull);
    });

    test('sets isLoading=false after loading', () async {
      await controller.loadActiveCustomers();
      expect(controller.isLoading, false);
    });

    test('on error: sets isLoading=false and stores errorMessage', () async {
      when(() => mockRepo.getActiveCustomers()).thenThrow(Exception('Network error'));

      await controller.loadActiveCustomers();

      expect(controller.isLoading, false);
      expect(controller.errorMessage, contains('Network error'));
    });

    test('stale search token prevents stale result from overwriting fresh result', () async {
      // This tests the race condition guard: if _searchToken increments between
      // an async call and its completion, the stale result is discarded.
      // We verify that a concurrent call does not corrupt state.
      var callCount = 0;
      when(() => mockRepo.getActiveCustomers()).thenAnswer((_) async {
        callCount++;
        return [_makeCustomer(id: callCount, name: 'Customer $callCount')];
      });

      // Fire two concurrent loads
      final future1 = controller.loadActiveCustomers();
      final future2 = controller.loadActiveCustomers();
      await Future.wait([future1, future2]);

      // State should reflect the result of the second call
      expect(controller.activeCustomers, isNotEmpty);
      expect(controller.isLoading, false);
    });
  });

  // ---------------------------------------------------------------------------
  // loadArchivedCustomers()
  // ---------------------------------------------------------------------------
  group('loadArchivedCustomers()', () {
    test('populates archivedCustomers', () async {
      when(() => mockRepo.getArchivedCustomers()).thenAnswer((_) async => [
            _makeCustomer(id: 5, name: 'Archived One', isActive: false),
          ]);

      await controller.loadArchivedCustomers();

      expect(controller.archivedCustomers.length, 1);
      expect(controller.archivedCustomers.first.nameEnglish, 'Archived One');
    });

    test('sets isArchivedLoading=false after loading', () async {
      await controller.loadArchivedCustomers();
      expect(controller.isArchivedLoading, false);
    });

    test('on error: sets isArchivedLoading=false and errorMessage', () async {
      when(() => mockRepo.getArchivedCustomers()).thenThrow(Exception('Archive error'));

      await controller.loadArchivedCustomers();

      expect(controller.isArchivedLoading, false);
      expect(controller.errorMessage, contains('Archive error'));
    });
  });

  // ---------------------------------------------------------------------------
  // toggleArchiveView()
  // ---------------------------------------------------------------------------
  group('toggleArchiveView()', () {
    test('flips showArchive from false to true', () {
      expect(controller.showArchive, false);
      controller.toggleArchiveView();
      expect(controller.showArchive, true);
    });

    test('flips showArchive from true to false', () {
      controller.showArchive = true;
      controller.toggleArchiveView();
      expect(controller.showArchive, false);
    });

    test('loads archived customers when toggling to true', () async {
      controller.toggleArchiveView();
      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => mockRepo.getArchivedCustomers()).called(greaterThan(0));
    });

    test('does not load archived customers when toggling to false', () {
      controller.showArchive = true;
      controller.toggleArchiveView();
      // showArchive is now false – getArchivedCustomers should not be called
      verifyNever(() => mockRepo.getArchivedCustomers());
    });
  });

  // ---------------------------------------------------------------------------
  // closeArchiveView()
  // ---------------------------------------------------------------------------
  group('closeArchiveView()', () {
    test('sets showArchive to false', () {
      controller.showArchive = true;
      controller.closeArchiveView();
      expect(controller.showArchive, false);
    });
  });

  // ---------------------------------------------------------------------------
  // toggleArchiveStatus()
  // ---------------------------------------------------------------------------
  group('toggleArchiveStatus()', () {
    setUp(() {
      when(() => mockRepo.updateCustomer(any(), any())).thenAnswer((_) async => 1);
    });

    test('calls updateCustomer with inverted isActive', () async {
      final customer = _makeCustomer(id: 3, isActive: true);
      await controller.toggleArchiveStatus(customer);

      final captured = verify(
        () => mockRepo.updateCustomer(3, captureAny()),
      ).captured.first as Customer;
      expect(captured.isActive, false);
    });

    test('archived customer gets un-archived', () async {
      final customer = _makeCustomer(id: 4, isActive: false);
      await controller.toggleArchiveStatus(customer);

      final captured = verify(
        () => mockRepo.updateCustomer(4, captureAny()),
      ).captured.first as Customer;
      expect(captured.isActive, true);
    });

    test('on error: sets errorMessage', () async {
      when(() => mockRepo.updateCustomer(any(), any())).thenThrow(Exception('Update failed'));
      final customer = _makeCustomer(id: 5);

      await controller.toggleArchiveStatus(customer);

      expect(controller.errorMessage, contains('Update failed'));
    });
  });

  // ---------------------------------------------------------------------------
  // deleteCustomer()
  // ---------------------------------------------------------------------------
  group('deleteCustomer()', () {
    setUp(() {
      when(() => mockRepo.deleteCustomer(any())).thenAnswer((_) async => 1);
    });

    test('returns true on successful deletion', () async {
      final customer = _makeCustomer(id: 7);
      final result = await controller.deleteCustomer(customer);
      expect(result, true);
    });

    test('calls deleteCustomer on repository with correct id', () async {
      final customer = _makeCustomer(id: 9);
      await controller.deleteCustomer(customer);
      verify(() => mockRepo.deleteCustomer(9)).called(1);
    });

    test('returns false on error', () async {
      when(() => mockRepo.deleteCustomer(any())).thenThrow(Exception('Delete failed'));
      final customer = _makeCustomer(id: 8);

      final result = await controller.deleteCustomer(customer);

      expect(result, false);
      expect(controller.errorMessage, contains('Delete failed'));
    });

    test('clears open ledger customer after successful deletion', () async {
      final customer = _makeCustomer(id: 14);
      controller.ledgerCustomer = customer;

      final result = await controller.deleteCustomer(customer);

      expect(result, true);
      expect(controller.ledgerCustomer, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // openLedger() and closeLedger()
  // ---------------------------------------------------------------------------
  group('openLedger() / closeLedger()', () {
    test('openLedger sets ledgerCustomer', () {
      final customer = _makeCustomer(id: 10, name: 'Ledger Customer');
      controller.openLedger(customer);
      expect(controller.ledgerCustomer, customer);
    });

    test('closeLedger clears ledgerCustomer', () {
      controller.ledgerCustomer = _makeCustomer(id: 10);
      controller.closeLedger();
      expect(controller.ledgerCustomer, isNull);
    });

    test('openLedger notifies listeners', () {
      int count = 0;
      controller.addListener(() => count++);

      controller.openLedger(_makeCustomer());

      expect(count, 1);
    });

    test('closeLedger notifies listeners', () {
      int count = 0;
      controller.addListener(() => count++);
      controller.ledgerCustomer = _makeCustomer();

      controller.closeLedger();

      expect(count, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // refreshLedgerCustomer()
  // ---------------------------------------------------------------------------
  group('refreshLedgerCustomer()', () {
    test('does nothing when ledgerCustomer is null', () async {
      controller.ledgerCustomer = null;
      await controller.refreshLedgerCustomer();
      verifyNever(() => mockRepo.getCustomerById(any()));
    });

    test('updates ledgerCustomer with fresh data from repo', () async {
      final original = _makeCustomer(id: 11, outstandingBalance: 0);
      controller.ledgerCustomer = original;

      final updated = _makeCustomer(id: 11, outstandingBalance: 5000);
      when(() => mockRepo.getCustomerById(11)).thenAnswer((_) async => updated);

      await controller.refreshLedgerCustomer();

      expect(controller.ledgerCustomer!.outstandingBalance, 5000);
    });

    test('silently ignores error during background refresh', () async {
      controller.ledgerCustomer = _makeCustomer(id: 12);
      when(() => mockRepo.getCustomerById(any())).thenThrow(Exception('Network error'));

      // Should not throw
      await controller.refreshLedgerCustomer();
    });

    test('clears ledgerCustomer when getCustomerById returns null', () async {
      final original = _makeCustomer(id: 13);
      controller.ledgerCustomer = original;
      when(() => mockRepo.getCustomerById(13)).thenAnswer((_) async => null);

      await controller.refreshLedgerCustomer();

      expect(controller.ledgerCustomer, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // setSelectedIndex()
  // ---------------------------------------------------------------------------
  group('setSelectedIndex()', () {
    setUp(() async {
      when(() => mockRepo.getActiveCustomers()).thenAnswer((_) async => List.generate(
            5, (i) => _makeCustomer(id: i + 1, name: 'Customer ${i + 1}')));
      await controller.loadActiveCustomers();
    });

    test('sets selectedIndex to valid value', () {
      controller.setSelectedIndex(2);
      expect(controller.selectedIndex, 2);
    });

    test('sets selectedIndex to -1 (deselect)', () {
      controller.selectedIndex = 3;
      controller.setSelectedIndex(-1);
      expect(controller.selectedIndex, -1);
    });

    test('ignores out-of-bounds index (too high)', () {
      controller.setSelectedIndex(100);
      expect(controller.selectedIndex, -1); // unchanged from default
    });

    test('ignores index below -1', () {
      controller.selectedIndex = 2;
      controller.setSelectedIndex(-2);
      expect(controller.selectedIndex, 2); // unchanged
    });
  });

  // ---------------------------------------------------------------------------
  // handleKeyboardNavigation()
  // ---------------------------------------------------------------------------
  group('handleKeyboardNavigation()', () {
    setUp(() async {
      when(() => mockRepo.getActiveCustomers()).thenAnswer((_) async => List.generate(
            3, (i) => _makeCustomer(id: i + 1, name: 'Customer ${i + 1}')));
      await controller.loadActiveCustomers();
    });

    test('does nothing when activeCustomers is empty', () {
      controller.activeCustomers = [];
      controller.selectedIndex = -1;
      controller.handleKeyboardNavigation(true);
      expect(controller.selectedIndex, -1);
    });

    test('down: increments selectedIndex from -1 to 0', () {
      controller.selectedIndex = -1;
      controller.handleKeyboardNavigation(true);
      expect(controller.selectedIndex, 0);
    });

    test('down: increments selectedIndex from 0 to 1', () {
      controller.selectedIndex = 0;
      controller.handleKeyboardNavigation(true);
      expect(controller.selectedIndex, 1);
    });

    test('down: does not exceed last item index', () {
      controller.selectedIndex = 2; // last index (3 items, 0-indexed)
      controller.handleKeyboardNavigation(true);
      expect(controller.selectedIndex, 2); // clamped
    });

    test('up: decrements selectedIndex from 2 to 1', () {
      controller.selectedIndex = 2;
      controller.handleKeyboardNavigation(false);
      expect(controller.selectedIndex, 1);
    });

    test('up: from index 0 goes back to -1 (deselected)', () {
      controller.selectedIndex = 0;
      controller.handleKeyboardNavigation(false);
      expect(controller.selectedIndex, -1);
    });

    test('up: does nothing when already at -1', () {
      controller.selectedIndex = -1;
      controller.handleKeyboardNavigation(false);
      expect(controller.selectedIndex, -1);
    });

    test('navigation notifies listeners', () {
      int count = 0;
      controller.addListener(() => count++);
      controller.selectedIndex = 0;
      controller.handleKeyboardNavigation(true);
      expect(count, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // submitSelected()
  // ---------------------------------------------------------------------------
  group('submitSelected()', () {
    setUp(() async {
      when(() => mockRepo.getActiveCustomers()).thenAnswer((_) async => [
            _makeCustomer(id: 1, name: 'First'),
            _makeCustomer(id: 2, name: 'Second'),
          ]);
      await controller.loadActiveCustomers();
    });

    test('opens ledger for selected customer', () {
      controller.selectedIndex = 0;
      controller.submitSelected();
      expect(controller.ledgerCustomer?.nameEnglish, 'First');
    });

    test('does nothing when selectedIndex is -1', () {
      controller.selectedIndex = -1;
      controller.submitSelected();
      expect(controller.ledgerCustomer, isNull);
    });

    test('opens correct customer by index', () {
      controller.selectedIndex = 1;
      controller.submitSelected();
      expect(controller.ledgerCustomer?.nameEnglish, 'Second');
    });
  });

  // ---------------------------------------------------------------------------
  // clearError()
  // ---------------------------------------------------------------------------
  group('clearError()', () {
    test('resets errorMessage to null', () {
      controller.errorMessage = 'Some error';
      controller.clearError();
      expect(controller.errorMessage, isNull);
    });

    test('notifies listeners after clearing error', () {
      int count = 0;
      controller.addListener(() => count++);
      controller.errorMessage = 'Some error';

      controller.clearError();

      expect(count, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // onSearchChanged() – debounce
  // ---------------------------------------------------------------------------
  group('onSearchChanged()', () {
    test('debounces: only one search triggered after rapid changes', () async {
      when(() => mockRepo.searchCustomers(any(), activeOnly: any(named: 'activeOnly')))
          .thenAnswer((_) async => []);
      await controller.loadActiveCustomers(); // prime the active list

      controller.onSearchChanged('A');
      controller.onSearchChanged('Al');
      controller.onSearchChanged('Ali');

      // Wait for debounce duration (300ms) + buffer
      await Future.delayed(const Duration(milliseconds: 400));

      // Only the last query should have been dispatched
      verify(() => mockRepo.searchCustomers('Ali', activeOnly: true)).called(1);
      verifyNever(() => mockRepo.searchCustomers('A', activeOnly: true));
      verifyNever(() => mockRepo.searchCustomers('Al', activeOnly: true));
    });
  });

  // ---------------------------------------------------------------------------
  // Regression: boundary conditions
  // ---------------------------------------------------------------------------
  group('Regression / edge cases', () {
    test('deleteCustomer on customer without id does not crash', () async {
      final customerNoId = Customer(
        nameEnglish: 'No ID',
        isActive: true,
      );
      final result = await controller.deleteCustomer(customerNoId);
      expect(result, false);
      expect(controller.errorMessage, isNotNull);
      verifyNever(() => mockRepo.deleteCustomer(any()));
    });

    test('loadStats handles numeric values returned as double', () async {
      // Repository might return nums that are doubles; verify safe cast
      when(() => mockRepo.getCustomerStats()).thenAnswer((_) async => {
            'countTotal': 4.0,
            'balTotal': 8000.0,
            'countActive': 2.0,
            'balActive': 5000.0,
            'countArchived': 2.0,
            'balArchived': 3000.0,
          });

      await controller.loadStats();

      expect(controller.countTotal, 4);
      expect(controller.balTotal, 8000);
      expect(controller.countActive, 2);
    });
  });
}