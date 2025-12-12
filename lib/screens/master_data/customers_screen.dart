// lib/screens/master_data/customers_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart'; // ✅ Correct Import Path

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  final TextEditingController searchController = TextEditingController();

  // Summary Variables
  int totalCustomers = 0;
  
  // Debt Breakdown
  double totalOutstanding = 0.0;     // Grand Total
  double activeOutstanding = 0.0;    // Active Only
  double archivedOutstanding = 0.0;  // Archived Only
  
  int totalArchived = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // --- Database Logic ---
  Future<void> _loadCustomers() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch Active Customers (Detailed list for the screen)
    final activeResult = await db.query(
      'customers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name_english ASC',
    );

    // 2. Fetch Archived Summary (Count & Total Balance)
    final archivedSummary = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(outstanding_balance) as total_bal FROM customers WHERE is_active = 0');
    
    int archivedCount = (archivedSummary.first['count'] as int?) ?? 0;
    double archivedBal = (archivedSummary.first['total_bal'] as num? ?? 0.0).toDouble();

    // 3. Calculate Active Totals
    double activeBal = 0.0;
    for (var c in activeResult) {
      activeBal += (c['outstanding_balance'] as num? ?? 0.0).toDouble();
    }

    // 4. Update State
    if (!mounted) return;
    setState(() {
      customers = activeResult;
      filteredCustomers = activeResult;
      
      totalCustomers = activeResult.length;
      totalArchived = archivedCount;
      
      activeOutstanding = activeBal;
      archivedOutstanding = archivedBal;
      totalOutstanding = activeBal + archivedBal; // The Grand Total
    });
  }

  // --- Filter Logic (Linked to UI) ---
  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers.where((c) {
          final nameEng = (c['name_english'] ?? '').toString().toLowerCase();
          final nameUrdu = (c['name_urdu'] ?? '').toString();
          final phone = (c['contact_primary'] ?? '').toString();
          final q = query.toLowerCase();
          return nameEng.contains(q) || nameUrdu.contains(q) || phone.contains(q);
        }).toList();
      }
    });
  }

  // --- Core CRUD Logic (Translated) ---

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
        'outstanding_balance': 0.0, // New customers start with 0
        'is_active': 1,
      });
      
      if (!mounted) return;
      _loadCustomers(); // Refresh list
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.customerAddedSuccess), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _updateCustomer(
      int id, String phone, String address, double limit) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'customers',
        {
          'contact_primary': phone,
          'address': address,
          'credit_limit': limit,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (!mounted) return;
      _loadCustomers();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.customerUpdatedSuccess),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e'), backgroundColor: Colors.red));
    }
  }

  // FIX: Logic updated to call generated functions instead of replaceFirst
  Future<void> _deleteCustomer(int id, String name, double balance) async {
    final loc = AppLocalizations.of(context)!;
    final db = await DatabaseHelper.instance.database;

    // 1. CHECK FOR SALES HISTORY
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE customer_id = ?',
      [id]
    );
    int saleCount = (result.first['count'] as int?) ?? 0;

    // 2. CHECK FOR OUTSTANDING BALANCE
    bool hasMoneyInvolved = balance != 0;

    if (saleCount > 0 || hasMoneyInvolved) {
      if (mounted) Navigator.pop(context); // Close edit dialog
      
      String reason = "";
      // FIX: Call generated function: loc.deleteWarningSales(count)
      if (saleCount > 0) reason += "${loc.deleteWarningSales(saleCount.toString())}\n";
      if (hasMoneyInvolved) reason += "${loc.deleteWarningBalance(balance.toStringAsFixed(0))}.";

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.cannotDeleteTitle),
          content: Text(
            "${loc.customer} '$name' ${loc.cannotDeleteReason}:\n\n"
            "$reason\n\n"
            "${loc.deleteWarningReason}\n"
            "${loc.deleteWarningArchive}"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text(loc.ok)
            )
          ],
        ),
      );
    } else {
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.deleteCustomerTitle),
          // FIX: Call generated function: loc.deleteCustomerWarning(name)
          content: Text(
            "${loc.deleteCustomerWarning(name)}\n\n${loc.deleteWarningReason}"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: Text(loc.cancel)
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text(loc.deleteAction, style: const TextStyle(color: Colors.red))
            ),
          ],
        ),
      );

      if (confirm == true) {
        final db = await DatabaseHelper.instance.database;
        await db.delete('customers', where: 'id = ?', whereArgs: [id]);
        
        if (!mounted) return;
        Navigator.pop(context); // Close Edit Dialog
        _loadCustomers(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.customerDeleted), 
            backgroundColor: Colors.red
          )
        );
      }
    }
  }
  
  // Updated Archive Logic (Translated + preserving detailed logic)
  Future<void> _archiveCustomer(int id, String name, bool isArchiving, double balance) async {
    final loc = AppLocalizations.of(context)!;
    
    String actionWord = isArchiving ? loc.archiveAction : loc.restoreAction;
    String title = isArchiving ? loc.archiveCustomerTitle : loc.restoreCustomerTitle;
    
    // Custom Warning Message Content
    Widget content;
    if (isArchiving && balance != 0) {
      content = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "${loc.archiveConfirmMsg}\n\n"),
            TextSpan(text: "RS ${balance.toStringAsFixed(0)} ${loc.old} ${loc.balanceAging} ${loc.willBeArchived}.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ]
        )
      );
    } else {
      content = Text('${loc.doYouWantTo} $actionWord ${loc.thisCustomer}');
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title.replaceFirst('?', '')),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(loc.cancel)
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(actionWord, style: TextStyle(color: isArchiving ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'customers',
        {'is_active': isArchiving ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (!mounted) return;
      _loadCustomers(); // Refresh list
      
      // If restoring, close the archived list dialog
      if (!isArchiving) {
        if (Navigator.canPop(context)) { 
          Navigator.pop(context); 
          _showArchivedListDialog(); // Re-open fresh list to show restoration
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArchiving ? loc.customerArchived : loc.customerRestored)));
    }
  }

  // --- Dialogs (Translated) ---

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

  // --- Helper Widgets ---

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

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color bgColor,
      {VoidCallback? onTap, String? subtitle}) {
    // FIX: Using final loc inside build methods
    // ignore: unused_local_variable
    final loc = AppLocalizations.of(context)!;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: onTap != null ? bgColor : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: onTap != null
                  ? Border.all(color: Colors.white, width: 2)
                  : null),
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

  // FIX: This method was missing, causing the 'Missing concrete implementation' error
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // Access localization
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(loc.customersManagement), // Translated
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white), 
            tooltip: loc.archived,
            onPressed: _showArchivedListDialog // Linked to dialog
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
                    loc.active, // Translated
                    totalCustomers.toString(),
                    Icons.people,
                    Colors.white,
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    loc.receivableTotal, // Translated
                    totalOutstanding.toStringAsFixed(0),
                    Icons.account_balance_wallet,
                    Colors.white,
                    // FIX: Use translated keys for subtitle content
                    subtitle: "${loc.active}: ${activeOutstanding.toStringAsFixed(0)} + ${loc.archived}: ${archivedOutstanding.toStringAsFixed(0)}",
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    loc.archived, // Translated
                    totalArchived.toString(),
                    Icons.archive,
                    Colors.orange[100]!,
                    onTap: _showArchivedListDialog), // Linked to dialog
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: _filterList, // Linked to filter
              decoration: InputDecoration(
                hintText: loc.searchCustomerHint, // Translated
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
          ),

          // 3. Customer List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = filteredCustomers[index];
                return _buildCustomerCard(customer, isArchived: false);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: _showAddDialog, // Linked to add dialog
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}