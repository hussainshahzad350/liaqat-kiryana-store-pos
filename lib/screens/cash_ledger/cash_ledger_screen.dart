// lib/screens/cash_ledger/cash_ledger_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cash_ledger_model.dart';
import '../../domain/entities/money.dart';
import 'package:liaqat_store/core/constants/desktop_dimensions.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  final CashRepository _cashRepository = CashRepository();
  List<CashLedger> ledgerEntries = [];
  Money currentBalance = const Money(0);

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
        limit: _limit, offset: _page * _limit);

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

  Future<void> _addTransaction(String initialType) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    String selectedType = initialType;
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            selectedType == 'IN' ? loc.newCashIn : loc.newCashOut,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Selector
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setStateDialog(() => selectedType = 'IN'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: DesktopDimensions.spacingStandard),
                          decoration: BoxDecoration(
                            color: selectedType == 'IN'
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                                DesktopDimensions.cardBorderRadius / 2),
                            border: Border.all(
                                color: selectedType == 'IN'
                                    ? colorScheme.primary
                                    : colorScheme.outline),
                          ),
                          alignment: Alignment.center,
                          child: Text(loc.cashIn,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'IN'
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    Expanded(
                      child: InkWell(
                        onTap: () => setStateDialog(() => selectedType = 'OUT'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: DesktopDimensions.spacingStandard),
                          decoration: BoxDecoration(
                            color: selectedType == 'OUT'
                                ? colorScheme.errorContainer
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                                DesktopDimensions.cardBorderRadius / 2),
                            border: Border.all(
                                color: selectedType == 'OUT'
                                    ? colorScheme.error
                                    : colorScheme.outline),
                          ),
                          alignment: Alignment.center,
                          child: Text(loc.cashOut,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'OUT'
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                          data: Theme.of(context)
                              .copyWith(colorScheme: colorScheme),
                          child: child!),
                    );
                    if (picked != null) {
                      setStateDialog(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius / 2),
                      color: colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: DesktopDimensions.kpiIconSize,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(
                            width: DesktopDimensions.spacingStandard),
                        Text(DateFormat('dd MMM yyyy').format(selectedDate),
                            style: TextStyle(color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),

                TextField(
                  controller: amountCtrl,
                  decoration: InputDecoration(
                      labelText: loc.amount,
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius / 2))),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: DesktopDimensions.spacingStandard),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                      labelText: loc.description,
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius / 2))),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: DesktopDimensions.spacingStandard),
                TextField(
                  controller: remarksCtrl,
                  decoration: InputDecoration(
                      labelText: loc.remarks,
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius / 2))),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel,
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = Money.fromRupeesString(amountCtrl.text);
                if (amount > const Money(0) && descCtrl.text.isNotEmpty) {
                  await _cashRepository.addCashEntry(
                      descCtrl.text, selectedType, amount, remarksCtrl.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == 'IN'
                    ? colorScheme.primary
                    : colorScheme.error,
                foregroundColor: selectedType == 'IN'
                    ? colorScheme.onPrimary
                    : colorScheme.onError,
                minimumSize: const Size(0, DesktopDimensions.inputHeight),
              ),
              child: Text(loc.save),
            ),
          ],
        );
      }),
    ).then((_) {
      amountCtrl.dispose();
      descCtrl.dispose();
      remarksCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              bottom: DesktopDimensions.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addTransaction('IN'),
                  icon: const Icon(Icons.add),
                  label: Text(loc.cashIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                ElevatedButton.icon(
                  onPressed: () => _addTransaction('OUT'),
                  icon: const Icon(Icons.remove),
                  label: Text(loc.cashOut),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          // Balance Card
          Card(
            elevation: DesktopDimensions.cardElevation,
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesktopDimensions.spacingXXLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.currentBalance,
                      style: TextStyle(
                          fontSize: DesktopDimensions.bodySize,
                          color: colorScheme.onPrimaryContainer)),
                  Text(
                    currentBalance.formattedNoDecimal,
                    style: TextStyle(
                        fontSize: DesktopDimensions.headingSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesktopDimensions.spacingMedium),

          // List
          Expanded(
            child: Card(
              elevation: DesktopDimensions.cardElevation,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.cardBorderRadius)),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(DesktopDimensions.cardBorderRadius),
                child: _isFirstLoadRunning
                    ? Center(
                        child: CircularProgressIndicator(
                            color: colorScheme.primary))
                    : ledgerEntries.isEmpty
                        ? Center(
                            child: Text(loc.noData,
                                style: TextStyle(color: colorScheme.onSurface)))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: ledgerEntries.length +
                                (_isLoadMoreRunning ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == ledgerEntries.length) {
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: colorScheme.primary));
                              }

                              final entry = ledgerEntries[index];
                              final isIncome = entry.isInflow;

                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? colorScheme.primaryContainer
                                          : colorScheme.errorContainer,
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIncome
                                            ? colorScheme.primary
                                            : colorScheme.error,
                                      ),
                                    ),
                                    title: Text(entry.description,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface)),
                                    subtitle: Text(
                                        '${entry.transactionDate} | ${entry.transactionTime}',
                                        style: TextStyle(
                                            color:
                                                colorScheme.onSurfaceVariant)),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'} ${Money((entry.amount as num).toInt()).formattedNoDecimal}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isIncome
                                                ? colorScheme.primary
                                                : colorScheme.error,
                                            fontSize:
                                                DesktopDimensions.bodySize,
                                          ),
                                        ),
                                        Text(
                                          'Bal: ${Money((entry.balanceAfter as num?)?.toInt() ?? 0).formattedNoDecimal}',
                                          style: TextStyle(
                                              fontSize:
                                                  DesktopDimensions.captionSize,
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                ],
                              );
                            },
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
