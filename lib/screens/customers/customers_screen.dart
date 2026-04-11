import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../core/utils/error_handler.dart';
import '../../domain/entities/money.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer_model.dart';
import '../../core/res/app_tokens.dart';
import 'dialogs/add_customer_dialog.dart';
import 'dialogs/delete_customer_dialog.dart';
import 'widgets/customer_kpi_card.dart';
import 'widgets/customer_list_tile.dart';
import 'widgets/customer_ledger_panel.dart';
import 'widgets/archived_customers_overlay.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final CustomersRepository _customersRepo;
  late final InvoiceRepository _invoiceRepo;

  // ── List state ──────────────────────────────────────────
  List<Customer> _customers = [];
  List<Customer> _archivedCustomers = [];
  bool _isLoading = true;

  // ── Stats ────────────────────────────────────────────────
  int _countTotal = 0;
  int _balTotal = 0;
  int _countActive = 0;
  int _balActive = 0;
  int _countArchived = 0;
  int _balArchived = 0;

  // ── Overlay state ────────────────────────────────────────
  bool _showArchive = false;
  Customer? _ledgerCustomer;

  // ── Search ───────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _customersRepo = context.read<CustomersRepository>();
    _invoiceRepo = context.read<InvoiceRepository>();
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────

  Future<void> _refresh() async {
    await Future.wait([_loadStats(), _loadActiveCustomers()]);
    if (_showArchive) await _loadArchivedCustomers();
  }

  Future<void> _loadStats() async {
    try {
      final s = await _customersRepo.getCustomerStats();
      if (!mounted) return;
      setState(() {
        _countTotal = (s['countTotal'] as num?)?.toInt() ?? 0;
        _balTotal = (s['balTotal'] as num?)?.toInt() ?? 0;
        _countActive = (s['countActive'] as num?)?.toInt() ?? 0;
        _balActive = (s['balActive'] as num?)?.toInt() ?? 0;
        _countArchived = (s['countArchived'] as num?)?.toInt() ?? 0;
        _balArchived = (s['balArchived'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _loadActiveCustomers() async {
    if (_customers.isEmpty) setState(() => _isLoading = true);
    try {
      final query = _searchCtrl.text.trim();
      final result = query.isEmpty
          ? await _customersRepo.getActiveCustomers()
          : await _customersRepo.searchCustomers(query, activeOnly: true);
      if (!mounted) return;
      setState(() {
        _customers = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _loadArchivedCustomers() async {
    try {
      final result = await _customersRepo.getArchivedCustomers();
      if (!mounted) return;
      setState(() => _archivedCustomers = result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  // ── Search debounce ──────────────────────────────────────

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadActiveCustomers();
    });
  }

  // ── Actions ──────────────────────────────────────────────

  void _showAddDialog({Customer? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCustomerDialog(
        customer: customer,
        repository: _customersRepo,
        onSaved: _refresh,
      ),
    );
  }

  Future<void> _toggleArchive(Customer customer) async {
    try {
      final updated = customer.copyWith(isActive: !customer.isActive);
      await _customersRepo.updateCustomer(customer.id!, updated);
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Cannot delete with outstanding balance
    if (customer.outstandingBalance != 0) {
      await showDialog(
        context: context,
        builder: (_) => CannotDeleteDialog(
          onArchive: () => _toggleArchive(customer),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDeleteDialog(),
    );

    if (confirmed != true) return;

    try {
      await _customersRepo.deleteCustomer(customer.id!);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.itemDeleted),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  void _openLedger(Customer customer) {
    setState(() => _ledgerCustomer = customer);
  }

  void _closeLedger() {
    setState(() => _ledgerCustomer = null);
  }

  void _showError(String message) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getLocalizedMessage(message, loc)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // ── Main content ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(loc, colorScheme),
              const SizedBox(height: AppTokens.spacingMedium),

              // KPI cards
              SizedBox(
                height: AppTokens.kpiHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomerKpiCard(
                        title: loc.dashboardTotal,
                        count: _countTotal,
                        balance: Money(_balTotal),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                      child: CustomerKpiCard(
                        title: loc.dashboardActive,
                        count: _countActive,
                        balance: Money(_balActive),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                      child: CustomerKpiCard(
                        title: loc.dashboardArchived,
                        count: _countArchived,
                        balance: Money(_balArchived),
                        isTertiary: true,
                        onTap: () {
                          setState(() => _showArchive = true);
                          _loadArchivedCustomers();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingMedium),

              // Search bar
              Card(
                elevation: AppTokens.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.cardPadding),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: loc.searchPlaceholder,
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.buttonBorderRadius),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingStandard,
                        vertical: AppTokens.spacingStandard,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingMedium),

              // Customer list
              Expanded(
                child: Card(
                  elevation: AppTokens.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardBorderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardBorderRadius),
                    child: _buildCustomerList(loc, colorScheme, textTheme),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Ledger overlay ─────────────────────────────────
        if (_ledgerCustomer != null)
          CustomerLedgerPanel(
            customer: _ledgerCustomer!,
            customersRepository: _customersRepo,
            invoiceRepository: _invoiceRepo,
            onClose: _closeLedger,
            onDataChanged: () {
              _refresh();
              // Refresh the customer reference so balance is current
              _customersRepo
                  .getCustomerById(_ledgerCustomer!.id!)
                  .then((updated) {
                if (updated != null && mounted) {
                  setState(() => _ledgerCustomer = updated);
                }
              });
            },
          ),

        // ── Archive overlay ────────────────────────────────
        if (_showArchive)
          ArchivedCustomersOverlay(
            customers: _archivedCustomers,
            onClose: () => setState(() => _showArchive = false),
            onUnarchive: (c) {
              _toggleArchive(c);
              setState(() => _showArchive = false);
            },
            onDelete: _deleteCustomer,
            onLedger: (c) {
              setState(() => _showArchive = false);
              _openLedger(c);
            },
          ),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add, size: AppTokens.iconSizeMedium),
            label: Text(loc.addCustomer),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.primary));
    }
    if (_customers.isEmpty) {
      return Center(
        child: Text(
          loc.noCustomersFound,
          style: textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingLarge),
      itemCount: _customers.length,
      itemBuilder: (_, i) {
        final c = _customers[i];
        return CustomerListTile(
          customer: c,
          onLedger: () => _openLedger(c),
          onEdit: () => _showAddDialog(customer: c),
          onArchive: () => _toggleArchive(c),
          onDelete: () => _deleteCustomer(c),
        );
      },
    );
  }
}
