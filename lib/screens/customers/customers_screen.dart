// lib/screens/master_data/customers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liaqat_store/core/utils/currency_utils.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/services/ledger_export_service.dart';
import 'package:liaqat_store/models/invoice_model.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer_model.dart';
import '../../domain/entities/money.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomersRepository _customersRepository = CustomersRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final LedgerExportService _ledgerExportService = LedgerExportService();
  // --- STATE VARIABLES ---
  List<Customer> customers = [];
  List<Customer> archivedCustomers = [];
  
  // Ledger State
  bool _showArchiveOverlay = false;
  bool _showLedgerOverlay = false;
  List<Map<String, dynamic>> _currentLedger = [];
  Customer? _selectedCustomerForLedger;
  
  // Ledger Filters
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;
  String _ledgerFilterType = 'ALL'; // ALL, SALE, RECEIPT
  String _ledgerSearchQuery = '';
  final TextEditingController _ledgerSearchCtrl = TextEditingController();

  bool _isFirstLoadRunning = true;
  final TextEditingController searchController = TextEditingController();

  // Stats
  int countTotal = 0; int balTotal = 0;
  int countActive = 0; int balActive = 0;
  int countArchived = 0; int balArchived = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _ledgerSearchCtrl.dispose();
    super.dispose();
  }

  // --- DATABASE & LOGIC ---

  Future<void> _refreshData() async {
    await _loadStats();
    await _loadActiveCustomers();
    if (_showArchiveOverlay) await _loadArchivedCustomers();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _customersRepository.getCustomerStats();
      
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
      debugPrint("Error loading stats: $e");
    }
  }

  Future<void> _loadActiveCustomers() async {
    if (customers.isEmpty) {
      setState(() => _isFirstLoadRunning = true);
    }
    try {
      final searchText = searchController.text.trim();
      
      List<Customer> result;
      if (searchText.isEmpty) {
        result = await _customersRepository.getActiveCustomers();
      } else {
        result = await _customersRepository.searchCustomers(searchText, activeOnly: true);
      }

      if (mounted) {
        setState(() {
          customers = result;
          _isFirstLoadRunning = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading customers: $e");
      if (mounted) {
        setState(() => _isFirstLoadRunning = false);
      }
    }
  }

  Future<void> _loadArchivedCustomers() async {
    final result = await _customersRepository.getArchivedCustomers();
    setState(() => archivedCustomers = result);
  }

  Future<bool> _isPhoneUnique(String phone, {int? excludeId}) async {
    return await _customersRepository.isPhoneUnique(phone, excludeId: excludeId);
  }

  Future<bool> _canDelete(int id, int balance) async {
    if (balance != 0) return false;
    return true; 
  }

  // --- LEDGER LOGIC (GROUPED) ---

  Future<void> _openLedger(Customer customer) async {
    setState(() {
      _selectedCustomerForLedger = customer;
      _showLedgerOverlay = true;
      _currentLedger = []; 
      // Reset filters
      _ledgerStartDate = null;
      _ledgerEndDate = null;
      _ledgerFilterType = 'ALL';
      _ledgerSearchQuery = '';
      _ledgerSearchCtrl.clear();
    });
    await _loadLedgerData();
  }

  Future<void> _loadLedgerData() async {
    if (_selectedCustomerForLedger == null) return;
    try {
      final data = await _customersRepository.getCustomerLedger(
        _selectedCustomerForLedger!.id!,
        startDate: _ledgerStartDate,
        endDate: _ledgerEndDate,
      );
      if (mounted) setState(() => _currentLedger = data);
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }
  }

  List<Map<String, dynamic>> get _filteredLedgerRows {
    return _currentLedger.where((row) {
      // 1. Type Filter
      if (_ledgerFilterType == 'SALE' && row['type'] != 'SALE') return false;
      if (_ledgerFilterType == 'RECEIPT' && row['type'] != 'PAYMENT' && row['type'] != 'RECEIPT') return false;

      // 2. Search Filter
      if (_ledgerSearchQuery.isNotEmpty) {
        final q = _ledgerSearchQuery.toLowerCase();
        final docNo = row['ref_no'].toString().toLowerCase();
        final desc = (row['description'] ?? '').toString().toLowerCase();
        return docNo.contains(q) || desc.contains(q);
      }
      return true;
    }).toList();
  }

  /// Add payment to the currently selected customer
  /// and refresh the ledger data.
  ///
  /// [amount] is the amount to be added
  /// [notes] is a brief description of the payment
  ///
  /// After adding the payment, the ledger data is refreshed
  /// and the ledger overlay is shown with the updated data.
  Future<void> _addPayment(Money amount, String notes) async {
    if (_selectedCustomerForLedger == null) return;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await _customersRepository.addPayment(_selectedCustomerForLedger!.id!, amount.paisas, date, notes);
    await _refreshData(); 
    await _loadLedgerData(); // Refresh ledger data
  }
  
  Future<void> _handleExport(AppLocalizations loc) async {
    if (_selectedCustomerForLedger == null || _currentLedger.isEmpty) return;
    
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    
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
              onTap: () {
                Navigator.pop(context);
                _ledgerExportService.exportToPdf(
                  _currentLedger, 
                  _selectedCustomerForLedger!, 
                  isUrdu: isUrdu
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export to Excel (CSV)'),
              onTap: () async {
                Navigator.pop(context);
                final path = await _ledgerExportService.exportToCsv(
                  _currentLedger, 
                  _selectedCustomerForLedger!
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to: $path'))
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _addOrUpdateCustomer({
    required int? id,
    required String nameEng,
    required String nameUrdu,
    required String phone,
    required String address,
    required int limit,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    bool isUnique = await _isPhoneUnique(phone, excludeId: id);
    if (!isUnique) throw Exception(loc.phoneExistsError);

    final customer = Customer(
      id: id,
      nameEnglish: nameEng,
      nameUrdu: nameUrdu,
      contactPrimary: phone,
      address: address,
      creditLimit: limit,
      outstandingBalance: 0,
      isActive: true,
    );

    if (id == null) {
      await _customersRepository.addCustomer(customer);
      _showSnack(loc.customerAddedSuccess, colorScheme.primary);
    } else {
      await _customersRepository.updateCustomer(id, customer);
      _showSnack(loc.customerUpdatedSuccess, colorScheme.primary);
    }
    _refreshData();
  }

  Future<void> _toggleArchiveStatus(int id, bool currentStatus) async {
    final customer = await _customersRepository.getCustomerById(id);
    if (customer == null) return;
    
    final updatedCustomer = customer.copyWith(isActive: !currentStatus);
    await _customersRepository.updateCustomer(id, updatedCustomer);
    _refreshData();
    if (_showArchiveOverlay) _loadArchivedCustomers(); 
  }

  Future<void> _deleteCustomer(int id, int balance) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!(await _canDelete(id, balance))) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(loc.warning, style: TextStyle(color: colorScheme.onSurface)),
          content: Text(loc.cannotDeleteBal, style: TextStyle(color: colorScheme.onSurface)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.ok, style: TextStyle(color: colorScheme.onSurface))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.tertiary, foregroundColor: colorScheme.onTertiary),
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

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: TextStyle(color: colorScheme.onSurface)),
        content: Text(loc.confirmDeleteItem, style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.no, style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            onPressed: () => Navigator.pop(context, true), 
            child: Text(loc.yesDelete)
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _customersRepository.deleteCustomer(id);
      _refreshData();
      _showSnack(loc.itemDeleted, colorScheme.onSurfaceVariant);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.customers, style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary, 
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // MAIN CONTENT
          Column(
            children: [
              _buildDashboard(loc),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => _loadActiveCustomers(),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: loc.searchPlaceholder,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    filled: true, fillColor: colorScheme.surfaceVariant,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                ),
              ),

              Expanded(
                child: _isFirstLoadRunning
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : customers.isEmpty
                  ? Center(child: Text(loc.noCustomersFound, style: TextStyle(color: colorScheme.onSurface)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: customers.length,
                      itemBuilder: (context, index) => _buildCustomerCard(customers[index]),
                    ),
              ),
            ],
          ),

          // OVERLAYS
          _buildArchiveOverlay(loc),
          if (_showLedgerOverlay) _buildLedgerOverlay(loc),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () => _showAddDialog(),
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
          Expanded(child: _buildKpiCard(loc, loc.dashboardTotal, countTotal, Money(balTotal), null)),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard(loc, loc.dashboardActive, countActive, Money(balActive), null)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(loc, loc.dashboardArchived, countArchived, Money(balArchived), () {
               setState(() {
                 _showArchiveOverlay = true;
                 _loadArchivedCustomers();
               });
            }, isOrange: true), 
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(AppLocalizations loc, String title, int count, Money amount, VoidCallback? onTap, {bool isOrange = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final containerColor = isOrange ? colorScheme.tertiaryContainer : colorScheme.primaryContainer;
    final contentColor = isOrange ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer;
    final borderColor = isOrange ? colorScheme.tertiary : colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2), 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, style: TextStyle(color: contentColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.people, size: 18, color: contentColor), 
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("$count", style: TextStyle(color: contentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text("${loc.balanceShort}: ${amount.toString()}", style: TextStyle(color: contentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, {bool isOverlay = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final Money balance = Money(customer.outstandingBalance);
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final String name = isUrdu 
        ? (customer.nameUrdu != null && customer.nameUrdu!.isNotEmpty ? customer.nameUrdu! : customer.nameEnglish) 
        : customer.nameEnglish;
    final String phone = customer.contactPrimary ?? '';

    return Card(
      elevation: 2, 
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: isUrdu ? 20 : 16, fontFamily: isUrdu ? 'NooriNastaleeq' : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phone, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            if (customer.creditLimit > 0)
              Text("${AppLocalizations.of(context)!.creditLimit}: ${Money(customer.creditLimit)}", style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (balance != const Money(0))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: balance > const Money(0) ? colorScheme.errorContainer : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: balance > const Money(0) ? colorScheme.error : colorScheme.primary)
                ),
                child: Text(balance.toString(), style: TextStyle(color: balance > const Money(0) ? colorScheme.error : colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            
            if (!isOverlay)
            IconButton(
              icon: Icon(Icons.receipt_long, color: colorScheme.primary),
              tooltip: "View Ledger",
              onPressed: () => _openLedger(customer),
            ),

            if (isOverlay)
              IconButton(icon: Icon(Icons.unarchive, color: colorScheme.primary), onPressed: () => _toggleArchiveStatus(customer.id!, false))
            else
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colorScheme.onSurface), 
                onSelected: (value) {
                  if (value == 'edit') _showAddDialog(customer: customer);
                  if (value == 'archive') _toggleArchiveStatus(customer.id!, true);
                  if (value == 'delete') _deleteCustomer(customer.id!, balance.paisas);
                },
                itemBuilder: (context) => [
                   PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: colorScheme.onSurface), const SizedBox(width: 8), Text('Edit', style: TextStyle(color: colorScheme.onSurface))])),
                   PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive, size: 18, color: colorScheme.onSurface), const SizedBox(width: 8), Text('Archive', style: TextStyle(color: colorScheme.onSurface))])),
                   PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: colorScheme.error), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: colorScheme.error))])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- LEDGER OVERLAY (GROUPED) ---
  Widget _buildLedgerOverlay(AppLocalizations loc) {
    final customer = _selectedCustomerForLedger!;

    return Stack(
      children: [
        GestureDetector(onTap: () => setState(() => _showLedgerOverlay = false), child: Container(color: Colors.black54)),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
            ),
            child: Column(
              children: [
                // ZONE A: HEADER
                _buildLedgerHeader(customer, loc),
                
                // ZONE B: FILTER BAR
                _buildLedgerFilterBar(loc),

                // ZONE C: TABLE HEADER
                _buildLedgerTableHeader(),

                // ZONE C: TABLE BODY
                Expanded(
                  child: _filteredLedgerRows.isEmpty
                      ? Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey[600])))
                      : ListView.builder(
                          itemCount: _filteredLedgerRows.length,
                          itemBuilder: (context, index) {
                            final row = _filteredLedgerRows[index];
                            return _LedgerRow(
                              row: row,
                              isEven: index % 2 == 0,
                              invoiceRepository: _invoiceRepository,
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

  Widget _buildLedgerHeader(Customer customer, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final Money balance = Money(customer.outstandingBalance);
    final isDebit = balance > const Money(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), offset: const Offset(0, 2), blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Customer Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.nameEnglish, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (customer.nameUrdu != null)
                Text(customer.nameUrdu!, style: const TextStyle(fontSize: 18, fontFamily: 'NooriNastaleeq', color: Colors.black54)),
              const SizedBox(height: 4),
              Text(customer.contactPrimary ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              if (customer.address != null)
                Text(customer.address!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          // Financials
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Current Balance", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              Text(
                balance.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                  color: isDebit ? Colors.red[700] : Colors.green[700],
                ),
              ),
              if (customer.creditLimit > 0)
                Text("Limit: ${Money(customer.creditLimit)}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(width: 24),
          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.add),
                label: const Text("Receive Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => _handleExport(loc),
                tooltip: "Export",
                color: Colors.grey[700],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showLedgerOverlay = false),
                tooltip: "Close",
                color: Colors.grey[700],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerFilterBar(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Date Range
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
                _loadLedgerData();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_ledgerStartDate == null 
              ? "Date Range" 
              : "${DateFormat('dd/MM').format(_ledgerStartDate!)} - ${DateFormat('dd/MM').format(_ledgerEndDate!)}"
            ),
            style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
          ),
          if (_ledgerStartDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 16), 
              onPressed: () {
                setState(() { _ledgerStartDate = null; _ledgerEndDate = null; });
                _loadLedgerData();
              }
            ),
          
          const SizedBox(width: 16),
          // Type Filter
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ALL', label: Text('All')),
              ButtonSegment(value: 'SALE', label: Text('Sales')),
              ButtonSegment(value: 'RECEIPT', label: Text('Receipts')),
            ],
            selected: {_ledgerFilterType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _ledgerFilterType = newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.selected)) return Theme.of(context).colorScheme.primaryContainer;
                return Colors.white;
              }),
            ),
          ),
          
          const Spacer(),
          // Search
          SizedBox(
            width: 250,
            child: TextField(
              controller: _ledgerSearchCtrl,
              decoration: InputDecoration(
                hintText: "Search Doc # or Desc...",
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _ledgerSearchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () {
                      _ledgerSearchCtrl.clear();
                      setState(() => _ledgerSearchQuery = '');
                    }) 
                  : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[400]!)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _ledgerSearchQuery = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("Doc No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 4, child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("Debit", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("Credit", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text("Balance", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.outline, width: 2)),
        title: Text("Receive Payment", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: _cleanInput("Amount", Icons.money),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: _cleanInput("Notes (Optional)", Icons.note),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            onPressed: () {
               if(amountCtrl.text.isNotEmpty) {
                 final Money amount = Money.fromRupeesString(amountCtrl.text);
                 if(amount > const Money(0)) {
                   Navigator.pop(context);
                   _addPayment(amount, notesCtrl.text);
                 }
               }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- ARCHIVE OVERLAY ---
  Widget _buildArchiveOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_showArchiveOverlay) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(onTap: () => setState(() => _showArchiveOverlay = false), child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline, width: 2), 
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.archivedCustomers, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    IconButton(icon: Icon(Icons.close, color: colorScheme.onSurface), onPressed: () => setState(() => _showArchiveOverlay = false))
                  ],
                ),
                Divider(color: colorScheme.primary),
                Expanded(
                  child: archivedCustomers.isEmpty
                      ? Center(child: Text(loc.noCustomersFound, style: TextStyle(color: colorScheme.onSurface)))
                      : ListView.builder(itemCount: archivedCustomers.length, itemBuilder: (context, index) => _buildCustomerCard(archivedCustomers[index], isOverlay: true)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- ADD/EDIT DIALOG ---
  void _showAddDialog({Customer? customer}) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final nameEnController = TextEditingController(text: customer?.nameEnglish ?? '');
    final nameUrController = TextEditingController(text: customer?.nameUrdu ?? '');
    final phoneController = TextEditingController(text: customer?.contactPrimary ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    String currentLimit = (customer?.creditLimit ?? 0).toString();
    final limitController = TextEditingController(text: currentLimit == "0" ? "" : currentLimit);
    bool isSaving = false;
    final bool isEdit = customer != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline, width: 2)),
              title: Text(customer == null ? loc.addCustomer : loc.editCustomer, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameEnController, 
                        decoration: _cleanInput("${loc.nameEnglish} *", Icons.person), 
                        style: TextStyle(color: colorScheme.onSurface),
                        readOnly: isEdit,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      // ✅ FIXED: Removed TextDirection.rtl
                      TextFormField(
                        controller: nameUrController, 
                        textAlign: TextAlign.start, 
                        decoration: _cleanInput("${loc.nameUrdu} *", Icons.translate), 
                        style: TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 18, color: colorScheme.onSurface),
                        readOnly: isEdit,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController, 
                        decoration: _cleanInput("${loc.phoneLabel} *", Icons.phone), 
                        keyboardType: TextInputType.phone, 
                        style: TextStyle(color: colorScheme.onSurface),
                        readOnly: isEdit,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: addressController, decoration: _cleanInput(loc.addressLabel, Icons.location_on), maxLines: 2, style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      TextFormField(controller: limitController, decoration: _cleanInput(loc.creditLimit, Icons.credit_card), keyboardType: TextInputType.number, style: TextStyle(color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                  onPressed: isSaving ? null : () async {
                     if (nameEnController.text.trim().isEmpty) { _showSnack("${loc.nameEnglish} ${loc.requiredField}", colorScheme.error); return; }
                     if (nameUrController.text.trim().isEmpty) { _showSnack("${loc.nameUrdu} ${loc.requiredField}", colorScheme.error); return; }
                     if (phoneController.text.trim().isEmpty) { _showSnack("${loc.phoneLabel} ${loc.requiredField}", colorScheme.error); return; }

                     setStateDialog(() => isSaving = true);
                     try {
                       await _addOrUpdateCustomer(
                         id: customer?.id, 
                         nameEng: nameEnController.text.trim(), 
                         nameUrdu: nameUrController.text.trim(), 
                         phone: phoneController.text.trim(), 
                         address: addressController.text.trim(), 
                         limit: Money.fromRupeesString(limitController.text).paisas
                       );
                       if (context.mounted) Navigator.pop(context);
                     } catch (e) {
                       setStateDialog(() => isSaving = false);
                       _showSnack(e.toString().replaceAll("Exception: ", ""), colorScheme.error);
                     }
                  },
                  child: isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary)) : Text(loc.save),
                ),
              ],
            );
          }
        );
      },
    );
  }

  InputDecoration _cleanInput(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.primary),
      prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
      filled: true, fillColor: colorScheme.surface, 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), isDense: true,
    );
  }
}

