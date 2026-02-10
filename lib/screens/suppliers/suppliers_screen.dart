// lib/screens/master_data/suppliers_screen.dart
import 'package:flutter/material.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../domain/entities/money.dart';
import '../../models/supplier_model.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; // Keep for PdfColor
import '../../services/ledger_export_service.dart';
import '../../core/constants/desktop_dimensions.dart';

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
  int countTotal = 0;
  int balTotal = 0;
  int countActive = 0;
  int balActive = 0;
  int countArchived = 0;
  int balArchived = 0;

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
      if (_ledgerFilterType == 'PAYMENT' && row['type'] != 'PAYMENT') {
        return false;
      }

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
                final messenger = ScaffoldMessenger.of(context);

                Navigator.of(context).pop();
                final service = LedgerExportService();
                final path = await service.exportSupplierLedgerToCsv(
                    _currentLedger, _selectedSupplierForLedger!);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Saved to: $path')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CRUD Operations ---

  Future<void> _addSupplier(String nameEng, String nameUrdu, String phone,
      String address, String type, int balance) async {
    final loc = AppLocalizations.of(context)!;
    if (nameEng.isEmpty) return;

    try {
      // Check phone uniqueness
      if (phone.isNotEmpty) {
        final exists = await _repository.supplierContactExists(phone);

        if (!mounted) return;

        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(loc.phoneExistsError),
              backgroundColor: Theme.of(context).colorScheme.error));
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
      await _refreshList(); // Reload list to show new item
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.supplierAdded),
          backgroundColor: Theme.of(context).colorScheme.primary));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _updateSupplier(int id, String nameEng, String nameUrdu,
      String phone, String address, String type, int balance) async {
    final loc = AppLocalizations.of(context)!;
    try {
      // Check phone uniqueness
      if (phone.isNotEmpty) {
        final exists =
            await _repository.supplierContactExists(phone, excludeId: id);

        if (!mounted) return;

        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(loc.phoneExistsError),
              backgroundColor: Theme.of(context).colorScheme.error));
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
      await _refreshList(); // Reload list
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.supplierUpdated),
          backgroundColor: Theme.of(context).colorScheme.primary));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
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
          title:
              Text(loc.warning, style: Theme.of(context).textTheme.titleLarge),
          content: Text(loc.cannotDeleteBal,
              style: Theme.of(context).textTheme.bodyMedium),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text(loc.ok)),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary),
                onPressed: () {
                  Navigator.pop(context);
                  _toggleArchiveStatus(id, true);
                },
                child: Text(loc.archiveNow))
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: Theme.of(context).textTheme.titleLarge),
        content: Text(loc.confirmDeleteSupplier,
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
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
        await _refreshList(); // Reload list
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.supplierDeleted),
            backgroundColor: colorScheme.error));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  Future<void> _toggleArchiveStatus(int id, bool archive) async {
    await _repository.toggleSupplierStatus(id);
    await _refreshList();
    if (_showArchiveOverlay) await _loadArchivedSuppliers();
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
    final balanceCtrl = TextEditingController(
        text: supplier != null
            ? Money(supplier.outstandingBalance).toRupeesString()
            : '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(isEdit ? loc.editSupplier : loc.addSupplier,
            style: Theme.of(context).textTheme.titleLarge),
        contentPadding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
        content: SizedBox(
          width: DesktopDimensions.dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEngCtrl,
                decoration: _inputDecoration(
                    loc.nameEnglish, Icons.person, colorScheme),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: nameUrduCtrl,
                style: const TextStyle(fontFamily: 'NooriNastaleeq'),
                decoration: _inputDecoration(
                    loc.nameUrdu, Icons.translate, colorScheme),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    _inputDecoration(loc.phoneNum, Icons.phone, colorScheme),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: addressCtrl,
                decoration: _inputDecoration(
                    loc.address, Icons.location_on, colorScheme),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: typeCtrl,
                decoration: _inputDecoration(
                    "Supplier Type", Icons.category, colorScheme),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                    loc.balance, Icons.account_balance_wallet, colorScheme),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () {
              Money? parsedBalance;
              try {
                parsedBalance = Money.fromRupeesString(balanceCtrl.text);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.invalidAmount),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }
              final balance = parsedBalance.paisas;
              if (isEdit) {
                _updateSupplier(
                    supplier.id!,
                    nameEngCtrl.text,
                    nameUrduCtrl.text,
                    phoneCtrl.text,
                    addressCtrl.text,
                    typeCtrl.text,
                    balance);
              } else {
                _addSupplier(nameEngCtrl.text, nameUrduCtrl.text,
                    phoneCtrl.text, addressCtrl.text, typeCtrl.text, balance);
              }
            },
            child: Text(isEdit ? loc.update : loc.save),
          ),
        ],
      ),
    ).whenComplete(() {
      nameEngCtrl.dispose();
      nameUrduCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      typeCtrl.dispose();
      balanceCtrl.dispose();
    });
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.formFieldBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.formFieldBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.formFieldBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
          child: Column(
            children: [
              // Local Toolbar
              Container(
                padding: const EdgeInsets.only(
                  bottom: DesktopDimensions.spacingMedium,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showSupplierDialog(),
                      icon: const Icon(Icons.add),
                      label: Text(loc.addSupplier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDashboard(loc),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Card(
                elevation: DesktopDimensions.cardElevation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius)),
                child: Padding(
                  padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
                  child: TextField(
                    controller: searchController,
                    onChanged: (val) => _firstLoad(),
                    decoration: InputDecoration(
                      hintText: loc.search,
                      prefixIcon: Icon(Icons.search,
                          size: DesktopDimensions.iconSizeMedium,
                          color: colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.smallBorderRadius),
                          borderSide: BorderSide(color: colorScheme.outline)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: DesktopDimensions.spacingSmall,
                          vertical: DesktopDimensions.spacingSmall),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Expanded(
                child: _isFirstLoadRunning
                    ? Center(
                        child: CircularProgressIndicator(
                            color: colorScheme.primary))
                    : suppliers.isEmpty
                        ? Center(
                            child: Text(loc.noSuppliersFound,
                                style: Theme.of(context).textTheme.bodyMedium))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount:
                                suppliers.length + (_isLoadMoreRunning ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == suppliers.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(
                                      DesktopDimensions.spacingMedium),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: colorScheme.primary)),
                                );
                              }
                              final supplier = suppliers[index];
                              final isSelected =
                                  _selectedSupplierForLedger?.id == supplier.id;
                              return _buildSupplierRow(
                                  supplier, colorScheme, loc, isSelected);
                            },
                          ),
              ),
            ],
          ),
        ),
        if (_showArchiveOverlay) _buildArchiveOverlay(loc),
        if (_selectedSupplierForLedger != null) _buildLedgerOverlay(loc),
      ],
    );
  }

  Widget _buildDashboard(AppLocalizations loc) {
    return SizedBox(
      height: DesktopDimensions.kpiHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildKpiCard("Total", countTotal, balTotal, null)),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Expanded(child: _buildKpiCard("Active", countActive, balTotal, null)),
          const SizedBox(width: DesktopDimensions.spacingMedium),
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

  Widget _buildKpiCard(String title, int count, int amount, VoidCallback? onTap,
      {bool isOrange = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor =
        isOrange ? colorScheme.tertiaryContainer : colorScheme.primaryContainer;
    final contentColor = isOrange
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;
    final borderColor = isOrange ? colorScheme.tertiary : colorScheme.primary;

    return _HoverableCard(
      onTap: onTap,
      color: borderColor,
      child: Container(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: contentColor, fontWeight: FontWeight.bold)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(Icons.business, color: contentColor),
              Text("$count",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: contentColor, fontWeight: FontWeight.bold))
            ]),
            Text(Money(amount).formattedNoDecimal,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: contentColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierRow(Supplier supplier, ColorScheme colorScheme,
      AppLocalizations loc, bool isSelected) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingStandard),
      leading: CircleAvatar(
        radius: DesktopDimensions.iconSizeSmall,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.business,
            size: DesktopDimensions.iconSizeSmall,
            color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        supplier.nameUrdu ?? supplier.nameEnglish,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(supplier.contactPrimary ?? '-',
              style: Theme.of(context).textTheme.bodySmall),
          if (supplier.supplierType != null &&
              supplier.supplierType!.isNotEmpty) ...[
            const SizedBox(width: DesktopDimensions.spacingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesktopDimensions.spacingSmall,
                  vertical: DesktopDimensions.spacingSmall),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius:
                    BorderRadius.circular(DesktopDimensions.spacingSmall),
              ),
              child: Text(supplier.supplierType!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.onSecondaryContainer)),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Money(supplier.outstandingBalance).formattedNoDecimal,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colorScheme.primary),
              ),
              Text(loc.balance, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          IconButton(
            icon: Icon(Icons.receipt_long, color: colorScheme.primary),
            tooltip: "View Ledger",
            onPressed: () => _openLedger(supplier),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: DesktopDimensions.iconSizeSmallMedium,
                color: colorScheme.onSurfaceVariant),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') _showSupplierDialog(supplier: supplier);
              if (value == 'archive') _toggleArchiveStatus(supplier.id!, true);
              if (value == 'delete') {
                _deleteSupplier(supplier.id!, supplier.outstandingBalance);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit,
                        size: DesktopDimensions.iconSizeSmall,
                        color: colorScheme.secondary),
                    const SizedBox(width: DesktopDimensions.spacingSmall),
                    Text(loc.editSupplier)
                  ])),
              PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(Icons.archive,
                        size: DesktopDimensions.iconSizeSmall,
                        color: colorScheme.onSurface),
                    const SizedBox(width: DesktopDimensions.spacingSmall),
                    Text(loc.archiveAction)
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete,
                        size: DesktopDimensions.iconSizeSmall,
                        color: colorScheme.error),
                    const SizedBox(width: DesktopDimensions.spacingSmall),
                    Text(loc.delete,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.error))
                  ])),
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
        GestureDetector(
            onTap: () => setState(() => _selectedSupplierForLedger = null),
            child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: DesktopDimensions.dialogWidth,
            height: DesktopDimensions.dialogHeight,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
              boxShadow: [
                BoxShadow(
                    blurRadius: 20, color: colorScheme.shadow.withOpacity(0.25))
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesktopDimensions.spacingLarge,
                      vertical: DesktopDimensions.spacingMedium),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text(supplier.contactPrimary ?? '',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      Row(
                        children: [
                          _buildSummaryChip("Payable Balance", netBalance,
                              colorScheme.primary, colorScheme),
                          const SizedBox(
                              width: DesktopDimensions.spacingStandard),
                          ElevatedButton.icon(
                            onPressed: _showPaymentDialog,
                            icon: const Icon(Icons.payment,
                                size: DesktopDimensions.iconSizeSmallMedium),
                            label: const Text("Pay Supplier"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: DesktopDimensions.spacingMedium,
                                  vertical: DesktopDimensions.spacingStandard),
                            ),
                          ),
                          const SizedBox(width: DesktopDimensions.spacingSmall),
                          IconButton(
                              icon: const Icon(Icons.print),
                              onPressed: () => _handleExport(loc),
                              tooltip: "Export"),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(
                                  () => _selectedSupplierForLedger = null)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesktopDimensions.spacingMedium,
                      vertical: DesktopDimensions.spacingSmall),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _ledgerStartDate != null &&
                                    _ledgerEndDate != null
                                ? DateTimeRange(
                                    start: _ledgerStartDate!,
                                    end: _ledgerEndDate!)
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
                        icon: const Icon(Icons.calendar_today,
                            size: DesktopDimensions.bodySize),
                        label: Text(_ledgerStartDate == null
                            ? "Date Range"
                            : "${DateFormat('dd/MM').format(_ledgerStartDate!)} - ${DateFormat('dd/MM').format(_ledgerEndDate!)}"),
                        style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: Theme.of(context).textTheme.bodySmall),
                      ),
                      if (_ledgerStartDate != null)
                        IconButton(
                            icon: const Icon(Icons.clear,
                                size: DesktopDimensions.bodySize),
                            onPressed: () {
                              setState(() {
                                _ledgerStartDate = null;
                                _ledgerEndDate = null;
                              });
                              _getSupplierLedger(supplier.id!);
                            }),
                      const SizedBox(width: DesktopDimensions.spacingStandard),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ALL', label: Text('All')),
                          ButtonSegment(value: 'BILL', label: Text('Bills')),
                          ButtonSegment(
                              value: 'PAYMENT', label: Text('Payments'))
                        ],
                        selected: {_ledgerFilterType},
                        onSelectionChanged: (val) =>
                            setState(() => _ledgerFilterType = val.first),
                        style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: DesktopDimensions.labelWidthStandard,
                        child: TextField(
                          controller: _ledgerSearchCtrl,
                          decoration: InputDecoration(
                            hintText: "Search...",
                            prefixIcon: const Icon(Icons.search,
                                size: DesktopDimensions.iconSizeSmall),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: DesktopDimensions.spacingSmall,
                                horizontal: DesktopDimensions.spacingSmall),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    DesktopDimensions.smallBorderRadius)),
                          ),
                          onChanged: (val) =>
                              setState(() => _ledgerSearchQuery = val),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: DesktopDimensions.spacingStandard,
                      horizontal: DesktopDimensions.spacingMedium),
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Row(
                    children: [
                      const SizedBox(
                          width: DesktopDimensions
                              .buttonHeight), // Space for expand icon
                      Expanded(
                          flex: 2,
                          child: Text("Date",
                              style: Theme.of(context).textTheme.titleSmall)),
                      Expanded(
                          flex: 3,
                          child: Text("Description",
                              style: Theme.of(context).textTheme.titleSmall)),
                      Expanded(
                          flex: 2,
                          child: Text("Purchase Bill",
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleSmall)),
                      Expanded(
                          flex: 2,
                          child: Text("Payment Sent",
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleSmall)),
                      Expanded(
                          flex: 2,
                          child: Text("Payable Balance",
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleSmall)),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _isLedgerLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary))
                      : _filteredLedgerRows.isEmpty
                          ? Center(
                              child: Text("No transactions found",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium))
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

  Widget _buildSummaryChip(
      String label, int amount, Color color, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingStandard,
          vertical: DesktopDimensions.spacingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(DesktopDimensions.smallBorderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(Money(amount).formattedNoDecimal,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(int index, ColorScheme colorScheme) {
    final row = _filteredLedgerRows[index];
    final isExpanded = _expandedRowIndex == index;
    final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final Money dr = Money(((row['dr'] ?? 0) as num).toInt());
    final Money cr = Money(((row['cr'] ?? 0) as num).toInt());
    final Money balance = Money(((row['balance'] ?? 0) as num).toInt());
    final isBill = row['type'] == 'BILL';

    return Column(
      children: [
        InkWell(
          onTap: isBill
              ? () {
                  setState(() {
                    if (_expandedRowIndex == index) {
                      _expandedRowIndex = null;
                    } else {
                      _expandedRowIndex = index;
                      _fetchBillItems(row['ref_id']);
                    }
                  });
                }
              : null,
          hoverColor: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: DesktopDimensions.spacingStandard,
                horizontal: DesktopDimensions.spacingMedium),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: DesktopDimensions.buttonHeight,
                  child: isBill
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: DesktopDimensions.iconSizeMedium,
                          color: colorScheme.onSurfaceVariant)
                      : null,
                ),
                Expanded(
                    flex: 2,
                    child: Text(dateStr,
                        style: Theme.of(context).textTheme.bodyLarge)),
                Expanded(
                    flex: 3,
                    child: Text(row['desc'] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge)),
                Expanded(
                    flex: 2,
                    child: Text(cr > Money.zero ? cr.formattedNoDecimal : '-',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error))),
                Expanded(
                    flex: 2,
                    child: Text(dr > Money.zero ? dr.formattedNoDecimal : '-',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary))),
                Expanded(
                    flex: 2,
                    child: Text(balance.formattedNoDecimal,
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
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
                  padding: const EdgeInsets.fromLTRB(
                      DesktopDimensions.spacingXLarge,
                      DesktopDimensions.spacingSmall,
                      DesktopDimensions.spacingMedium,
                      DesktopDimensions.spacingMedium),
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
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(DesktopDimensions.spacingSmall),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DesktopDimensions.spacingSmall),
        child: Text("No items details available.",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontStyle: FontStyle.italic)),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1)
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant))),
          children: [
            Padding(
                padding: const EdgeInsets.only(
                    bottom: DesktopDimensions.spacingXSmall),
                child:
                    Text("Item", style: Theme.of(context).textTheme.bodySmall)),
            Padding(
                padding: const EdgeInsets.only(
                    bottom: DesktopDimensions.spacingXSmall),
                child: Text("Qty",
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall)),
            Padding(
                padding: const EdgeInsets.only(
                    bottom: DesktopDimensions.spacingXSmall),
                child: Text("Unit",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall)),
            Padding(
                padding: const EdgeInsets.only(
                    bottom: DesktopDimensions.spacingXSmall),
                child: Text("Rate",
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall)),
            Padding(
                padding: const EdgeInsets.only(
                    bottom: DesktopDimensions.spacingXSmall),
                child: Text("Total",
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
        ...items.map((item) => TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingXSmall),
                    child: Text(
                        item['name_english'] ?? item['name_urdu'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyLarge)),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingXSmall),
                    child: Text(item['quantity'].toString(),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge)),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingXSmall),
                    child: Text(item['unit_type'] ?? '-',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge)),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingXSmall),
                    child: Text(
                        item['cost_price'] != null
                            ? Money((item['cost_price'] as num).toInt())
                                .formattedNoDecimal
                            : '-',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge)),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingXSmall),
                    child: Text(
                        item['total_amount'] != null
                            ? Money((item['total_amount'] as num).toInt())
                                .formattedNoDecimal
                            : '-',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge)),
              ],
            )),
      ],
    );
  }

  Widget _buildArchiveOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        GestureDetector(
            onTap: () => setState(() => _showArchiveOverlay = false),
            child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: DesktopDimensions.dialogWidth,
            height: DesktopDimensions.dialogHeight,
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                    DesktopDimensions.dialogBorderRadius)),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.archivedCustomers,
                          style: Theme.of(context).textTheme.headlineSmall),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _showArchiveOverlay = false))
                    ]),
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
                                subtitle: Text(
                                    "Bal: ${Money(s.outstandingBalance).formattedNoDecimal}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.unarchive),
                                  onPressed: () =>
                                      _toggleArchiveStatus(s.id!, false),
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
        title: Text("Pay Supplier",
            style: Theme.of(context).textTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Amount", Icons.money, colorScheme),
            ),
            const SizedBox(height: DesktopDimensions.spacingStandard),
            TextField(
              controller: notesCtrl,
              decoration: _inputDecoration("Notes", Icons.note, colorScheme),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isNotEmpty) {
                Money? amountMoney;
                try {
                  amountMoney = Money.fromRupeesString(amountCtrl.text);
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.invalidAmount),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                  return;
                }
                final amount = amountMoney.paisas;
                if (amount > 0) {
                  Navigator.pop(context);
                  final supplierId = _selectedSupplierForLedger?.id;
                  if (supplierId == null) return;
                  await _addPayment(supplierId, amount, notesCtrl.text);
                }
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    ).whenComplete(() {
      amountCtrl.dispose();
      notesCtrl.dispose();
    });
  }
}

class _HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;

  const _HoverableCard({
    required this.child,
    this.onTap,
    required this.color,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHoveredOrFocused = _isHovered || _isFocused;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow
                  .withOpacity(isHoveredOrFocused ? 0.15 : 0.05),
              blurRadius: isHoveredOrFocused ? 8 : 2,
              offset: Offset(0, isHoveredOrFocused ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: isHoveredOrFocused
                ? widget.color.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _isFocused = value),
            borderRadius:
                BorderRadius.circular(DesktopDimensions.cardBorderRadius),
            hoverColor: widget.color.withOpacity(0.05),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
