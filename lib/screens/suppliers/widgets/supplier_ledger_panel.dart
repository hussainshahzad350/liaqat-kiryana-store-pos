import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/suppliers_repository.dart';
import '../../../../domain/entities/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/supplier_model.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../services/ledger_export_service.dart';
import '../dialogs/receive_supplier_payment_dialog.dart';

class SupplierLedgerPanel extends StatefulWidget {
  final Supplier supplier;
  final SuppliersRepository repository;
  final VoidCallback onClose;
  final VoidCallback onDataChanged;

  const SupplierLedgerPanel({
    super.key,
    required this.supplier,
    required this.repository,
    required this.onClose,
    required this.onDataChanged,
  });

  @override
  State<SupplierLedgerPanel> createState() => _SupplierLedgerPanelState();
}

class _SupplierLedgerPanelState extends State<SupplierLedgerPanel> {
  final LedgerExportService _exportService = LedgerExportService();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _ledger = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await widget.repository.getSupplierLedger(
        widget.supplier.id!,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _ledger = data;
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _ledger.where((row) {
      if (_filterType == 'BILL' && row['type'] != 'BILL') {
        return false;
      }
      if (_filterType == 'PAYMENT' && row['type'] != 'PAYMENT') {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return (row['bill_no'] ?? '').toString().toLowerCase().contains(q) ||
            (row['desc'] ?? '').toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _searchQuery = val);
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadLedger();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadLedger();
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (_) => ReceiveSupplierPaymentDialog(
        supplier: widget.supplier,
        repository: widget.repository,
        onPaymentAdded: () {
          _loadLedger();
          widget.onDataChanged();
        },
      ),
    );
  }

  Future<void> _handleExport() async {
    if (_ledger.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTokens.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: colorScheme.error),
              title: Text(loc.printOrPdf),
              onTap: () {
                Navigator.pop(ctx);
                _exportService.exportSupplierLedgerToPdf(
                  _ledger, widget.supplier,
                  isUrdu: isUrdu,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: colorScheme.primary),
              title: Text(loc.exportToExcelCsv),
              onTap: () async {
                Navigator.pop(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final path =
                    await _exportService.exportSupplierLedgerToCsv(_ledger, widget.supplier);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(loc.savedToPath(path))));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: colorScheme.shadow.withValues(alpha: 0.5)),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  color: colorScheme.shadow.withValues(alpha: 0.3),
                )
              ],
            ),
            child: Column(
              children: [
                _Header(
                  supplier: widget.supplier,
                  onPayment: _showPaymentDialog,
                  onExport: _handleExport,
                  onClose: widget.onClose,
                  loc: loc,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _FilterBar(
                  filterType: _filterType,
                  startDate: _startDate,
                  endDate: _endDate,
                  searchCtrl: _searchCtrl,
                  onFilterChanged: (v) => setState(() => _filterType = v),
                  onPickDate: _pickDateRange,
                  onClearDate: _clearDateRange,
                  onSearch: _onSearchChanged,
                  loc: loc,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _TableHeader(
                    loc: loc, colorScheme: colorScheme, textTheme: textTheme),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary))
                      : _loadError != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 40, color: colorScheme.error),
                                  const SizedBox(
                                      height: AppTokens.spacingMedium),
                                  Text(
                                    loc.errorMessage(_loadError!),
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.error),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(
                                      height: AppTokens.spacingMedium),
                                  ElevatedButton.icon(
                                    onPressed: _loadLedger,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(loc.retry),
                                  ),
                                ],
                              ),
                            )
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(loc.noTransactionsFound,
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final row = _filtered[i];
                                final isEven = i % 2 == 0;
                                final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
                                final debit = Money(_parseInt(row['dr']) ?? _parseInt(row['debit']) ?? 0); // We paid them
                                final credit = Money(_parseInt(row['cr']) ?? _parseInt(row['credit']) ?? 0); // Bill
                                final balance = Money(_parseInt(row['balance']) ?? 0);
                                final isBill = row['type'] == 'BILL';

                                final bgColor = isEven ? colorScheme.surface : colorScheme.surfaceContainerHighest;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppTokens.spacingSmall,
                                    horizontal: AppTokens.spacingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Text(DateFormat('dd-MM-yyyy').format(date),
                                              style: textTheme.bodySmall?.copyWith(fontFamily: 'RobotoMono'))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            (row['bill_no'] ?? '-')
                                              .toString(),
                                              style: textTheme.bodySmall?.copyWith(fontFamily: 'RobotoMono'))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            isBill ? "Bill" : "Payment",
                                            style: textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isBill ? colorScheme.primary : colorScheme.tertiary,
                                            ),
                                          )),
                                      Expanded(
                                          flex: 4,
                                          child: Text((row['desc'] ?? '').toString(),
                                              style: textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            debit > Money.zero ? debit.toString() : '-', // DR
                                            textAlign: TextAlign.right,
                                            style: textTheme.bodySmall?.copyWith(fontFamily: 'RobotoMono'),
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            credit > Money.zero ? credit.toString() : '-', // CR
                                            textAlign: TextAlign.right,
                                            style: textTheme.bodySmall?.copyWith(fontFamily: 'RobotoMono'),
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            balance.toString(),
                                            textAlign: TextAlign.right,
                                            style: textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'RobotoMono',
                                              color: balance > Money.zero
                                                  ? colorScheme.error
                                                  : colorScheme.primary, // Alert them it's a debt we owe!
                                            ),
                                          )),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onPayment;
  final VoidCallback onExport;
  final VoidCallback onClose;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Header({
    required this.supplier,
    required this.onPayment,
    required this.onExport,
    required this.onClose,
    required this.loc,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final balance = Money(supplier.outstandingBalance);
    final isDebit = balance > Money.zero;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.cardBorderRadius)),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(supplier.nameEnglish,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (supplier.nameUrdu != null)
                Text(supplier.nameUrdu!,
                    style: textTheme.bodyLarge?.copyWith(
                        fontFamily: 'NooriNastaleeq',
                        height: 1.2,
                        color: colorScheme.onSurfaceVariant)),
              Text(supplier.contactPrimary ?? '', style: textTheme.bodyMedium),
              if (supplier.address != null)
                Text(supplier.address!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Total Payable", // loc fallback
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
              Text(
                balance.toString(),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDebit ? colorScheme.error : colorScheme.primary,
                ),
              ),
              if (supplier.supplierType != null)
                Text(
                  supplier.supplierType!,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(width: AppTokens.spacingLarge),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onPayment,
                icon: const Icon(Icons.add, size: AppTokens.iconSizeMedium),
                label: const Text("Make Payment"),
              ),
              const SizedBox(width: AppTokens.spacingSmall),
              IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: onExport,
                  tooltip: loc.exportTooltip,
                  color: colorScheme.onSurfaceVariant),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: loc.closeTooltip,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String filterType;
  final DateTime? startDate;
  final DateTime? endDate;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<String> onSearch;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _FilterBar({
    required this.filterType,
    required this.startDate,
    required this.endDate,
    required this.searchCtrl,
    required this.onFilterChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onSearch,
    required this.loc,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onPickDate,
            icon:
                const Icon(Icons.calendar_today, size: AppTokens.iconSizeSmall),
            label: Text(startDate == null
                ? loc.dateRangeButton
                : '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'),
            style: OutlinedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
          if (startDate != null) ...[
            IconButton(
              icon: const Icon(Icons.clear, size: AppTokens.iconSizeSmall),
              onPressed: onClearDate,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
          const SizedBox(width: AppTokens.spacingMedium),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ALL', label: Text("All")),
              ButtonSegment(value: 'BILL', label: Text("Bills")),
              ButtonSegment(value: 'PAYMENT', label: Text("Payments")),
            ],
            selected: {filterType},
            onSelectionChanged: (s) => onFilterChanged(s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: AppTokens.sidebarWidthSmall,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style:
                  textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: loc.searchDocOrDescPlaceholder,
                prefixIcon:
                    const Icon(Icons.search, size: AppTokens.iconSizeSmall),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spacingSmall,
                  horizontal: AppTokens.spacingStandard,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.buttonBorderRadius),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TableHeader(
      {required this.loc, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.spacingSmall,
        horizontal: AppTokens.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          _col(2, loc.date),
          _col(2, loc.docNoHeader),
          _col(2, loc.typeHeader),
          _col(4, loc.description),
          _colRight(2, loc.debitHeader),
          _colRight(2, loc.creditHeader),
          _colRight(2, loc.balanceHeader),
        ],
      ),
    );
  }

  Widget _col(int flex, String label) => Expanded(
      flex: flex,
      child: Text(label,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)));

  Widget _colRight(int flex, String label) => Expanded(
      flex: flex,
      child: Text(label,
          textAlign: TextAlign.right,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)));
}
