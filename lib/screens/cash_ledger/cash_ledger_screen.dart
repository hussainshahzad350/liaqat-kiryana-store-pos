// lib/screens/cash_ledger/cash_ledger_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cash_ledger_model.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  final CashRepository _cashRepository = CashRepository();
  List<CashLedger> ledgerEntries = [];
  double currentBalance = 0.0;
  
  // Pagination
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 0;
  final int _limit = 20;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _refreshData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> _refreshData() async {
    setState(() {
      _isFirstLoadRunning = true;
      _page = 0;
      _hasNextPage = true;
      ledgerEntries = [];
    });
    
    // Load Balance
    final bal = await _cashRepository.getCurrentCashBalance();
    
    // Load List
    final data = await _cashRepository.getCashLedger(limit: _limit, offset: 0);
    
    if (!mounted) return;
    setState(() {
      currentBalance = bal;
      ledgerEntries = data;
      _isFirstLoadRunning = false;
      if (data.length < _limit) _hasNextPage = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;
    setState(() => _isLoadMoreRunning = true);

    _page++;
    final data = await _cashRepository.getCashLedger(
      limit: _limit, 
      offset: _page * _limit
    );

    if (!mounted) return;
    setState(() {
      if (data.isNotEmpty) {
        ledgerEntries.addAll(data);
      } else {
        _hasNextPage = false;
      }
      if (data.length < _limit) _hasNextPage = false;
      _isLoadMoreRunning = false;
    });
  }

  Future<void> _addTransaction(String type) async {
    final loc = AppLocalizations.of(context)!;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'IN' ? loc.newCashIn : loc.newCashOut), // Ensure keys exist
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(labelText: loc.amount),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: loc.description),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                decoration: InputDecoration(labelText: loc.remarks),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amount > 0 && descCtrl.text.isNotEmpty) {
                await _cashRepository.addCashEntry(
                  descCtrl.text, 
                  type, 
                  amount, 
                  remarksCtrl.text
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _refreshData(); // Reload list
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'IN' ? Colors.green : Colors.red,
            ),
            child: Text(loc.save, style: const TextStyle(color: Colors.white)),
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
        title: Text(loc.cashLedger), // Ensure key 'cashLedger' exists
        backgroundColor: Colors.deepOrange[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Balance Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.deepOrange[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.currentBalance, style: const TextStyle(fontSize: 16)),
                  Text(
                    'Rs ${currentBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange[900]
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isFirstLoadRunning
              ? const Center(child: CircularProgressIndicator())
              : ledgerEntries.isEmpty
                  ? Center(child: Text(loc.noData))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: ledgerEntries.length + (_isLoadMoreRunning ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == ledgerEntries.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final entry = ledgerEntries[index];
                        final isIncome = entry.isInflow;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${entry.transactionDate} | ${entry.transactionTime}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} ${entry.amount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Bal: ${entry.balanceAfter?.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(loc.cashIn, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _addTransaction('IN'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    label: Text(loc.cashOut, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _addTransaction('OUT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}