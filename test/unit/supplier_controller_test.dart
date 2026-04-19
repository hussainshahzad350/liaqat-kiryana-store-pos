import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/models/supplier_model.dart';
import 'package:liaqat_store/screens/suppliers/controller/supplier_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockSuppliersRepository extends Mock implements SuppliersRepository {}

Supplier _makeSupplier({
  int id = 1,
  String name = 'Test Supplier',
  bool isActive = true,
  int outstandingBalance = 0,
}) {
  return Supplier(
    id: id,
    nameEnglish: name,
    isActive: isActive,
    outstandingBalance: outstandingBalance,
  );
}

Map<String, dynamic> _supplierMap({
  int id = 1,
  String name = 'Test Supplier',
  bool isActive = true,
  int outstandingBalance = 0,
}) {
  return {
    'id': id,
    'name_english': name,
    'is_active': isActive ? 1 : 0,
    'outstanding_balance': outstandingBalance,
  };
}

Map<String, dynamic> _defaultStats() {
  return {
    'countTotal': 5,
    'balTotal': 10000,
    'countActive': 3,
    'balActive': 7000,
    'countArchived': 2,
    'balArchived': 3000,
  };
}

void main() {
  late MockSuppliersRepository mockRepo;
  late SupplierController controller;

  setUp(() {
    mockRepo = MockSuppliersRepository();

    when(() => mockRepo.getSupplierStats())
        .thenAnswer((_) async => _defaultStats());
    when(() => mockRepo.getActiveSuppliers())
        .thenAnswer((_) async => [_supplierMap(id: 1), _supplierMap(id: 2)]);
    when(() => mockRepo.searchSuppliers(any())).thenAnswer((_) async => []);
    when(() => mockRepo.getInactiveSuppliers()).thenAnswer((_) async => []);

    controller = SupplierController(mockRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('deleteSupplier()', () {
    test('clears open ledger supplier after successful deletion', () async {
      final supplier = _makeSupplier(id: 11);
      controller.ledgerSupplier = supplier;
      when(() => mockRepo.deleteSupplier(11)).thenAnswer((_) async => 1);

      final result = await controller.deleteSupplier(supplier);

      expect(result, true);
      expect(controller.ledgerSupplier, isNull);
    });
  });

  group('refreshLedgerSupplier()', () {
    test('clears ledgerSupplier when getSupplierById returns null', () async {
      controller.ledgerSupplier = _makeSupplier(id: 12);
      when(() => mockRepo.getSupplierById(12)).thenAnswer((_) async => null);

      await controller.refreshLedgerSupplier();

      expect(controller.ledgerSupplier, isNull);
    });

    test('updates ledgerSupplier when getSupplierById returns data', () async {
      controller.ledgerSupplier =
          _makeSupplier(id: 13, outstandingBalance: 100);
      when(() => mockRepo.getSupplierById(13)).thenAnswer(
          (_) async => _supplierMap(id: 13, outstandingBalance: 4500));

      await controller.refreshLedgerSupplier();

      expect(controller.ledgerSupplier, isNotNull);
      expect(controller.ledgerSupplier!.outstandingBalance, 4500);
    });
  });
}
