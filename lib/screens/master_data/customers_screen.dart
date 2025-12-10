// lib/screens/customers/customer_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

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
    // We use SUM() to avoid fetching all archived rows just for the total
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
    setState(() {
      customers = activeResult;
      filteredCustomers = activeResult;
      
      totalCustomers = activeResult.length;
      totalArchived = archivedCount;
      
      // Breakdown
      activeOutstanding = activeBal;
      archivedOutstanding = archivedBal;
      totalOutstanding = activeBal + archivedBal; // The Grand Total
    });
  }

  // Updated Archive Logic with Warning
  Future<void> _archiveCustomer(int id, String name, bool isArchiving, double balance) async {
    String actionWord = isArchiving ? 'Archive' : 'Restore';
    
    // Custom Warning Message
    Widget content;
    if (isArchiving && balance != 0) {
      content = Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'This customer still owes '),
            TextSpan(
              text: 'RS ${balance.toStringAsFixed(0)}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)
            ),
            const TextSpan(text: '.\n\nArchiving them will hide them, but the debt will '),
            const TextSpan(text: 'REMAIN ', style: TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: 'in your total business receivables.'),
          ]
        )
      );
    } else {
      content = Text('Do you want to $actionWord this customer?');
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$actionWord Customer?'),
        content: content,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(actionWord,
                  style: const TextStyle(color: Colors.green))),
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
      _loadCustomers();

      // Logic for refreshing Archive Dialog if we are restoring
      if (!isArchiving) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close the stale archive list
          _showArchivedListDialog(); // Open fresh archive list
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer $actionWord Successful')));
    }
  }

  Future<void> _addCustomer(String nameEng, String nameUrdu, String phone, String address, double limit) async {
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
      _loadCustomers(); // Refresh list
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer Added Successfully'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateCustomer(
      int id, String phone, String address, double limit) async {
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
      _loadCustomers();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Customer Updated Successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteCustomer(int id, String name, double balance) async {
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
      if (mounted) Navigator.pop(context); 
      
      String reason = "";
      if (saleCount > 0) reason += "• Has $saleCount sales records.\n";
      if (hasMoneyInvolved) reason += "• Balance is not 0 (RS ${balance.toStringAsFixed(0)}).";

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cannot Delete"),
          content: Text(
            "Customer '$name' cannot be deleted because:\n\n"
            "$reason\n\n"
            "Deleting them would corrupt your financial reports.\n"
            "Please 'Archive' them instead."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("OK")
            )
          ],
        ),
      );
    } else {
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Customer?"),
          content: Text(
            "Are you sure you want to permanently delete '$name'?\n\n"
            "This action cannot be undone."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: const Text("Cancel")
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text("Delete", style: TextStyle(color: Colors.red))
            ),
          ],
        ),
      );

      if (confirm == true) {
        await db.delete('customers', where: 'id = ?', whereArgs: [id]);
        
        if (mounted) {
           Navigator.pop(context); // Close Edit Dialog
           _loadCustomers(); // Refresh list
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Customer deleted successfully'), 
               backgroundColor: Colors.red
             )
           );
        }
      }
    }
  }

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

  // --- Dialogs ---

  Future<void> _showArchivedListDialog() async {
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

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        
        return AlertDialog(
          title: const Text("Archived Customers"),
          contentPadding: const EdgeInsets.all(10),
          content: SizedBox(
            width: size.width * 0.9,
            height: size.height * 0.7, // Slightly taller to fit header
            child: Column(
              children: [
                // Header showing Total Archived Debt
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
                      Text("Total Archived Outstanding", style: TextStyle(fontSize: 12, color: Colors.grey[800])),
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
                    ? const Center(child: Text("No archived customers."))
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
                child: const Text("Close")),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    final nameEngCtrl = TextEditingController();
    final nameUrduCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEngCtrl,
                decoration: const InputDecoration(labelText: 'Name (English) *', prefixIcon: Icon(Icons.person)),
              ),
              TextField(
                controller: nameUrduCtrl,
                decoration: const InputDecoration(labelText: 'Name (Urdu)', prefixIcon: Icon(Icons.translate)),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
              ),
              TextField(
                controller: creditLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text("RS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameEngCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name (English) is required')));
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> customer) {
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
            const Text('Edit Customer'),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: "Delete Customer",
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
                    decoration: const InputDecoration(labelText: 'Name (English)', contentPadding: EdgeInsets.all(10), border: InputBorder.none),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: nameUrduCtrl,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Name (Urdu)', contentPadding: EdgeInsets.all(10), border: InputBorder.none),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone, size: 18)),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on, size: 18)),
              ),
              TextField(
                controller: creditLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Text("RS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateCustomer(
                  customer['id'] as int,
                  phoneCtrl.text,
                  addressCtrl.text,
                  double.tryParse(creditLimitCtrl.text) ?? 0.0);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, {bool isArchived = false}) {
    String nameUrdu = customer['name_urdu']?.toString() ?? '';
    String nameEnglish = customer['name_english']?.toString() ?? '';
    String displayName = (nameUrdu.isNotEmpty) ? nameUrdu : nameEnglish;

    String address = customer['address']?.toString() ?? 'No Address';
    String phone = customer['contact_primary']?.toString() ?? 'No Phone';
    String limit = (customer['credit_limit'] ?? 0).toString();

    String details = "$nameEnglish | $phone | $address | Limit: $limit";
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
                    // Update Archive Call to pass name and balance
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.green[700],
        elevation: 0,
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
                    'Active',
                    totalCustomers.toString(),
                    Icons.people,
                    Colors.white,
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    'Receivable',
                    totalOutstanding.toStringAsFixed(0), // Grand Total
                    Icons.account_balance_wallet,
                    Colors.white,
                    // Pass the breakdown string here
                    subtitle: "Active: ${activeOutstanding.toStringAsFixed(0)} + Archived: ${archivedOutstanding.toStringAsFixed(0)}",
                    onTap: null),
                const SizedBox(width: 8),
                _buildSummaryCard(
                    'Archived',
                    totalArchived.toString(),
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
              onChanged: _filterList,
              decoration: InputDecoration(
                hintText: 'Search by Name or Phone...',
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
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white), // This connects the button to your function!
      ),
    );
  }

  // Helper for Summary Cards (Updated for Subtitle)
  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color bg,
      {VoidCallback? onTap, String? subtitle}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: onTap != null ? bg : Colors.white.withOpacity(0.9),
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
                              color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis)),
                  Icon(icon, size: 14, color: Colors.grey[800]),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Show subtitle if provided (for Receivable breakdown)
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey[800]),
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
}