import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/repositories/customers_repository.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../models/invoice_item_model.dart';
import '../../../core/res/app_tokens.dart';
import '../../../services/ledger_export_service.dart';
import '../dialogs/receive_payment_dialog.dart';

class CustomerLedgerPanel extends StatefulWidget {
  final Customer customer;
  final CustomersRepository customersRepository;
  final InvoiceRepository invoiceRepository;
  final VoidCallback onClose;
  final VoidCallback onDataChanged;

  const CustomerLedgerPanel({
    super.key,
    required this.customer,
    required this.customersRepository,
    required this.invoiceRepository,
    required this.onClose,
    required this.onDataChanged,
  });

  @override
  State<CustomerLedgerPanel> createState() => _CustomerLedgerPanelState();
}

class _CustomerLedgerPanelState extends State<CustomerLedgerPanel> {
  final LedgerExportService _exportService = LedgerExportService();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _ledger = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      final data = await widget.customersRepository.getCustomerLedger(
        widget.customer.id!,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _ledger = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _ledger.where((row) {
      if (_filterType == 'SALE' && row['type'] != 'SALE') {
        return false;
      }
      if (_filterType == 'RECEIPT' &&
          row['type'] != 'PAYMENT' &&
          row['type'] != 'RECEIPT') {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return row['ref_no'].toString().toLowerCase().contains(q) ||
            (row['description'] ?? '').toString().toLowerCase().contains(q);
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
      builder: (_) => ReceivePaymentDialog(
        customer: widget.customer,
        repository: widget.customersRepository,
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
                _exportService.exportToPdf(_ledger, widget.customer,
                    isUrdu: isUrdu);
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: colorScheme.primary),
              title: Text(loc.exportToExcelCsv),
              onTap: () async {
                Navigator.pop(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final path =
                    await _exportService.exportToCsv(_ledger, widget.customer);
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
                  customer: widget.customer,
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
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(loc.noTransactionsFound,
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) => _LedgerRow(
                                row: _filtered[i],
                                isEven: i % 2 == 0,
                                invoiceRepository: widget.invoiceRepository,
                                onInvoiceCancelled: () {
                                  _loadLedger();
                                  widget.onDataChanged();
                                },
                              ),
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

// ──────────────────────────────────────────────────────────
// Internal sub-widgets
// ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Customer customer;
  final VoidCallback onPayment;
  final VoidCallback onExport;
  final VoidCallback onClose;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Header({
    required this.customer,
    required this.onPayment,
    required this.onExport,
    required this.onClose,
    required this.loc,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final balance = Money(customer.outstandingBalance);
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
              Text(customer.nameEnglish,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (customer.nameUrdu != null)
                Text(customer.nameUrdu!,
                    style: textTheme.bodyLarge?.copyWith(
                        fontFamily: 'NooriNastaleeq',
                        height: 1.2,
                        color: colorScheme.onSurfaceVariant)),
              Text(customer.contactPrimary ?? '', style: textTheme.bodyMedium),
              if (customer.address != null)
                Text(customer.address!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(loc.currentBalanceLabel,
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
              if (customer.creditLimit > 0)
                Text(
                  loc.creditLimitLabel(Money(customer.creditLimit).toString()),
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
                label: Text(loc.receivePaymentButton),
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
            segments: [
              ButtonSegment(value: 'ALL', label: Text(loc.all)),
              ButtonSegment(value: 'SALE', label: Text(loc.sales)),
              ButtonSegment(value: 'RECEIPT', label: Text(loc.filterReceipts)),
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

// ──────────────────────────────────────────────────────────
// Ledger row with expandable invoice items
// ──────────────────────────────────────────────────────────

class _LedgerRow extends StatefulWidget {
  final Map<String, dynamic> row;
  final bool isEven;
  final InvoiceRepository invoiceRepository;
  final VoidCallback onInvoiceCancelled;

  const _LedgerRow({
    required this.row,
    required this.isEven,
    required this.invoiceRepository,
    required this.onInvoiceCancelled,
  });

  @override
  State<_LedgerRow> createState() => _LedgerRowState();
}

class _LedgerRowState extends State<_LedgerRow> {
  bool _isExpanded = false;
  List<InvoiceItem>? _items;
  bool _isLoading = false;

  Future<void> _toggleExpand() async {
    if (widget.row['type'] != 'SALE') return;
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded && _items == null) {
      setState(() => _isLoading = true);
      try {
        final id = _parseInt(widget.row['ref_no']);
        if (id != null) {
          final invoice =
              await widget.invoiceRepository.getInvoiceWithItems(id);
          if (mounted) setState(() => _items = invoice?.items ?? []);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelInvoice() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius)),
        child: Container(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
          padding: const EdgeInsets.all(AppTokens.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(loc.confirmCancellationTitle, style: textTheme.titleLarge),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
              const Divider(),
              const SizedBox(height: AppTokens.spacingMedium),
              Text(loc.confirmCancelInvoiceMessage,
                  style: textTheme.bodyMedium),
              const SizedBox(height: AppTokens.spacingLarge),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(loc.no)),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: Text(loc.yesCancelButton),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final id = _parseInt(widget.row['ref_no']);
      if (id == null) return;
      await widget.invoiceRepository.cancelInvoice(
        invoiceId: id,
        cancelledBy: 'User',
        reason: 'Cancelled from customer ledger',
      );
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final successMsg =
            AppLocalizations.of(context)!.invoiceCancelledSuccess;
        final successColor = Theme.of(context).colorScheme.primary;
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(successMsg),
          backgroundColor: successColor,
        ));
        widget.onInvoiceCancelled();
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final errorMsg =
            AppLocalizations.of(context)!.errorMessage(e.toString());
        final errorColor = Theme.of(context).colorScheme.error;
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: errorColor,
        ));
      }
    }
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    final row = widget.row;
    final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    final debit = Money(_parseInt(row['debit']) ?? 0);
    final credit = Money(_parseInt(row['credit']) ?? 0);
    final balance = Money(_parseInt(row['balance']) ?? 0);
    final isSale = row['type'] == 'SALE';
    final isReceipt = row['type'] == 'PAYMENT' || row['type'] == 'RECEIPT';

    final bgColor = _isExpanded
        ? colorScheme.primaryContainer.withValues(alpha: 0.1)
        : (isReceipt
            ? colorScheme.primaryContainer.withValues(alpha: 0.05)
            : (widget.isEven
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest));

    return Column(
      children: [
        InkWell(
          onTap: isSale ? _toggleExpand : null,
          hoverColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.spacingSmall,
              horizontal: AppTokens.spacingMedium,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border:
                  Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(DateFormat('dd-MM-yyyy').format(date),
                        style: textTheme.bodySmall
                            ?.copyWith(fontFamily: 'RobotoMono'))),
                Expanded(
                    flex: 2,
                    child: Text(
                        isSale
                            ? 'INV-${row['ref_no']}'
                            : 'RCP-${row['ref_no']}',
                        style: textTheme.bodySmall
                            ?.copyWith(fontFamily: 'RobotoMono'))),
                Expanded(
                    flex: 2,
                    child: Text(
                      isSale ? loc.saleType : loc.receiptType,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isSale ? colorScheme.primary : colorScheme.tertiary,
                      ),
                    )),
                Expanded(
                    flex: 4,
                    child: Row(children: [
                      if (isSale)
                        Icon(
                          _isExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          size: AppTokens.iconSizeSmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      Expanded(
                          child: Text(row['description'] ?? '',
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis)),
                      if (isSale)
                        IconButton(
                          icon: Icon(Icons.cancel,
                              color: colorScheme.error,
                              size: AppTokens.iconSizeSmall),
                          tooltip: loc.cancelInvoiceTooltip,
                          onPressed: _cancelInvoice,
                        ),
                    ])),
                Expanded(
                    flex: 2,
                    child: Text(
                      debit > Money.zero ? debit.toString() : '-',
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall
                          ?.copyWith(fontFamily: 'RobotoMono'),
                    )),
                Expanded(
                    flex: 2,
                    child: Text(
                      credit > Money.zero ? credit.toString() : '-',
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall
                          ?.copyWith(fontFamily: 'RobotoMono'),
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
                            : colorScheme.primary,
                      ),
                    )),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(
                AppTokens.spacingXXLarge,
                AppTokens.spacingSmall,
                AppTokens.spacingMedium,
                AppTokens.spacingMedium),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                        width: AppTokens.iconSizeMedium,
                        height: AppTokens.iconSizeMedium,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : _items == null || _items!.isEmpty
                    ? Center(
                        child: Text(loc.noItemsFound,
                            style: textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)))
                    : Table(
                        border: TableBorder(
                            bottom: BorderSide(color: colorScheme.outline)),
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest),
                            children: [
                              _th(loc.item, textTheme),
                              _th(loc.qty, textTheme, align: TextAlign.center),
                              _th(loc.rateHeader, textTheme,
                                  align: TextAlign.right),
                              _th(loc.totalHeader, textTheme,
                                  align: TextAlign.right),
                            ],
                          ),
                          ..._items!.map(
                            (item) => TableRow(children: [
                              _td(item.itemName, textTheme),
                              _td(item.quantity.toString(), textTheme,
                                  align: TextAlign.center),
                              _td(Money(item.unitPrice).toString(), textTheme,
                                  align: TextAlign.right),
                              _td(Money(item.totalPrice).toString(), textTheme,
                                  align: TextAlign.right),
                            ]),
                          ),
                        ],
                      ),
          ),
      ],
    );
  }

  Widget _th(String label, TextTheme t, {TextAlign align = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXSmall),
        child: Text(label,
            textAlign: align,
            style: t.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _td(String value, TextTheme t, {TextAlign align = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXSmall),
        child: Text(value, textAlign: align, style: t.bodySmall),
      );
}