class _LedgerRow extends StatefulWidget {
  final Map<String, dynamic> row;
  final bool isEven;
  final InvoiceRepository invoiceRepository;

  const _LedgerRow({
    required this.row,
    required this.isEven,
    required this.invoiceRepository,
  });

  @override
  State<_LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<_LedgerRow> {
  bool _isExpanded = false;
  List<InvoiceItem>? _items;
  bool _isLoadingItems = false;
  String? _error;

  Future<void> _toggleExpand() async {
    if (widget.row['type'] != 'SALE') return; // Only expand sales

    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded && _items == null) {
      setState(() => _isLoadingItems = true);
      setState(() => _error = null);
      try {
        // Lazy Load Items
        final invoiceId = widget.row['ref_no'] as int; // ref_no is ref_id in simple query
        final items = await widget.invoiceRepository.getInvoiceItems(invoiceId);
        if (mounted) setState(() => _items = items);
      } catch (e) {
        if (mounted) setState(() => _error = "Failed to load details");
      } finally {
        if (mounted) setState(() => _isLoadingItems = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(date); // Fixed width format
    final Money debit = Money((row['debit'] as num).toInt());
    final Money credit = Money((row['credit'] as num).toInt());
    final Money balance = Money((row['balance'] as num).toInt());
    final isSale = row['type'] == 'SALE';
    final isReceipt = row['type'] == 'PAYMENT' || row['type'] == 'RECEIPT';
    
    // Visual Styles
    final bgColor = _isExpanded 
        ? Colors.blue[50] 
        : (isReceipt ? Colors.green[50]!.withOpacity(0.3) : (widget.isEven ? Colors.white : Colors.grey[50]));
    
    const textStyle = TextStyle(fontSize: 13, color: Colors.black87);
    const monoStyle = TextStyle(fontSize: 13, fontFamily: 'RobotoMono', color: Colors.black87);

    return Column(
      children: [
        InkWell(
          onTap: isSale ? _toggleExpand : null,
          hoverColor: Colors.blue[50],
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(dateStr, style: monoStyle)),
                Expanded(flex: 2, child: Text(isSale ? "INV-${row['ref_no']}" : "RCP-${row['ref_no']}", style: monoStyle)),
                Expanded(flex: 2, child: Text(isSale ? "SALE" : "RECEIPT", style: textStyle.copyWith(fontWeight: FontWeight.bold, color: isSale ? Colors.blue[800] : Colors.green[800]))),
                Expanded(flex: 4, child: Row(
                  children: [
                    if (isSale) 
                      Icon(_isExpanded ? Icons.arrow_drop_down : Icons.arrow_right, size: 16, color: Colors.grey[600]),
                    Expanded(child: Text(row['description'] ?? '', style: textStyle, overflow: TextOverflow.ellipsis)),
                  ],
                )),
                Expanded(flex: 2, child: Text(debit > const Money(0) ? debit.toString() : '-', textAlign: TextAlign.right, style: monoStyle)),
                Expanded(flex: 2, child: Text(credit > const Money(0) ? credit.toString() : '-', textAlign: TextAlign.right, style: monoStyle)),
                Expanded(flex: 2, child: Text(balance.toString(), textAlign: TextAlign.right, style: monoStyle.copyWith(fontWeight: FontWeight.bold, color: balance > const Money(0) ? Colors.red[700] : Colors.green[700]))),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(48, 8, 16, 16),
            child: _isLoadingItems
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : _error != null 
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _items == null || _items!.isEmpty
                    ? const Center(child: Text("No items found", style: TextStyle(fontStyle: FontStyle.italic)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Table(
                            border: TableBorder(bottom: BorderSide(color: Colors.grey[300]!)),
                            columnWidths: const {
                              0: FlexColumnWidth(4),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[200]),
                                children: const [
                                  Padding(padding: EdgeInsets.all(4), child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(4), child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(4), child: Text("Rate", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(4), child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                ]
                              ),
                              ..._items!.map((item) => TableRow(children: [
                                Padding(padding: const EdgeInsets.all(4), child: Text(item.itemName, style: const TextStyle(fontSize: 11))),
                                Padding(padding: const EdgeInsets.all(4), child: Text(item.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                Padding(padding: const EdgeInsets.all(4), child: Text(Money(item.rate).toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                                Padding(padding: const EdgeInsets.all(4), child: Text(Money(item.subtotal).toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                              ]
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
}
