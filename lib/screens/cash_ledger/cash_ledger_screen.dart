import 'package:flutter/material.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  List<Map<String, dynamic>> ledgerEntries = [
    {
      'id': 1,
      'date': '2025-12-01',
      'time': '10:30 AM',
      'description': 'روزانہ کیش ان',
      'type': 'انکم',
      'amount': 15000.0,
      'balance': 35000.0,
      'remarks': 'شاپ سے جمع',
    },
    {
      'id': 2,
      'date': '2025-12-01',
      'time': '11:15 AM',
      'description': 'سپلائر کو ادائیگی',
      'type': 'اخراج',
      'amount': 5000.0,
      'balance': 30000.0,
      'remarks': 'علی ڈیپو',
    },
    {
      'id': 3,
      'date': '2025-12-01',
      'time': '02:45 PM',
      'description': 'گاہک سے وصولی',
      'type': 'انکم',
      'amount': 3200.0,
      'balance': 33200.0,
      'remarks': 'علی خان',
    },
    {
      'id': 4,
      'date': '2025-12-01',
      'time': '05:00 PM',
      'description': 'بجلی کا بل',
      'type': 'اخراج',
      'amount': 2500.0,
      'balance': 30700.0,
      'remarks': 'LESCO بل نمبر 445',
    },
  ];

  double openingBalance = 20000.0;
  double closingBalance = 30700.0;
  double totalIncome = 18200.0;
  double totalExpense = 7500.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کیش لیجر'),
        backgroundColor: Colors.deepOrange[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLedger,
            tooltip: 'ایکسپورٹ',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printLedger,
            tooltip: 'پرنٹ',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'شروع تاریخ',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('سے'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'اختتام تاریخ',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('فلٹر'),
                  ),
                ],
              ),
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'شروعاتی بیلنس',
                    'Rs ${openingBalance.toStringAsFixed(0)}',
                    Colors.blue,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'کل انکم',
                    'Rs ${totalIncome.toStringAsFixed(0)}',
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'کل اخراج',
                    'Rs ${totalExpense.toStringAsFixed(0)}',
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'اختتامی بیلنس',
                    'Rs ${closingBalance.toStringAsFixed(0)}',
                    Colors.purple,
                    Icons.account_balance,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ledger Entries
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('تفصیل')),
                          Expanded(child: Text('وقت')),
                          Expanded(child: Text('قسم')),
                          Expanded(child: Text('رقم')),
                          Expanded(child: Text('بیلنس')),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ledgerEntries.isEmpty
                          ? const Center(
                              child: Text('کوئی اندراج نہیں'),
                            )
                          : ListView.builder(
                              itemCount: ledgerEntries.length,
                              itemBuilder: (context, index) {
                                final entry = ledgerEntries[index];
                                final isIncome = entry['type'] == 'انکم';
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Description
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry['description'],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                entry['remarks'],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Time
                                        Expanded(
                                          child: Text(entry['time']),
                                        ),

                                        // Type
                                        Expanded(
                                          child: Chip(
                                            label: Text(entry['type']),
                                            backgroundColor: isIncome
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        // Amount
                                        Expanded(
                                          child: Text(
                                            'Rs ${entry['amount']?.toStringAsFixed(0) ?? "0"}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),

                                        // Balance
                                        Expanded(
                                          child: Text(
                                            'Rs ${entry['balance']?.toStringAsFixed(0) ?? "0"}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
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
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('نیا کیش ان'),
                    onPressed: _addCashIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('نیا کیش آؤٹ'),
                    onPressed: _addCashOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _addCashIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نیا کیش ان'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'رقم'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'تفصیل'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'ریمارکس'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save logic
              Navigator.pop(context);
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  void _addCashOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نیا کیش آؤٹ'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'رقم'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'تفصیل'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'ریمارکس'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save logic
              Navigator.pop(context);
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  void _exportLedger() {
    // Export to PDF/Excel
  }

  void _printLedger() {
    // Print ledger
  }
}