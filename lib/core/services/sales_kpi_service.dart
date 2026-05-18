import '../../domain/entities/money.dart';
import '../../models/invoice_model.dart';
import '../repositories/cash_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/items_repository.dart';

class SalesKpiSnapshot {
  const SalesKpiSnapshot({
    required this.todaySalesTotal,
    required this.lowStockCount,
    required this.latestInvoice,
    required this.cashSnapshot,
    required this.fetchedAt,
  });

  final int todaySalesTotal;
  final int lowStockCount;
  final Invoice? latestInvoice;
  final Money cashSnapshot;
  final DateTime fetchedAt;
}

class SalesKpiService {
  static const Duration defaultCacheTtl = Duration(seconds: 90);

  SalesKpiService({
    required InvoiceRepository invoiceRepository,
    required ItemsRepository itemsRepository,
    required CashRepository cashRepository,
    this.cacheTtl = defaultCacheTtl,
  })  : _invoiceRepository = invoiceRepository,
        _itemsRepository = itemsRepository,
        _cashRepository = cashRepository;

  final InvoiceRepository _invoiceRepository;
  final ItemsRepository _itemsRepository;
  final CashRepository _cashRepository;
  final Duration cacheTtl;

  SalesKpiSnapshot? _cache;
  Future<SalesKpiSnapshot>? _inFlight;

  bool _isCacheValid(DateTime now) {
    if (_cache == null) return false;
    return now.difference(_cache!.fetchedAt) < cacheTtl;
  }

  Future<SalesKpiSnapshot> getSnapshot({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _isCacheValid(now)) {
      return _cache!;
    }
    if (_inFlight != null) return _inFlight!;

    _inFlight = _fetchAndCache();
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  Future<int> getTodaySalesTotal({bool forceRefresh = false}) async {
    final snapshot = await getSnapshot(forceRefresh: forceRefresh);
    return snapshot.todaySalesTotal;
  }

  Future<int> getLowStockCount({bool forceRefresh = false}) async {
    final snapshot = await getSnapshot(forceRefresh: forceRefresh);
    return snapshot.lowStockCount;
  }

  Future<Invoice?> getLatestInvoice({bool forceRefresh = false}) async {
    final snapshot = await getSnapshot(forceRefresh: forceRefresh);
    return snapshot.latestInvoice;
  }

  Future<Money> getCashSnapshot({bool forceRefresh = false}) async {
    final snapshot = await getSnapshot(forceRefresh: forceRefresh);
    return snapshot.cashSnapshot;
  }

  void clearCache() {
    _cache = null;
  }

  Future<SalesKpiSnapshot> _fetchAndCache() async {
    final results = await Future.wait([
      _invoiceRepository.getTodaySalesTotal(),
      _itemsRepository.getLowStockCount(),
      _invoiceRepository.getRecentInvoicesWithCustomer(limit: 1),
      _cashRepository.getCurrentCashBalance(),
    ]);

    final recentInvoices = results[2] as List<Invoice>;
    final snapshot = SalesKpiSnapshot(
      todaySalesTotal: results[0] as int,
      lowStockCount: results[1] as int,
      latestInvoice: recentInvoices.isNotEmpty ? recentInvoices.first : null,
      cashSnapshot: results[3] as Money,
      fetchedAt: DateTime.now(),
    );
    _cache = snapshot;
    return snapshot;
  }
}
