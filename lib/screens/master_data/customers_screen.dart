// lib/screens/master_data/customers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // Pagination & List State
  List<Map<String, dynamic>> customers = [];
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;
  
  late ScrollController _scrollController;
  final TextEditingController searchController = TextEditingController();

  // Summary Variables
  int totalCustomersCount = 0;
  double totalOutstanding = 0.0;     
  double activeOutstanding = 0.0;    
  double archivedOutstanding = 0.0;  
  int totalArchivedCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadStats(); // Load totals once
    _firstLoad(); // Load list
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

  // --- Database Logic: Stats ---
  // FIX: Stats must be calculated via SQL Aggregation now, 
  // because we don't load all customers into memory at once.
  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Archive Stats
    final archivedRes = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(outstanding_balance) as total_bal FROM customers WHERE is_active = 0');
    totalArchivedCount = (archivedRes.first['count'] as int?) ?? 0;
    archivedOutstanding = (archivedRes.first['total_bal'] as num? ?? 0.0).toDouble();

    // 2. Active Stats (Total Sum, independent of pagination)
    final activeRes = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(outstanding_balance) as total_bal FROM customers WHERE is_active = 1');
    totalCustomersCount = (activeRes.first['count'] as int?) ?? 0;
    activeOutstanding = (activeRes.first['total_bal'] as num? ?? 0.0).toDouble();

    totalOutstanding = activeOutstanding + archivedOutstanding;
    
    if (mounted) setState(() {});
  }

  // --- Database Logic: Pagination ---

  Future<void> _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 0;
      _hasNextPage = true;
      customers = [];
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final query = searchController.text.trim();
      
      List<Map<String, dynamic>> result;
      
      if (query.isNotEmpty) {
         // Search active customers
         result = await db.query(
          'customers',
          where: '(name_english LIKE ? OR name_urdu LIKE ? OR contact_primary LIKE ?) AND is_active = 1',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      } else {
        // Standard List
        result = await db.query(
          'customers',
          where: 'is_active = 1',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: 0,
        );
      }

      if (!mounted) return;
      setState(() {
        customers = result;
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
          'customers',
          where: '(name_english LIKE ? OR name_urdu LIKE ? OR contact_primary LIKE ?) AND is_active = 1',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      } else {
        result = await db.query(
          'customers',
          where: 'is_active = 1',
          orderBy: 'name_english ASC',
          limit: _limit,
          offset: offset,
        );
      }

      if (!mounted) return;
      setState(() {
        if (result.isNotEmpty) {
          customers.addAll(result);
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

  // --- CRUD Wrappers (Refresh Logic Updated) ---

  Future<void> _refreshData() async {
    await _loadStats();
    await _firstLoad();
  }

  // ... [Keep _addCustomer, _updateCustomer, _deleteCustomer, _archiveCustomer same logic but CALL _refreshData() at end] ...

  Future<void> _addCustomer(String nameEng, String nameUrdu, String phone, String address, double limit) async {
    final loc = AppLocalizations.of(context)!;
    if (nameEng.isEmpty) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('customers', {
        'name_english': nameEng,
        'name_urdu': nameUrdu,
        'contact_primary': phone,
        'address': address,
        'credit_limit': limit,
        'outstanding_balance': 0.0,
        'is_active': 1,
      });
      if (!mounted) return;
      _refreshData(); // Updated to refresh paginated list
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.customerAddedSuccess), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }
  
  // (Assuming _updateCustomer, _deleteCustomer, _archiveCustomer are similarly updated to call _refreshData() instead of _loadCustomers())
  // Here is one example for update:
  Future<void> _updateCustomer(int id, String phone, String address, double limit) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('customers', 
        {'contact_primary': phone, 'address': address, 'credit_limit': limit},
        where: 'id = ?', whereArgs: [id]);
      if (!mounted) return;
      _refreshData();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.customerUpdatedSuccess), backgroundColor: Colors.green));
    } catch (e) { /*...*/ }
  }
  
  // ... [Dialogs _showAddDialog, _showEditDialog, _showArchivedListDialog remain similar] ...

  // Helper Wrappers (Simplified for brevity in response)
  Future<void> _archiveCustomer(int id, String name, bool isArchiving, double balance) async {
      // ... (Original logic) ...
      // On success:
      final db = await DatabaseHelper.instance.database;
      await db.update('customers', {'is_active': isArchiving ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
      if(mounted) _refreshData();
      // ...
  }
  
  Future<void> _deleteCustomer(int id, String name, double balance) async {
       // ... (Original logic) ...
       // On success:
       final db = await DatabaseHelper.instance.database;
       await db.delete('customers', where: 'id = ?', whereArgs: [id]);
       if(mounted) {
         Navigator.pop(context);
         _refreshData();
       }
       // ...
  }

  // ... [_showArchivedListDialog, _buildCustomerCard, _buildSummaryCard remain unchanged] ...
  
  // Include helper methods from original code here... 
  // (Use provided code for _showArchivedListDialog, _buildCustomerCard, _buildSummaryCard)
  // Just ensure _buildCustomerCard uses 'customers' list which is now correct.

  Widget _buildCustomerCard(Map<String, dynamic> customer, {bool isArchived = false}) {
    final loc = AppLocalizations.of(context)!;
    
    String nameUrdu = customer['name_urdu']?.toString() ?? '';
    String nameEnglish = customer['name_english']?.toString() ?? '';
    String displayName = (nameUrdu.isNotEmpty) ? nameUrdu : nameEnglish;

    String address = customer['address']?.toString() ?? loc.address;
    String phone = customer['contact_primary']?.toString() ?? loc.phone;
    String limit = (customer['credit_limit'] ?? 0).toString();

    String details = "$nameEnglish | $phone | ${loc.address}: $address | ${loc.creditLimit}: $limit";
    double balance = (customer['outstanding_balance'] as num? ?? 0.0).toDouble();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          dense: true,
          leading: CircleAvatar(
            backgroundColor: isArchived ? Colors.grey[300] : Colors.green[100],
            radius: 22,
            child: Text(
              (nameEnglish.isNotEmpty ? nameEnglish[0] : 'C').toUpperCase(),
              style: TextStyle(
                  color: isArchived ? Colors.grey[700] : Colors.green[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              details,
              style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: isArchived ? null : () => _showEditDialog(customer),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                balance.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isArchived 
                      ? Colors.grey 
                      : (balance > 0 ? Colors.red[700] : Colors.green[700])
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                    color: isArchived ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  icon: Icon(
                    isArchived ? Icons.restore : Icons.archive,
                    size: 18,
                    color: isArchived ? Colors.green : Colors.red, 
                  ),
                  onPressed: () {
                    _archiveCustomer(
                      customer['id'] as int, 
                      displayName,
                      !isArchived,
                      balance
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color bgColor, {VoidCallback? onTap, String? subtitle}) {
    final loc = AppLocalizations.of(context)!;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: onTap != null ? bgColor : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: onTap != null ? Border.all(color: Colors.white, width: 2) : null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: onTap != null ? Colors.white : Colors.grey[800]),
                          overflow: TextOverflow.ellipsis)),
                  Icon(icon, size: 14, color: onTap != null ? Colors.white : Colors.grey[800]),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onTap != null ? Colors.white : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: onTap != null ? Colors.white70 : Colors.grey[800]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
  
  // (Include _showAddDialog, _showEditDialog, _showArchivedListDialog from previous code here)
  void _showAddDialog() {
    final loc = AppLocalizations.of(context)!;
    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addNewCustomer), // Translated
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEngCtrl,
                decoration: InputDecoration(labelText: loc.nameEnglish, prefixIcon: const Icon(Icons.person)),
              ),
              TextField(
                controller: nameUrduCtrl,
                decoration: InputDecoration(labelText: loc.nameUrdu, prefixIcon: const Icon(Icons.translate)),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: loc.phoneNum, prefixIcon: const Icon(Icons.phone)),
              ),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: loc.address, prefixIcon: const Icon(Icons.location_on)),
              ),
              TextField(
                controller: creditLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: loc.creditLimit,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text("RS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)), // Translated
          ElevatedButton(
            onPressed: () {
              if (nameEngCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.customerNameRequired))); // Translated
                return;
              }
              _addCustomer(
                  nameEngCtrl.text,
                  nameUrduCtrl.text,
                  phoneCtrl.text,
                  addressCtrl.text,
                  double.tryParse(creditLimitCtrl.text) ?? 0.0
              );
            },
            child: Text(loc.save), // Translated
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> customer) {
    final loc = AppLocalizations.of(context)!;
    final nameEngCtrl = TextEditingController(text: customer['name_english']?.toString() ?? '');
    final nameUrduCtrl = TextEditingController(text: customer['name_urdu']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: customer['contact_primary']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: customer['address']?.toString() ?? '');
    final creditLimitCtrl = TextEditingController(text: customer['credit_limit']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.editCustomer), // Translated
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: loc.deleteAction,
              onPressed: () {
                double currentBalance = (customer['outstanding_balance'] as num? ?? 0.0).toDouble();
                _deleteCustomer(
                  customer['id'] as int, 
                  customer['name_english']?.toString() ?? 'Unknown',
                  currentBalance
                );
              },
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.grey[200],
                child: Column(children: [
                  TextField(
                    controller: nameEngCtrl,
                    enabled: false,
                    decoration: InputDecoration(labelText: loc.nameEnglish, contentPadding: const EdgeInsets.all(10), border: InputBorder.none),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: nameUrduCtrl,
                    enabled: false,
                    decoration: InputDecoration(labelText: loc.nameUrdu, contentPadding: const EdgeInsets.all(10), border: InputBorder.none),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: loc.phoneNum, prefixIcon: const Icon(Icons.phone, size: 18)),
              ),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: loc.address, prefixIcon: const Icon(Icons.location_on, size: 18)),
              ),
              TextField(
                controller: creditLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: loc.creditLimit,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text("RS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () {
              _updateCustomer(
                  customer['id'] as int,
                  phoneCtrl.text,
                  addressCtrl.text,
                  double.tryParse(creditLimitCtrl.text) ?? 0.0);
            },
            child: Text(loc.update),
          ),
        ],
      ),
    );
  }

  Future<void> _showArchivedListDialog() async {
    final loc = AppLocalizations.of(context)!;
    final db = await DatabaseHelper.instance.database;
    final archivedList = await db.query(
      'customers',
      where: 'is_active = ?',
      whereArgs: [0],
      orderBy: 'name_english ASC',
    );

    // Calculate total for just this list
    double archivedListTotal = 0.0;
    for(var c in archivedList) {
      archivedListTotal += (c['outstanding_balance'] as num? ?? 0.0).toDouble();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        
        return AlertDialog(
          title: Text(loc.archived),
          contentPadding: const EdgeInsets.all(10),
          content: SizedBox(
            width: size.width * 0.9,
            height: size.height * 0.7, 
            child: Column(
              children: [
                // Header showing Total Archived Debt (Translated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: [
                      Text(loc.receivableArchived, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Text(
                        "RS ${archivedListTotal.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      )
                    ],
                  ),
                ),

                // The List
                Expanded(
                  child: archivedList.isEmpty
                    ? Center(child: Text("${loc.no} ${loc.archived} ${loc.customers}.")) 
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: archivedList.length,
                        itemBuilder: (ctx, i) {
                          final customer = archivedList[i];
                          return _buildCustomerCard(customer, isArchived: true);
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)), 
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(loc.customersManagement),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white), 
            tooltip: loc.archived,
            onPressed: _showArchivedListDialog
          ),
        ]
      ),
      body: Column(
        children: [
          // 1. Summary Cards
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green[700],
            child: Row(
              children: [
                _buildSummaryCard(
                    loc.active,
                    totalCustomersCount.toString(),
                    Icons.people,
                    Colors.white,
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    loc.receivableTotal,
                    totalOutstanding.toStringAsFixed(0),
                    Icons.account_balance_wallet,
                    Colors.white,
                    subtitle: "${loc.active}: ${activeOutstanding.toStringAsFixed(0)} + ${loc.archived}: ${archivedOutstanding.toStringAsFixed(0)}",
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    loc.archived,
                    totalArchivedCount.toString(),
                    Icons.archive,
                    Colors.orange[100]!,
                    onTap: _showArchivedListDialog),
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: (val) => _firstLoad(), // Trigger search
              decoration: InputDecoration(
                hintText: loc.searchCustomerHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
          ),

          // 3. Customer List
          Expanded(
            child: _isFirstLoadRunning
            ? const Center(child: CircularProgressIndicator())
            : customers.isEmpty
              ? Center(child: Text(loc.noCustomersFound))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _buildCustomerCard(customer, isArchived: false);
                        },
                      ),
                    ),
                    if (_isLoadMoreRunning)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}