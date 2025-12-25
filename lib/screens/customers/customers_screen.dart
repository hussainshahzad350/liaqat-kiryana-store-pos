// lib/screens/master_data/customers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomersRepository _customersRepository = CustomersRepository();
  // --- STATE VARIABLES ---
  List<Customer> customers = [];
  List<Customer> archivedCustomers = [];
  
  // Ledger State
  bool _showArchiveOverlay = false;
  bool _showLedgerOverlay = false;
  List<Map<String, dynamic>> _currentLedger = [];
  Customer? _selectedCustomerForLedger;

  bool _isFirstLoadRunning = true;
  final TextEditingController searchController = TextEditingController();

  // Stats
  int countTotal = 0; double balTotal = 0.0;
  int countActive = 0; double balActive = 0.0;
  int countArchived = 0; double balArchived = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --- DATABASE & LOGIC ---

  Future<void> _refreshData() async {
    await _loadStats();
    await _loadActiveCustomers();
    if (_showArchiveOverlay) await _loadArchivedCustomers();
  }

  Future<void> _loadStats() async {
    final stats = await _customersRepository.getCustomerStats();
    
    if (mounted) {
      setState(() {
        countTotal = stats['countTotal'] as int;
        balTotal = stats['balTotal'] as double;
        countActive = stats['countActive'] as int;
        balActive = stats['balActive'] as double;
        countArchived = stats['countArchived'] as int;
        balArchived = stats['balArchived'] as double;
      });
    }
  }

  Future<void> _loadActiveCustomers() async {
    setState(() => _isFirstLoadRunning = true);
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
  }

  Future<void> _loadArchivedCustomers() async {
    final result = await _customersRepository.getArchivedCustomers();
    setState(() => archivedCustomers = result);
  }

  Future<bool> _isPhoneUnique(String phone, {int? excludeId}) async {
    return await _customersRepository.isPhoneUnique(phone, excludeId: excludeId);
  }

  Future<bool> _canDelete(int id, double balance) async {
    if (balance != 0) return false;
    return true; 
  }

  // --- LEDGER LOGIC (GROUPED) ---

  Future<void> _openLedger(Customer customer) async {
    setState(() {
      _selectedCustomerForLedger = customer;
      _showLedgerOverlay = true;
      _currentLedger = []; 
    });
    
    try {
      // ✅ Using the Grouped Logic
      final ledgerData = await _customersRepository.getCustomerLedgerGrouped(customer.id!);
      setState(() => _currentLedger = ledgerData);
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }
  }

  Future<void> _addPayment(double amount, String notes) async {
    if (_selectedCustomerForLedger == null) return;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await _customersRepository.addPayment(_selectedCustomerForLedger!.id!, amount, date, notes);
    await _refreshData(); 
    await _openLedger(_selectedCustomerForLedger!); 
  }
  
  Future<void> _exportLedgerPdf(AppLocalizations loc) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final customerName = _selectedCustomerForLedger?.nameEnglish ?? 'Customer';

    // Fonts
    final font = isUrdu ? await PdfGoogleFonts.notoSansArabicRegular() : await PdfGoogleFonts.notoSansRegular();
    final doc = pw.Document();

    // Headers
    final headers = isUrdu 
      ? ['تاریخ', 'تفصیل', 'Udhar (Dr)', 'Jama (Cr)', 'بیلنس']
      : ['Date', 'Description', 'Bill Amt (Dr)', 'Received (Cr)', 'Balance'];

    // Data Preparation (Flattening for PDF)
    final data = _currentLedger.map((row) {
      final date = row['date'].toString().substring(0, 10);
      final desc = row['type'] == 'BILL' ? "Bill #${row['bill_no']}" : "Payment / Recovery";
      
      return [
        date,
        desc, // Simplified description for PDF
        row['dr'] > 0 ? row['dr'].toString() : '-',
        row['cr'] > 0 ? row['cr'].toString() : '-',
        row['balance'].toStringAsFixed(0),
      ];
    }).toList();

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font).copyWith(textAlign: pw.TextAlign.start),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(isUrdu ? "$customerName :لیجر" : "Ledger: $customerName", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd-MM-yyyy').format(DateTime.now())),
                  ],
                )
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(colorScheme.primary.value)),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                }
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  // --- ACTIONS ---

  Future<void> _addOrUpdateCustomer({
    required int? id,
    required String nameEng,
    required String nameUrdu,
    required String phone,
    required String address,
    required double limit,
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
      creditLimit: limit.toInt(),
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

  Future<void> _deleteCustomer(int id, double balance) async {
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
          Expanded(child: _buildKpiCard(loc, loc.dashboardTotal, countTotal, balTotal, null)),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard(loc, loc.dashboardActive, countActive, balActive, null)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(loc, loc.dashboardArchived, countArchived, balArchived, () { 
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

  Widget _buildKpiCard(AppLocalizations loc, String title, int count, double amount, VoidCallback? onTap, {bool isOrange = false}) {
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
              child: Text("${loc.balanceShort}: ${amount.toStringAsFixed(0)}", style: TextStyle(color: contentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, {bool isOverlay = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double balance = customer.outstandingBalance.toDouble();
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
        subtitle: Text(phone, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (balance != 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: balance > 0 ? colorScheme.errorContainer : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: balance > 0 ? colorScheme.error : colorScheme.primary)
                ),
                child: Text(balance.toStringAsFixed(0), style: TextStyle(color: balance > 0 ? colorScheme.error : colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  if (value == 'delete') _deleteCustomer(customer.id!, balance);
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
    final colorScheme = Theme.of(context).colorScheme;
    final customer = _selectedCustomerForLedger!;
    final name = customer.nameEnglish;
    
    // Calculate Totals for Header
    double totalDr = 0;
    double totalCr = 0;
    for(var row in _currentLedger) {
      totalDr += (row['dr'] as num).toDouble();
      totalCr += (row['cr'] as num).toDouble();
    }
    double netBalance = totalDr - totalCr;

    return Stack(
      children: [
        GestureDetector(onTap: () => setState(() => _showLedgerOverlay = false), child: Container(color: colorScheme.shadow.withOpacity(0.5))),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.90, 
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: colorScheme.surface, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline, width: 2), 
            ),
            child: Column(
              children: [
                // Header (Totals)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          Row(
                            children: [
                              IconButton(icon: Icon(Icons.print, color: colorScheme.primary), onPressed: () => _exportLedgerPdf(loc), tooltip: "Export PDF"),
                              IconButton(icon: Icon(Icons.close, color: colorScheme.onSurface), onPressed: () => setState(() => _showLedgerOverlay = false)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildSummaryBox("Bill Amount", totalDr, colorScheme.tertiary),
                          const SizedBox(width: 8),
                          _buildSummaryBox("Received", totalCr, colorScheme.primary),
                          const SizedBox(width: 8),
                          _buildSummaryBox("Net Balance", netBalance, netBalance > 0 ? colorScheme.error : colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: colorScheme.outlineVariant),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: colorScheme.primary, 
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text("Date / Details", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimary))),
                      Expanded(flex: 2, child: Text("Bill Amt", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimary))),
                      Expanded(flex: 2, child: Text("Recvd", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimary))),
                      Expanded(flex: 2, child: Text("Bal", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer))),
                    ],
                  ),
                ),

                // Transaction List (Grouped)
                Expanded(
                  child: _currentLedger.isEmpty
                      ? Center(child: Text("No transactions found", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                      : ListView.separated(
                          itemCount: _currentLedger.length,
                          separatorBuilder: (c, i) => Divider(height: 1, color: colorScheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final row = _currentLedger[index];
                            final isPayment = row['type'] == 'PAYMENT';
                            final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
                            final dateStr = DateFormat('dd-MM-yy').format(date);
                            final balance = (row['balance'] as num).toDouble();
                            
                            // 1. PAYMENT ROW
                            if (isPayment) {
                              return Container(
                                color: colorScheme.primaryContainer.withOpacity(0.3), 
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3, 
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                          Text("PAYMENT / RECOVERY", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13)),
                                          if(row['desc'] != null && row['desc'] != '')
                                            Text(row['desc'], style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
                                        ],
                                      )
                                    ),
                                    const Expanded(flex: 2, child: Text("-", textAlign: TextAlign.right)),
                                    Expanded(flex: 2, child: Text(row['cr'].toString(), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary))),
                                    Expanded(flex: 2, child: Text(balance.toStringAsFixed(0), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                                  ],
                                ),
                              );
                            } 
                            // 2. BILL ROW (Expandable)
                            else {
                              final items = row['items'] as List<dynamic>;
                              return ExpansionTile(
                                backgroundColor: colorScheme.surface,
                                collapsedBackgroundColor: colorScheme.surface,
                                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      flex: 3, 
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                          Text("BILL #${row['bill_no']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
                                        ],
                                      )
                                    ),
                                    Expanded(flex: 2, child: Text(row['dr'].toString(), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error))),
                                    const Expanded(flex: 2, child: Text("-", textAlign: TextAlign.right)), 
                                    Expanded(flex: 2, child: Text(balance.toStringAsFixed(0), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                                  ],
                                ),
                                children: [
                                  Container(
                                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        const Row(children: [
                                          Expanded(flex: 4, child: Text("Item Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text("Rate x Qty", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                        ]),
                                        const Divider(),
                                        ...items.map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(children: [
                                            Expanded(flex: 4, child: Text(item['name'], style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
                                            Expanded(flex: 2, child: Text("${item['rate']} x ${item['qty']}", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
                                            Expanded(flex: 2, child: Text("${item['total']}", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: colorScheme.onSurface))),
                                          ]),
                                        ))
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }
                          },
                        ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(10),
                  color: colorScheme.surface,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.attach_money, color: colorScheme.onPrimary),
                      label: Text("Receive Payment", style: TextStyle(color: colorScheme.onPrimary, fontSize: 16)),
                      onPressed: _showPaymentDialog,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper for Top Stats
  Widget _buildSummaryBox(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(child: Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
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
                 double amount = double.tryParse(amountCtrl.text) ?? 0.0;
                 if(amount > 0) {
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
                      TextFormField(controller: nameEnController, decoration: _cleanInput("${loc.nameEnglish} *", Icons.person), style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      // ✅ FIXED: Removed TextDirection.rtl
                      TextFormField(controller: nameUrController, textAlign: TextAlign.start, decoration: _cleanInput("${loc.nameUrdu} *", Icons.translate), style: TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 18, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      TextFormField(controller: phoneController, decoration: _cleanInput("${loc.phoneLabel} *", Icons.phone), keyboardType: TextInputType.phone, style: TextStyle(color: colorScheme.onSurface)),
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
                         limit: double.tryParse(limitController.text) ?? 0.0
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