// lib/screens/master_data/suppliers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/supplier_model.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; // Keep for PdfColor
import '../../services/ledger_export_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SuppliersRepository _repository = SuppliersRepository();
  // Pagination State
  List<Supplier> suppliers = [];
  List<Supplier> archivedSuppliers = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;
  
  // Stats
  int countTotal = 0; int balTotal = 0;
  int countActive = 0; int balActive = 0;
  int countArchived = 0; int balArchived = 0;

  // Ledger State
  bool _showArchiveOverlay = false;
  List<Map<String, dynamic>> _currentLedger = [];
  Supplier? _selectedSupplierForLedger;
  final Map<int, List<Map<String, dynamic>>> _billItemsCache = {};
  int? _expandedRowIndex;
  bool _isLedgerLoading = false;
  
  // Ledger Filters
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;
  String _ledgerFilterType = 'ALL'; // ALL, BILL, PAYMENT
  String _ledgerSearchQuery = '';
  final TextEditingController _ledgerSearchCtrl = TextEditingController();

  late ScrollController _scrollController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _firstLoad();
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    _ledgerSearchCtrl.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _hasNextPage) {
      _loadMore();
    }
  }

  // --- Data Loading ---

  Future<void> _loadStats() async {
    try {
      final stats = await _repository.getSupplierStats();
      if (mounted) {
        setState(() {
          countTotal = (stats['countTotal'] as num?)?.toInt() ?? 0;
          balTotal = (stats['balTotal'] as num?)?.toInt() ?? 0;
          countActive = (stats['countActive'] as num?)?.toInt() ?? 0;
          balActive = (stats['balActive'] as num?)?.toInt() ?? 0;
          countArchived = (stats['countArchived'] as num?)?.toInt() ?? 0;
          balArchived = (stats['balArchived'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 0;
      _hasNextPage = true;
      suppliers = [];
    });

    try {
      final query = searchController.text.trim();
      final result = await _repository.getSuppliersPaged(
        limit: _limit,
        offset: 0,
        query: query.isNotEmpty ? query : null,
      );

      if (!mounted) return;
      setState(() {
        suppliers = result;
        _isFirstLoadRunning = false;
        if (result.length < _limit) _hasNextPage = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isFirstLoadRunning = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;
    setState(() => _isLoadMoreRunning = true);

    try {
      final query = searchController.text.trim();
      _page++;
      final offset = _page * _limit;

      final result = await _repository.getSuppliersPaged(
        limit: _limit,
        offset: offset,
        query: query.isNotEmpty ? query : null,
      );

      if (!mounted) return;
      setState(() {
        if (result.isNotEmpty) {
          suppliers.addAll(result);
        } else {
          _hasNextPage = false;
        }
        if (result.length < _limit) _hasNextPage = false;
        _isLoadMoreRunning = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadMoreRunning = false);
    }
  }

  Future<void> _loadArchivedSuppliers() async {
    try {
      final result = await _repository.getInactiveSuppliers();
      if (mounted) {
        setState(() {
          archivedSuppliers = result.map((e) => Supplier.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading archived suppliers: $e');
    }
  }

  Future<void> _refreshList() async {
    await _firstLoad();
    await _loadStats();
    if (_showArchiveOverlay) await _loadArchivedSuppliers();
  }

  // --- Ledger Logic ---

  Future<void> _openLedger(Supplier supplier) async {
    setState(() {
      _selectedSupplierForLedger = supplier;
      _currentLedger = [];
      _billItemsCache.clear();
      _expandedRowIndex = null;
      _isLedgerLoading = true;
      // Reset filters
      _ledgerStartDate = null;
      _ledgerEndDate = null;
      _ledgerFilterType = 'ALL';
      _ledgerSearchQuery = '';
      _ledgerSearchCtrl.clear();
    });

    await _getSupplierLedger(supplier.id!);
    if (mounted) setState(() => _isLedgerLoading = false);
  }

  Future<void> _getSupplierLedger(int supplierId) async {
    try {
      final ledger = await _repository.getSupplierLedger(
        supplierId,
        startDate: _ledgerStartDate,
        endDate: _ledgerEndDate,
      );
      if (mounted) {
        setState(() {
          _currentLedger = ledger;
        });
      }
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }
  }

  List<Map<String, dynamic>> get _filteredLedgerRows {
    return _currentLedger.where((row) {
      // 1. Type Filter
      if (_ledgerFilterType == 'BILL' && row['type'] != 'BILL') return false;
      if (_ledgerFilterType == 'PAYMENT' && row['type'] != 'PAYMENT') return false;

      // 2. Search Filter
      if (_ledgerSearchQuery.isNotEmpty) {
        final q = _ledgerSearchQuery.toLowerCase();
        final desc = (row['desc'] ?? '').toString().toLowerCase();
        return desc.contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _fetchBillItems(int billId) async {
    if (_billItemsCache.containsKey(billId)) return;

    try {
      final items = await _repository.getBillItems(billId);
      if (mounted) {
        setState(() => _billItemsCache[billId] = items);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _billItemsCache[billId] = []);
      }
    }
  }

  Future<void> _addPayment(int supplierId, int amount, String notes) async {
    try {
      await _repository.addPayment(supplierId, amount, notes);
    } catch (e) {
      debugPrint('Error adding payment: $e');
    }
    await _refreshList();
    if (_selectedSupplierForLedger != null) {
      await _getSupplierLedger(supplierId);
    }
  }

  Future<void> _handleExport(AppLocalizations loc) async {
    if (_selectedSupplierForLedger == null) return;
    
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Print / PDF'),
              onTap: () async {
                Navigator.pop(context);
                final service = LedgerExportService();
                await service.exportSupplierLedgerToPdf(
                  _currentLedger, 
                  _selectedSupplierForLedger!, 
                  isUrdu: isUrdu,
                  headerColor: PdfColor.fromInt(colorScheme.primary.value),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export to Excel (CSV)'),
              onTap: () async {
                Navigator.pop(context);
                final service = LedgerExportService();
                final path = await service.exportSupplierLedgerToCsv(_currentLedger, _selectedSupplierForLedger!);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $path')));
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CRUD Operations ---

  Future<void> _addSupplier(String nameEng, String nameUrdu, String phone, String address, String type, int balance) async {
    final loc = AppLocalizations.of(context)!;
    if (nameEng.isEmpty) return;

    try {
      // Check phone uniqueness
      if (phone.isNotEmpty) {
        final exists = await _repository.supplierContactExists(phone);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.phoneExistsError), backgroundColor: Theme.of(context).colorScheme.error));
          return;
        }
      }

      await _repository.addSupplier({
        'name_english': nameEng,
        'name_urdu': nameUrdu,
        'contact_primary': phone,
        'address': address,
        'supplier_type': type,
        'outstanding_balance': balance,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _refreshList(); // Reload list to show new item
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierAdded), backgroundColor: Theme.of(context).colorScheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _updateSupplier(int id, String nameEng, String nameUrdu, String phone, String address, String type, int balance) async {
    final loc = AppLocalizations.of(context)!;
    try {
      // Check phone uniqueness
      if (phone.isNotEmpty) {
        final exists = await _repository.supplierContactExists(phone, excludeId: id);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.phoneExistsError), backgroundColor: Theme.of(context).colorScheme.error));
          return;
        }
      }

      await _repository.updateSupplier(id, {
        'name_english': nameEng,
        'name_urdu': nameUrdu,
        'contact_primary': phone,
        'address': address,
        'supplier_type': type,
        'outstanding_balance': balance,
      });

      if (!mounted) return;
      Navigator.pop(context);
      _refreshList(); // Reload list
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierUpdated), backgroundColor: Theme.of(context).colorScheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _deleteSupplier(int id, int balance) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (balance != 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(loc.warning, style: TextStyle(color: colorScheme.onSurface)),
          content: Text(loc.cannotDeleteBal, style: TextStyle(color: colorScheme.onSurface)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.ok, style: TextStyle(color: colorScheme.onSurface))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
              onPressed: () {
                Navigator.pop(context);
                _toggleArchiveStatus(id, true);
              }, 
              child: Text(loc.archiveNow)
            )
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: TextStyle(color: colorScheme.onSurface)),
        content: Text(loc.confirmDeleteSupplier, style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.yesDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteSupplier(id);
        
        if (!mounted) return;
        _refreshList(); // Reload list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierDeleted), backgroundColor: colorScheme.error));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  Future<void> _toggleArchiveStatus(int id, bool archive) async {
    await _repository.toggleSupplierStatus(id);
    _refreshList();
    if (_showArchiveOverlay) _loadArchivedSuppliers();
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = supplier != null;

    final nameEngCtrl = TextEditingController(text: supplier?.nameEnglish);
    final nameUrduCtrl = TextEditingController(text: supplier?.nameUrdu);
    final phoneCtrl = TextEditingController(text: supplier?.contactPrimary);
    final addressCtrl = TextEditingController(text: supplier?.address);
    final typeCtrl = TextEditingController(text: supplier?.supplierType);
    final balanceCtrl = TextEditingController(text: supplier != null ? CurrencyUtils.toDecimal(supplier.outstandingBalance) : '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(isEdit ? loc.editSupplier : loc.addSupplier, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEngCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(loc.nameEnglish, Icons.person, colorScheme),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameUrduCtrl,
                style: TextStyle(color: colorScheme.onSurface, fontFamily: 'NooriNastaleeq'),
                decoration: _inputDecoration(loc.nameUrdu, Icons.translate, colorScheme),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(loc.phoneNum, Icons.phone, colorScheme),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(loc.address, Icons.location_on, colorScheme),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: typeCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration("Supplier Type", Icons.category, colorScheme),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(loc.balance, Icons.account_balance_wallet, colorScheme),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () {
              final balance = CurrencyUtils.toPaisas(balanceCtrl.text);
              if (isEdit) {
                _updateSupplier(
                  supplier.id!, 
                  nameEngCtrl.text, 
                  nameUrduCtrl.text, 
                  phoneCtrl.text, 
                  addressCtrl.text,
                  typeCtrl.text,
                  balance
                );
              } else {
                _addSupplier(
                  nameEngCtrl.text, 
                  nameUrduCtrl.text, 
                  phoneCtrl.text, 
                  addressCtrl.text,
                  typeCtrl.text,
                  balance
                );
              }
            },
            child: Text(isEdit ? loc.update : loc.save),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.suppliersManagement, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // KPI Card
              _buildDashboard(loc),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) => _firstLoad(),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: loc.search,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
                    filled: true, fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    isDense: true,
                  ),
                ),
              ),
              
              // List
              Expanded(
                child: _isFirstLoadRunning
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : suppliers.isEmpty
                      ? Center(child: Text(loc.noSuppliersFound, style: TextStyle(color: colorScheme.onSurface)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: suppliers.length + (_isLoadMoreRunning ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == suppliers.length) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                              );
                            }
                            final supplier = suppliers[index];
                            final isSelected = _selectedSupplierForLedger?.id == supplier.id;
                            return _buildSupplierRow(supplier, colorScheme, loc, isSelected);
                          },
                        ),
              ),
            ],
          ),
          
          // Overlays
          if (_showArchiveOverlay) _buildArchiveOverlay(loc),
          if (_selectedSupplierForLedger != null) _buildLedgerOverlay(loc),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildDashboard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      height: 115,
      child: Row(
        children: [
          Expanded(child: _buildKpiCard("Total", countTotal, balTotal, null)),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard("Active", countActive, balActive, null)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard("Archived", countArchived, balArchived, () { 
               setState(() {
                 _showArchiveOverlay = true;
                 _loadArchivedSuppliers();
               });
            }, isOrange: true), 
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, int count, int amount, VoidCallback? onTap, {bool isOrange = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = isOrange ? colorScheme.tertiaryContainer : colorScheme.primaryContainer;
    final contentColor = isOrange ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: contentColor, fontWeight: FontWeight.bold)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(Icons.business, color: contentColor), Text("$count", style: TextStyle(color: contentColor, fontSize: 18, fontWeight: FontWeight.bold))]),
            Text(CurrencyUtils.formatRupees(amount), style: TextStyle(color: contentColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierRow(Supplier supplier, ColorScheme colorScheme, AppLocalizations loc, bool isSelected) {
    return Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withOpacity(0.2) : null,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.business, size: 16, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.nameUrdu ?? supplier.nameEnglish,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        supplier.contactPrimary ?? '-', 
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)
                      ),
                      if (supplier.supplierType != null && supplier.supplierType!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(supplier.supplierType!, style: TextStyle(fontSize: 10, color: colorScheme.onSecondaryContainer)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.formatRupees(supplier.outstandingBalance),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.primary),
                ),
                Text(loc.balance, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.receipt_long, color: colorScheme.primary),
            tooltip: "View Ledger",
            onPressed: () => _openLedger(supplier),
          ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') _showSupplierDialog(supplier: supplier);
                if (value == 'archive') _toggleArchiveStatus(supplier.id!, true);
                if (value == 'delete') _deleteSupplier(supplier.id!, supplier.outstandingBalance);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: colorScheme.secondary), const SizedBox(width: 8), Text(loc.editSupplier)])),
                PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive, size: 16, color: colorScheme.onSurface), const SizedBox(width: 8), Text(loc.archiveAction)])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: colorScheme.error), const SizedBox(width: 8), Text(loc.delete, style: TextStyle(color: colorScheme.error))])),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildLedgerOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final supplier = _selectedSupplierForLedger!;
    final name = supplier.nameEnglish;

    int netBalance = 0;
    if (_currentLedger.isNotEmpty) {
      netBalance = (_currentLedger.first['balance'] as num).toInt();
    }

    return Stack(
      children: [
        GestureDetector(onTap: () => setState(() => _selectedSupplierForLedger = null), child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(blurRadius: 20, color: colorScheme.shadow.withOpacity(0.25))],
            ),
            child: Column(
              children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  Text(supplier.contactPrimary ?? '', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
              Row(
                children: [
                  _buildSummaryChip("Payable Balance", netBalance, colorScheme.primary, colorScheme),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showPaymentDialog,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text("Pay Supplier"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.print), onPressed: () => _handleExport(loc), tooltip: "Export"),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedSupplierForLedger = null)),
                ],
              ),
            ],
          ),
        ),

        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _ledgerStartDate != null && _ledgerEndDate != null 
                      ? DateTimeRange(start: _ledgerStartDate!, end: _ledgerEndDate!) 
                      : null,
                  );
                  if (picked != null) {
                    setState(() {
                      _ledgerStartDate = picked.start;
                      _ledgerEndDate = picked.end;
                    });
                    _getSupplierLedger(supplier.id!);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(_ledgerStartDate == null ? "Date Range" : "${DateFormat('dd/MM').format(_ledgerStartDate!)} - ${DateFormat('dd/MM').format(_ledgerEndDate!)}", style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              if (_ledgerStartDate != null) IconButton(icon: const Icon(Icons.clear, size: 14), onPressed: () { setState(() { _ledgerStartDate = null; _ledgerEndDate = null; }); _getSupplierLedger(supplier.id!); }),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'ALL', label: Text('All')), ButtonSegment(value: 'BILL', label: Text('Bills')), ButtonSegment(value: 'PAYMENT', label: Text('Payments'))],
                selected: {_ledgerFilterType},
                onSelectionChanged: (val) => setState(() => _ledgerFilterType = val.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              const Spacer(),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _ledgerSearchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: const Icon(Icons.search, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() => _ledgerSearchQuery = val),
                ),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          child: Row(
            children: [
              const SizedBox(width: 40), // Space for expand icon
              Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
              Expanded(flex: 3, child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
              Expanded(flex: 2, child: Text("Purchase Bill", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
              Expanded(flex: 2, child: Text("Payment Sent", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
              Expanded(flex: 2, child: Text("Payable Balance", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLedgerLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : _filteredLedgerRows.isEmpty
                  ? Center(child: Text("No transactions found", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: _filteredLedgerRows.length,
                      itemBuilder: (context, index) {
                        return _buildLedgerRow(index, colorScheme);
                      },
                    ),
        ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String label, int amount, Color color, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          Text(CurrencyUtils.formatRupees(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(int index, ColorScheme colorScheme) {
    final row = _filteredLedgerRows[index];
    final isExpanded = _expandedRowIndex == index;
    final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final isBill = row['type'] == 'BILL';

    return Column(
      children: [
        InkWell(
          onTap: isBill ? () {
            setState(() {
              if (_expandedRowIndex == index) {
                _expandedRowIndex = null;
              } else {
                _expandedRowIndex = index;
                _fetchBillItems(row['ref_id']);
              }
            });
          } : null,
          hoverColor: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: isBill 
                    ? Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: colorScheme.onSurfaceVariant)
                    : null,
                ),
                Expanded(flex: 2, child: Text(dateStr, style: TextStyle(fontSize: 13, color: colorScheme.onSurface))),
                Expanded(flex: 3, child: Text(row['desc'] ?? '', style: TextStyle(fontSize: 13, color: colorScheme.onSurface))),
                Expanded(flex: 2, child: Text(row['cr'] > 0 ? CurrencyUtils.formatRupees(row['cr']) : '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.error))),
                Expanded(flex: 2, child: Text(row['dr'] > 0 ? CurrencyUtils.formatRupees(row['dr']) : '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.primary))),
                Expanded(flex: 2, child: Text(CurrencyUtils.formatRupees(row['balance']), textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
            ? Container(
                color: colorScheme.surfaceVariant.withOpacity(0.1),
                padding: const EdgeInsets.fromLTRB(60, 8, 16, 16),
                child: _buildExpandedDetails(row['ref_id'], colorScheme),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(int billId, ColorScheme colorScheme) {
    final items = _billItemsCache[billId];
    
    if (items == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("No items details available.", style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
      children: [
        TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colorScheme.outlineVariant))),
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("Item", style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("Qty", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("Unit", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("Rate", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
          ],
        ),
        ...items.map((item) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item['name_english'] ?? item['name_urdu'] ?? 'Unknown', style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item['quantity'].toString(), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item['unit_name'] ?? '-', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item['cost_price'] != null ? CurrencyUtils.formatRupees(item['cost_price']) : '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item['total_amount'] != null ? CurrencyUtils.formatRupees(item['total_amount']) : '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
          ],
        )),
      ],
    );
  }

  Widget _buildArchiveOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        GestureDetector(onTap: () => setState(() => _showArchiveOverlay = false), child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(loc.archivedCustomers, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _showArchiveOverlay = false))]),
                const Divider(),
                Expanded(
                  child: archivedSuppliers.isEmpty
                    ? Center(child: Text(loc.noSuppliersFound))
                    : ListView.builder(
                        itemCount: archivedSuppliers.length,
                        itemBuilder: (context, index) {
                          final s = archivedSuppliers[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.archive),
                              title: Text(s.nameEnglish),
                              subtitle: Text("Bal: ${CurrencyUtils.formatRupees(s.outstandingBalance)}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.unarchive),
                                onPressed: () => _toggleArchiveStatus(s.id!, false),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text("Pay Supplier", style: TextStyle(color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: _inputDecoration("Amount", Icons.money, colorScheme),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: _inputDecoration("Notes", Icons.note, colorScheme),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                final amount = CurrencyUtils.toPaisas(amountCtrl.text);
                if (amount > 0) {
                  Navigator.pop(context);
                  _addPayment(_selectedSupplierForLedger!.id!, amount, notesCtrl.text);
                }
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}