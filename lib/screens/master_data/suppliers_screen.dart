// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('suppliers', orderBy: 'name_english ASC');
      
      if (!mounted) return;
      setState(() {
        suppliers = result;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
      _loadSuppliers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierAdded), backgroundColor: Colors.green));
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
      _loadSuppliers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierUpdated), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
    }
  }

  Future<void> _deleteSupplier(int id) async {
    final loc = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirm),
        content: Text(loc.confirmDeleteSupplier),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.yesDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
        
        if (!mounted) return;
        _loadSuppliers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.supplierDeleted), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error}: $e')));
      }
    }
  }

  void _showSupplierDialog({Map<String, dynamic>? supplier}) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = supplier != null;

    final nameEngCtrl = TextEditingController(text: supplier?['name_english']);
    final nameUrduCtrl = TextEditingController(text: supplier?['name_urdu']);
    final phoneCtrl = TextEditingController(text: supplier?['contact_primary']);
    final addressCtrl = TextEditingController(text: supplier?['address']);
    final balanceCtrl = TextEditingController(text: supplier?['outstanding_balance']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? loc.editSupplier : loc.addSupplier),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEngCtrl,
                decoration: InputDecoration(labelText: loc.nameEnglish, prefixIcon: const Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameUrduCtrl,
                decoration: InputDecoration(labelText: loc.nameUrdu, prefixIcon: const Icon(Icons.translate)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: loc.phoneNum, prefixIcon: const Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: loc.address, prefixIcon: const Icon(Icons.location_on)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.balance, prefixIcon: const Icon(Icons.account_balance_wallet)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.suppliersManagement),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? Center(child: Text(loc.noSuppliersFound))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: Text(
                          supplier['name_urdu'] ?? supplier['name_english'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${loc.phoneNum}: ${supplier['contact_primary'] ?? '-'}'),
                            Text('${loc.balance}: ${supplier['outstanding_balance'] ?? 0}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSupplierDialog(supplier: supplier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSupplier(supplier['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}