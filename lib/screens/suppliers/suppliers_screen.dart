// lib/screens/master_data/suppliers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  // Pagination State
  List<Map<String, dynamic>> suppliers = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;
  double _totalPayable = 0.0;

  // Ledger State
  bool _showLedgerOverlay = false;
  List<Map<String, dynamic>> _currentLedger = [];
  Map<String, dynamic>? _selectedSupplierForLedger;

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
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('SELECT SUM(outstanding_balance) as total FROM suppliers');
      if (mounted) {
        setState(() {
          _totalPayable = (result.first['total'] as num?)?.toDouble() ?? 0.0;
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
      final db = await DatabaseHelper.instance.database;
      final query = searchController.text.trim();
      
      List<Map<String, dynamic>> result;
      
      if (query.isNotEmpty) {
        result = await db.query(
          'suppliers',
          where: 'name_english LIKE ? OR name_urdu LIKE ? OR contact_primary LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      } else {
        result = await db.query(
          'suppliers',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      }

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
      final db = await DatabaseHelper.instance.database;
      final query = searchController.text.trim();
      _page++;
      final offset = _page * _limit;

      List<Map<String, dynamic>> result;
      
      if (query.isNotEmpty) {
        result = await db.query(
          'suppliers',
          where: 'name_english LIKE ? OR name_urdu LIKE ? OR contact_primary LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      } else {
        result = await db.query(
          'suppliers',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      }

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

  Future<void> _refreshList() async {
    await _firstLoad();
    await _loadStats();
  }

  // --- Ledger Logic ---

  Future<void> _openLedger(Map<String, dynamic> supplier) async {
    setState(() {
      _selectedSupplierForLedger = supplier;
      _showLedgerOverlay = true;
      _currentLedger = [];
    });
    
    await _getSupplierLedger(supplier['id']);
  }

  Future<void> _getSupplierLedger(int supplierId) async {
    // Fetch ledger data (Purchases and Payments)
    // Assuming tables 'purchases' and 'supplier_payments' exist or similar logic
    try {
      final db = await DatabaseHelper.instance.database;
      
      // 1. Fetch Purchases (Bills) - Liability Increases (Credit in Supplier Account)
      // Note: If 'purchases' table doesn't exist yet, this try-catch will handle it.
      // We use a safe query approach.
      List<Map<String, dynamic>> purchases = [];
      try {
        purchases = await db.rawQuery('''
          SELECT 
            'BILL' as type,
            id as ref_id,
            purchase_date as date,
            invoice_number as bill_no,
            total_amount as cr, -- We owe them (Credit)
            0 as dr,
            'Purchase' as desc
          FROM purchases 
          WHERE supplier_id = ?
        ''', [supplierId]);
      } catch (e) {
        // Table might not exist yet
        debugPrint('Purchases table query failed: $e');
      }

      // 2. Fetch Payments - Liability Decreases (Debit in Supplier Account)
      List<Map<String, dynamic>> payments = [];
      try {
        payments = await db.rawQuery('''
          SELECT 
            'PAYMENT' as type,
            id as ref_id,
            payment_date as date,
            'Payment Sent' as bill_no,
            0 as cr,
            amount as dr, -- We paid them (Debit)
            notes as desc
          FROM supplier_payments
          WHERE supplier_id = ?
        ''', [supplierId]);
      } catch (e) {
        debugPrint('Supplier payments table query failed: $e');
      }

      // Combine
      List<Map<String, dynamic>> timeline = [...purchases, ...payments];

      // Sort by Date
      timeline.sort((a, b) {
        DateTime dA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1900);
        DateTime dB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1900);
        return dA.compareTo(dB);
      });

      // Calculate Running Balance
      double runningBal = 0.0;
      List<Map<String, dynamic>> finalLedger = [];

      for (var row in timeline) {
        double cr = (row['cr'] as num).toDouble(); // Bill
        double dr = (row['dr'] as num).toDouble(); // Payment
        runningBal += (cr - dr); // Payable Balance

        Map<String, dynamic> newRow = Map.from(row);
        newRow['balance'] = runningBal;
        finalLedger.add(newRow);
      }

      if (mounted) {
        setState(() {
          _currentLedger = finalLedger.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }
  }

  Future<void> _addPayment(int supplierId, double amount, String notes) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        // 1. Record Payment
        // Check if supplier_payments table exists, if not create it or skip
        // For this implementation, we assume it exists or we just update balance
        try {
          await txn.insert('supplier_payments', {
            'supplier_id': supplierId,
            'amount': amount,
            'payment_date': DateTime.now().toIso8601String(),
            'notes': notes,
          });
        } catch (e) {
          // Table might not exist, proceed to update balance
          debugPrint('supplier_payments insert failed: $e');
        }

        // 2. Update Supplier Balance (Decrease outstanding balance)
        await txn.rawUpdate(
          'UPDATE suppliers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
          [amount, supplierId]
        );
      });
    } catch (e) {
      debugPrint('Error adding payment: $e');
    }
    await _refreshList();
    if (_selectedSupplierForLedger != null) {
      await _getSupplierLedger(supplierId);
    }
  }

  Future<void> _exportLedgerPdf(AppLocalizations loc) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    // ignore: unused_local_variable
    final supplierName = _selectedSupplierForLedger?['name_english'] ?? 'Supplier';

    final font = isUrdu ? await PdfGoogleFonts.notoSansArabicRegular() : await PdfGoogleFonts.notoSansRegular();
    final doc = pw.Document();

    final headers = ['Date', 'Description', 'Bill (Cr)', 'Paid (Dr)', 'Balance'];
    final data = _currentLedger.map((row) {
      final date = row['date'].toString().substring(0, 10);
      return [
        date,
        row['desc'] ?? '',
        row['cr'] > 0 ? row['cr'].toString() : '-',
        row['dr'] > 0 ? row['dr'].toString() : '-',
        row['balance'].toStringAsFixed(0),
      ];
    }).toList();

    doc.addPage(pw.Page(
      theme: pw.ThemeData.withFont(base: font),
      build: (pw.Context context) => pw.Table.fromTextArray(
        context: context, headers: headers, data: data,
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(colorScheme.tertiary.value)),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // --- CRUD Operations ---

  Future<void> _addSupplier(String nameEng, String nameUrdu, String phone, String address, double balance) async {
    final loc = AppLocalizations.of(context)!;
    if (nameEng.isEmpty) return;

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('suppliers', {
        'name_english': nameEng,
        'name_urdu': nameUrdu,
        'contact_primary': phone,
        'address': address,
        'outstanding_balance': balance,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _refreshList(); // Reload list to show new item
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierAdded), backgroundColor: Theme.of(context).colorScheme.tertiary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _updateSupplier(int id, String nameEng, String nameUrdu, String phone, String address, double balance) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'suppliers',
        {
          'name_english': nameEng,
          'name_urdu': nameUrdu,
          'contact_primary': phone,
          'address': address,
          'outstanding_balance': balance,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (!mounted) return;
      Navigator.pop(context);
      _refreshList(); // Reload list
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierUpdated), backgroundColor: Theme.of(context).colorScheme.tertiary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _deleteSupplier(int id) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
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
        final db = await DatabaseHelper.instance.database;
        await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
        
        if (!mounted) return;
        _refreshList(); // Reload list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierDeleted), backgroundColor: colorScheme.error));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  void _showSupplierDialog({Map<String, dynamic>? supplier}) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = supplier != null;

    final nameEngCtrl = TextEditingController(text: supplier?['name_english']);
    final nameUrduCtrl = TextEditingController(text: supplier?['name_urdu']);
    final phoneCtrl = TextEditingController(text: supplier?['contact_primary']);
    final addressCtrl = TextEditingController(text: supplier?['address']);
    final balanceCtrl = TextEditingController(text: supplier?['outstanding_balance']?.toString() ?? '0');

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
              final balance = double.tryParse(balanceCtrl.text) ?? 0.0;
              if (isEdit) {
                _updateSupplier(
                  supplier['id'], 
                  nameEngCtrl.text, 
                  nameUrduCtrl.text, 
                  phoneCtrl.text, 
                  addressCtrl.text,
                  balance
                );
              } else {
                _addSupplier(
                  nameEngCtrl.text, 
                  nameUrduCtrl.text, 
                  phoneCtrl.text, 
                  addressCtrl.text,
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.tertiary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(loc.suppliersManagement, style: TextStyle(color: colorScheme.onTertiary)),
            backgroundColor: colorScheme.tertiary,
            iconTheme: IconThemeData(color: colorScheme.onTertiary),
          ),
          body: Column(
            children: [
              // KPI Card
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Card(
                  color: colorScheme.tertiaryContainer,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.total, style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold)),
                            Text(loc.balance, style: TextStyle(color: colorScheme.onTertiaryContainer, fontSize: 12)),
                          ],
                        ),
                        Text(
                          'Rs ${_totalPayable.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onTertiaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) => _firstLoad(),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: loc.search,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                    filled: true, fillColor: colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              
              // List
              Expanded(
                child: _isFirstLoadRunning
                  ? Center(child: CircularProgressIndicator(color: colorScheme.tertiary))
                  : suppliers.isEmpty
                      ? Center(child: Text(loc.noSuppliersFound, style: TextStyle(color: colorScheme.onSurface)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(10),
                                itemCount: suppliers.length,
                                itemBuilder: (context, index) {
                                  final supplier = suppliers[index];
                                  return _buildSupplierCard(supplier, colorScheme, loc);
                                },
                              ),
                            ),
                            if (_isLoadMoreRunning)
                               Padding(
                                 padding: const EdgeInsets.all(8.0),
                                 child: Center(child: CircularProgressIndicator(color: colorScheme.tertiary)),
                               ),
                          ],
                        ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showSupplierDialog(),
            backgroundColor: colorScheme.tertiary,
            child: Icon(Icons.add, color: colorScheme.onTertiary),
          ),
        ),
        
        if (_showLedgerOverlay) _buildLedgerOverlay(loc),
      ],
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier, ColorScheme colorScheme, AppLocalizations loc) {
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.tertiaryContainer,
          child: Icon(Icons.business, color: colorScheme.onTertiaryContainer),
        ),
        title: Text(
          supplier['name_urdu'] ?? supplier['name_english'] ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.phoneNum}: ${supplier['contact_primary'] ?? '-'}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            Text('${loc.balance}: ${supplier['outstanding_balance'] ?? 0}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.receipt_long, color: colorScheme.tertiary),
              tooltip: "View Ledger",
              onPressed: () => _openLedger(supplier),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.secondary),
              onPressed: () => _showSupplierDialog(supplier: supplier),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error),
              onPressed: () => _deleteSupplier(supplier['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final supplier = _selectedSupplierForLedger!;
    final name = supplier['name_english'] ?? 'Supplier';
    
    double totalCr = 0; // Bills (We owe)
    double totalDr = 0; // Payments (We paid)
    for(var row in _currentLedger) {
      totalCr += (row['cr'] as num).toDouble();
      totalDr += (row['dr'] as num).toDouble();
    }
    double netBalance = totalCr - totalDr;

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
                // Header
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
                              IconButton(icon: Icon(Icons.print, color: colorScheme.tertiary), onPressed: () => _exportLedgerPdf(loc), tooltip: "Export PDF"),
                              IconButton(icon: Icon(Icons.close, color: colorScheme.onSurface), onPressed: () => setState(() => _showLedgerOverlay = false)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildSummaryBox("Bill Amount", totalCr, colorScheme.error),
                          const SizedBox(width: 8),
                          _buildSummaryBox("Paid", totalDr, colorScheme.primary),
                          const SizedBox(width: 8),
                          _buildSummaryBox("Net Balance", netBalance, colorScheme.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: colorScheme.tertiary, 
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text("Date / Details", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onTertiary))),
                      Expanded(flex: 2, child: Text("Bill (Cr)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onTertiary))),
                      Expanded(flex: 2, child: Text("Paid (Dr)", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onTertiary))),
                      Expanded(flex: 2, child: Text("Bal", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onTertiaryContainer))),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _currentLedger.isEmpty
                      ? Center(child: Text("No transactions found", style: TextStyle(color: colorScheme.onSurfaceVariant)))
                      : ListView.separated(
                          itemCount: _currentLedger.length,
                          separatorBuilder: (c, i) => Divider(height: 1, color: colorScheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final row = _currentLedger[index];
                            final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
                            final dateStr = DateFormat('dd-MM-yy').format(date);
                            final balance = (row['balance'] as num).toDouble();
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3, 
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                        Text(row['desc'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 13)),
                                      ],
                                    )
                                  ),
                                  Expanded(flex: 2, child: Text(row['cr'] > 0 ? row['cr'].toString() : '-', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error))),
                                  Expanded(flex: 2, child: Text(row['dr'] > 0 ? row['dr'].toString() : '-', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary))),
                                  Expanded(flex: 2, child: Text(balance.toStringAsFixed(0), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                
                // Footer Action
                Container(
                  padding: const EdgeInsets.all(10),
                  color: colorScheme.surface,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment, color: colorScheme.onTertiary),
                      label: Text("Add Payment", style: TextStyle(color: colorScheme.onTertiary, fontSize: 16)),
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
        title: Text("Add Payment", style: TextStyle(color: colorScheme.onSurface)),
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
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amount > 0) {
                  Navigator.pop(context);
                  _addPayment(_selectedSupplierForLedger!['id'], amount, notesCtrl.text);
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