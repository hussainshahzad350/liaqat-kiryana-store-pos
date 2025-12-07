import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

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
      setState(() {
        suppliers = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading suppliers: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سپلائرز مينيجمنٹ'),
        backgroundColor: Colors.blue[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? const Center(child: Text('کوئی سپلائر نہيں ملا'))
              : ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.business, color: Colors.blue),
                        title: Text(supplier['name_english'] ?? 'نامعلوم'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('فون: ${supplier['contact_primary'] ?? 'N/A'}'),
                            Text('بیلنس: Rs ${supplier['outstanding_balance'] ?? '0'}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            // Call supplier
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add supplier
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}