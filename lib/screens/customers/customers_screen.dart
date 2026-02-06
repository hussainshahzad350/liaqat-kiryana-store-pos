// lib/screens/master_data/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../services/ledger_export_service.dart';
import '../../models/invoice_item_model.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer_model.dart';
import '../../domain/entities/money.dart';
import '../../core/constants/desktop_dimensions.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomersRepository _customersRepository = CustomersRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final LedgerExportService _ledgerExportService = LedgerExportService();

  // --- STATE VARIABLES ---
  List<Customer> customers = [];
  List<Customer> archivedCustomers = [];

  // Ledger State
  bool _showArchiveOverlay = false;
  bool _showLedgerOverlay = false;
  List<Map<String, dynamic>> _currentLedger = [];
  Customer? _selectedCustomerForLedger;

  // Ledger Filters
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;
  String _ledgerFilterType = 'ALL';
  String _ledgerSearchQuery = '';
  final TextEditingController _ledgerSearchCtrl = TextEditingController();

  bool _isFirstLoadRunning = true;
  final TextEditingController searchController = TextEditingController();

  // Stats
  int countTotal = 0;
  int balTotal = 0;
  int countActive = 0;
  int balActive = 0;
  int countArchived = 0;
  int balArchived = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _ledgerSearchCtrl.dispose();
    super.dispose();
  }

  // --- DATABASE & LOGIC ---
  // PRESERVED EXACTLY AS PROVIDED

  Future<void> _refreshData() async {
    await _loadStats();
    await _loadActiveCustomers();
    if (_showArchiveOverlay) await _loadArchivedCustomers();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _customersRepository.getCustomerStats();

      if (mounted) {
        setState(() {
          countTotal = (stats['countTotal'] as num?)?.toInt() ?? 0;
          balTotal = (stats['balTotal'] as num?)?.toInt() ?? 0;
          countActive = (stats['countActive'] as num?)?.toInt() ?? 0;
          balActive = (stats['balActive'] as num?)?.toInt() ?? 0;
          countArchived = (stats['countArchived'] as num?)?.toInt() ?? 0;
          balArchived = (stats['balArchived'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
    }
  }

  Future<void> _loadActiveCustomers() async {
    if (customers.isEmpty) {
      setState(() => _isFirstLoadRunning = true);
    }
    try {
      final searchText = searchController.text.trim();

      List<Customer> result;
      if (searchText.isEmpty) {
        result = await _customersRepository.getActiveCustomers();
      } else {
        result = await _customersRepository.searchCustomers(searchText,
            activeOnly: true);
      }

      if (mounted) {
        setState(() {
          customers = result;
          _isFirstLoadRunning = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading customers: $e");
      if (mounted) {
        setState(() => _isFirstLoadRunning = false);
      }
    }
  }

  Future<void> _loadArchivedCustomers() async {
    try {
      final result = await _customersRepository.getArchivedCustomers();
      if (mounted) {
        setState(() => archivedCustomers = result);
      }
    } catch (e) {
      debugPrint("Error loading archived customers: $e");
    }
  }

  Future<bool> _isPhoneUnique(String phone, {int? excludeId}) async {
    return await _customersRepository.isPhoneUnique(phone,
        excludeId: excludeId);
  }

  Future<bool> _canDelete(int id, int balance) async {
    if (balance != 0) return false;
    return true;
  }

  // --- LEDGER LOGIC ---
  // PRESERVED EXACTLY AS PROVIDED

  Future<void> _openLedger(Customer customer) async {
    setState(() {
      _selectedCustomerForLedger = customer;
      _showLedgerOverlay = true;
      _currentLedger = [];
      _ledgerStartDate = null;
      _ledgerEndDate = null;
      _ledgerFilterType = 'ALL';
      _ledgerSearchQuery = '';
      _ledgerSearchCtrl.clear();
    });
    await _loadLedgerData();
  }

  Future<void> _loadLedgerData() async {
    if (_selectedCustomerForLedger == null) return;
    try {
      final data = await _customersRepository.getCustomerLedger(
        _selectedCustomerForLedger!.id!,
        startDate: _ledgerStartDate,
        endDate: _ledgerEndDate,
      );
      if (mounted) setState(() => _currentLedger = data);
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }
  }

  List<Map<String, dynamic>> get _filteredLedgerRows {
    return _currentLedger.where((row) {
      if (_ledgerFilterType == 'SALE' && row['type'] != 'SALE') return false;
      if (_ledgerFilterType == 'RECEIPT' &&
          row['type'] != 'PAYMENT' &&
          row['type'] != 'RECEIPT') {
        return false;
      }

      if (_ledgerSearchQuery.isNotEmpty) {
        final q = _ledgerSearchQuery.toLowerCase();
        final docNo = row['ref_no'].toString().toLowerCase();
        final desc = (row['description'] ?? '').toString().toLowerCase();
        return docNo.contains(q) || desc.contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _addPayment(Money amount, String notes) async {
    if (_selectedCustomerForLedger == null) return;
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await _customersRepository.addPayment(
        _selectedCustomerForLedger!.id!, amount.paisas, date, notes);
    await _refreshData();
    await _loadLedgerData();
  }

  Future<void> _handleExport(AppLocalizations loc) async {
    if (_selectedCustomerForLedger == null || _currentLedger.isEmpty) return;

    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.error),
              title: Text(loc.printOrPdf),
              onTap: () {
                Navigator.pop(context);
                _ledgerExportService.exportToPdf(
                    _currentLedger, _selectedCustomerForLedger!,
                    isUrdu: isUrdu);
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(loc.exportToExcelCsv),
              onTap: () async {
                Navigator.pop(context);
                final path = await _ledgerExportService.exportToCsv(
                    _currentLedger, _selectedCustomerForLedger!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.savedToPath(path))));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---
  // PRESERVED EXACTLY AS PROVIDED

  Future<void> _addOrUpdateCustomer({
    required int? id,
    required String nameEng,
    required String nameUrdu,
    required String phone,
    required String address,
    required int limit,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    bool isUnique = await _isPhoneUnique(phone, excludeId: id);
    if (!isUnique) throw Exception(loc.phoneExistsError);

    final customer = Customer(
      id: id,
      nameEnglish: nameEng,
      nameUrdu: nameUrdu,
      contactPrimary: phone,
      address: address,
      creditLimit: limit,
      outstandingBalance: 0,
      isActive: true,
    );

    if (id == null) {
      await _customersRepository.addCustomer(customer);
      if (!mounted) return;
      _showSnack(loc.customerAddedSuccess, colorScheme.primary);
    } else {
      await _customersRepository.updateCustomer(id, customer);
      if (!mounted) return;
      _showSnack(loc.customerUpdatedSuccess, colorScheme.primary);
    }
    await _refreshData();
  }

  Future<void> _toggleArchiveStatus(int id, bool currentStatus) async {
    final customer = await _customersRepository.getCustomerById(id);
    if (customer == null) return;

    final updatedCustomer = customer.copyWith(isActive: !currentStatus);
    await _customersRepository.updateCustomer(id, updatedCustomer);
    _refreshData();
    if (_showArchiveOverlay) _loadArchivedCustomers();
  }

  Future<void> _deleteCustomer(int id, int balance) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!(await _canDelete(id, balance))) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesktopDimensions.dialogWidth,
              maxHeight: DesktopDimensions.dialogHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.warning,
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: DesktopDimensions.spacingMedium),
                  Text(loc.cannotDeleteBal,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: DesktopDimensions.spacingLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.ok,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface)),
                      ),
                      const SizedBox(width: DesktopDimensions.spacingStandard),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          minimumSize:
                              const Size(0, DesktopDimensions.buttonHeight),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleArchiveStatus(id, true);
                        },
                        child: Text(loc.archiveNow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DesktopDimensions.dialogWidth,
            maxHeight: DesktopDimensions.dialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.confirm,
                    style: textTheme.titleLarge
                        ?.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                Text(loc.confirmDeleteItem,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(loc.no,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        minimumSize:
                            const Size(0, DesktopDimensions.buttonHeight),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(loc.yesDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _customersRepository.deleteCustomer(id);
      if (!mounted) return;
      await _refreshData();
      _showSnack(loc.itemDeleted, colorScheme.onSurfaceVariant);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  // --- UI COMPONENTS ---
  // REWRITTEN WITH FOUNDATION COMPLIANCE

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
          child: Column(
            children: [
              // Actions Toolbar
              _buildActionToolbar(loc, colorScheme, textTheme),
              const SizedBox(height: DesktopDimensions.spacingMedium),

              // Dashboard
              _buildDashboard(loc, colorScheme, textTheme),
              const SizedBox(height: DesktopDimensions.spacingMedium),

              // Search Card
              Card(
                elevation: DesktopDimensions.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesktopDimensions.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => _loadActiveCustomers(),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: loc.searchPlaceholder,
                      hintStyle: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.buttonBorderRadius),
                        borderSide:
                            BorderSide(color: colorScheme.outline, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.buttonBorderRadius),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingStandard,
                        vertical: DesktopDimensions.spacingStandard,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingMedium),

              // Customers List
              Expanded(
                child: Card(
                  elevation: DesktopDimensions.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius),
                    child: _isFirstLoadRunning
                        ? Center(
                            child: CircularProgressIndicator(
                                color: colorScheme.primary),
                          )
                        : customers.isEmpty
                            ? Center(
                                child: Text(
                                  loc.noCustomersFound,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: colorScheme.onSurface),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                    bottom: DesktopDimensions.spacingLarge),
                                itemCount: customers.length,
                                itemBuilder: (context, index) =>
                                    _buildCustomerCard(
                                  customers[index],
                                  colorScheme,
                                  textTheme,
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showLedgerOverlay) _buildLedgerOverlay(loc),
        if (_showArchiveOverlay) _buildArchiveOverlay(loc),
      ],
    );
  }

  Widget _buildActionToolbar(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add, size: DesktopDimensions.iconSizeMedium),
            label: Text(loc.addCustomer),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(0, DesktopDimensions.buttonHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      height: DesktopDimensions.kpiHeight,
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              loc,
              loc.dashboardTotal,
              countTotal,
              Money(balTotal),
              null,
              colorScheme,
              textTheme,
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Expanded(
            child: _buildKpiCard(
              loc,
              loc.dashboardActive,
              countActive,
              Money(balActive),
              null,
              colorScheme,
              textTheme,
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Expanded(
            child: _buildKpiCard(
              loc,
              loc.dashboardArchived,
              countArchived,
              Money(balArchived),
              () {
                setState(() {
                  _showArchiveOverlay = true;
                  _loadArchivedCustomers();
                });
              },
              colorScheme,
              textTheme,
              isTertiary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    AppLocalizations loc,
    String title,
    int count,
    Money amount,
    VoidCallback? onTap,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isTertiary = false,
  }) {
    final containerColor = isTertiary
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final contentColor = isTertiary
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;
    final borderColor = isTertiary ? colorScheme.tertiary : colorScheme.primary;

    return Card(
      elevation: DesktopDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      color: containerColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.people,
                    size: DesktopDimensions.iconSizeLarge,
                    color: contentColor,
                  ),
                  Flexible(
                    child: Text(
                      "$count",
                      style: textTheme.titleLarge?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "${loc.balanceShort}: ${amount.toString()}",
                style: textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
      Customer customer, ColorScheme colorScheme, TextTheme textTheme) {
    final Money balance = Money(customer.outstandingBalance);
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final String name = isUrdu
        ? (customer.nameUrdu != null && customer.nameUrdu!.isNotEmpty
            ? customer.nameUrdu!
            : customer.nameEnglish)
        : customer.nameEnglish;
    final String phone = customer.contactPrimary ?? '';

    return Card(
      elevation: DesktopDimensions.cardElevation,
      margin: const EdgeInsets.symmetric(
        horizontal: DesktopDimensions.spacingMedium,
        vertical: DesktopDimensions.spacingSmall,
      ),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingStandard,
          vertical: DesktopDimensions.spacingSmall,
        ),
        dense: true,
        leading: CircleAvatar(
          radius: DesktopDimensions.iconSizeMedium,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: isUrdu ? 'NooriNastaleeq' : null,
            fontSize: isUrdu ? DesktopDimensions.titleLargeSize : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (customer.creditLimit > 0)
              Text(
                "${AppLocalizations.of(context)!.creditLimit}: ${Money(customer.creditLimit)}",
                style:
                    textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (balance != const Money(0))
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingSmall),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesktopDimensions.spacingSmall,
                  vertical: DesktopDimensions.spacingXSmall,
                ),
                decoration: BoxDecoration(
                  color: balance > const Money(0)
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.buttonBorderRadius),
                  border: Border.all(
                    color: balance > const Money(0)
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
                child: Text(
                  balance.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: balance > const Money(0)
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.receipt_long, color: colorScheme.primary),
              tooltip: AppLocalizations.of(context)!.viewLedgerTooltip,
              onPressed: () => _openLedger(customer),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'edit') _showAddDialog(customer: customer);
                if (value == 'archive') {
                  _toggleArchiveStatus(customer.id!, true);
                }
                if (value == 'delete') {
                  _deleteCustomer(customer.id!, customer.outstandingBalance);
                }
              },
              itemBuilder: (context) {
                final loc = AppLocalizations.of(context)!;
                return [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: DesktopDimensions.iconSizeSmall,
                            color: colorScheme.onSurface),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        Text(loc.editAction,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive,
                            size: DesktopDimensions.iconSizeSmall,
                            color: colorScheme.onSurface),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        Text(loc.archiveAction,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            size: DesktopDimensions.iconSizeSmall,
                            color: colorScheme.error),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        Text(loc.deleteAction,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- LEDGER OVERLAY ---
  // REWRITTEN WITH FOUNDATION COMPLIANCE

  Widget _buildLedgerOverlay(AppLocalizations loc) {
    final customer = _selectedCustomerForLedger!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showLedgerOverlay = false),
          child: Container(color: colorScheme.shadow.withOpacity(0.5)),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  blurRadius: DesktopDimensions.cardElevation * 4,
                  color: colorScheme.shadow.withOpacity(0.3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildLedgerHeader(customer, loc, colorScheme, textTheme),

                // Filter Bar
                _buildLedgerFilterBar(loc, colorScheme, textTheme),

                // Table Header
                _buildLedgerTableHeader(colorScheme, textTheme),

                // Table Body
                Expanded(
                  child: _filteredLedgerRows.isEmpty
                      ? Center(
                          child: Text(
                            loc.noTransactionsFound,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredLedgerRows.length,
                          itemBuilder: (context, index) {
                            final row = _filteredLedgerRows[index];
                            return _LedgerRow(
                              row: row,
                              isEven: index % 2 == 0,
                              invoiceRepository: _invoiceRepository,
                              onInvoiceCancelled: () {
                                _loadLedgerData();
                                _refreshData();
                              },
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

  Widget _buildLedgerHeader(Customer customer, AppLocalizations loc,
      ColorScheme colorScheme, TextTheme textTheme) {
    final Money balance = Money(customer.outstandingBalance);
    final isDebit = balance > const Money(0);

    return Container(
      padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesktopDimensions.cardBorderRadius)),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Customer Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.nameEnglish,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (customer.nameUrdu != null)
                Text(
                  customer.nameUrdu!,
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: 'NooriNastaleeq',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: DesktopDimensions.spacingXSmall),
              Text(
                customer.contactPrimary ?? '',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface),
              ),
              if (customer.address != null)
                Text(
                  customer.address!,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const Spacer(),
          // Financials
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                loc.currentBalanceLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          const SizedBox(width: DesktopDimensions.spacingLarge),
          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.add,
                    size: DesktopDimensions.iconSizeMedium),
                label: Text(loc.receivePaymentButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(0, DesktopDimensions.buttonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingMedium,
                    vertical: DesktopDimensions.spacingSmall,
                  ),
                ),
              ),
              const SizedBox(width: DesktopDimensions.spacingSmall),
              IconButton(
                icon: const Icon(Icons.print,
                    size: DesktopDimensions.iconSizeMedium),
                onPressed: () => _handleExport(loc),
                tooltip: loc.exportTooltip,
                color: colorScheme.onSurfaceVariant,
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: DesktopDimensions.iconSizeMedium),
                onPressed: () => setState(() => _showLedgerOverlay = false),
                tooltip: loc.closeTooltip,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerFilterBar(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopDimensions.spacingMedium,
        vertical: DesktopDimensions.spacingSmall,
      ),
      color: colorScheme.surfaceVariant,
      child: Row(
        children: [
          // Date Range
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange:
                    _ledgerStartDate != null && _ledgerEndDate != null
                        ? DateTimeRange(
                            start: _ledgerStartDate!, end: _ledgerEndDate!)
                        : null,
              );
              if (picked != null) {
                setState(() {
                  _ledgerStartDate = picked.start;
                  _ledgerEndDate = picked.end;
                });
                _loadLedgerData();
              }
            },
            icon: const Icon(Icons.calendar_today,
                size: DesktopDimensions.iconSizeSmall),
            label: Text(_ledgerStartDate == null
                ? loc.dateRangeButton
                : "${DateFormat('dd/MM').format(_ledgerStartDate!)} - ${DateFormat('dd/MM').format(_ledgerEndDate!)}"),
            style: OutlinedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
          if (_ledgerStartDate != null)
            IconButton(
              icon: const Icon(Icons.clear,
                  size: DesktopDimensions.iconSizeSmall),
              onPressed: () {
                setState(() {
                  _ledgerStartDate = null;
                  _ledgerEndDate = null;
                });
                _loadLedgerData();
              },
              color: colorScheme.onSurfaceVariant,
            ),

          const SizedBox(width: DesktopDimensions.spacingMedium),
          // Type Filter
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'ALL', label: Text(loc.all)),
              ButtonSegment(value: 'SALE', label: Text(loc.sales)),
              ButtonSegment(value: 'RECEIPT', label: Text(loc.filterReceipts)),
            ],
            selected: {_ledgerFilterType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _ledgerFilterType = newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.primaryContainer;
                }
                return Theme.of(context).colorScheme.surface;
              }),
            ),
          ),

          const Spacer(),
          // Search
          SizedBox(
            width: DesktopDimensions.sidebarWidthSmall,
            child: TextField(
              controller: _ledgerSearchCtrl,
              style:
                  textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: loc.searchDocOrDescPlaceholder,
                hintStyle: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search,
                    size: DesktopDimensions.iconSizeSmall),
                suffixIcon: _ledgerSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: DesktopDimensions.iconSizeSmall),
                        onPressed: () {
                          _ledgerSearchCtrl.clear();
                          setState(() => _ledgerSearchQuery = '');
                        },
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: DesktopDimensions.spacingSmall,
                  horizontal: DesktopDimensions.spacingStandard,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.buttonBorderRadius),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (val) => setState(() => _ledgerSearchQuery = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTableHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DesktopDimensions.spacingSmall,
        horizontal: DesktopDimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(loc.date,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(loc.docNoHeader,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(loc.typeHeader,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 4,
              child: Text(loc.description,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(loc.debitHeader,
                  textAlign: TextAlign.right,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(loc.creditHeader,
                  textAlign: TextAlign.right,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text(loc.balanceHeader,
                  textAlign: TextAlign.right,
                  style: textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
          side: BorderSide(color: colorScheme.outline, width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DesktopDimensions.dialogWidth,
            maxHeight: DesktopDimensions.dialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.receivePaymentTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface),
                  decoration:
                      _cleanInput(loc.amount, Icons.money, colorScheme),
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                TextField(
                  controller: notesCtrl,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface),
                  decoration: _cleanInput(
                      loc.notesOptionalLabel, Icons.note, colorScheme),
                ),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.cancel,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize:
                            const Size(0, DesktopDimensions.buttonHeight),
                      ),
                      onPressed: () async {
                        if (amountCtrl.text.isNotEmpty) {
                          Money? amount;
                          try {
                            amount =
                                Money.fromRupeesString(amountCtrl.text.trim());
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.invalidAmount),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                            return;
                          }
                          if (amount > const Money(0)) {
                            Navigator.pop(context);
                            try {
                              await _addPayment(amount, notesCtrl.text);
                            } catch (e) {
                              if (!mounted) return;
                              _showSnack(
                                loc.errorMessage(e.toString()),
                                colorScheme.error,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.invalidAmount),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(loc.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      amountCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  // --- ARCHIVE OVERLAY ---
  Widget _buildArchiveOverlay(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (!_showArchiveOverlay) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showArchiveOverlay = false),
          child: Container(color: colorScheme.shadow.withOpacity(0.5)),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.cardBorderRadius),
              border: Border.all(color: colorScheme.outline, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.archivedCustomers,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () =>
                          setState(() => _showArchiveOverlay = false),
                    ),
                  ],
                ),
                Divider(color: colorScheme.primary),
                Expanded(
                  child: archivedCustomers.isEmpty
                      ? Center(
                          child: Text(
                            loc.noCustomersFound,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                        )
                      : ListView.builder(
                          itemCount: archivedCustomers.length,
                          itemBuilder: (context, index) => _buildCustomerCard(
                            archivedCustomers[index],
                            colorScheme,
                            textTheme,
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

  // --- ADD/EDIT DIALOG ---
  void _showAddDialog({Customer? customer}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final nameEnController =
        TextEditingController(text: customer?.nameEnglish ?? '');
    final nameUrController =
        TextEditingController(text: customer?.nameUrdu ?? '');
    final phoneController =
        TextEditingController(text: customer?.contactPrimary ?? '');
    final addressController =
        TextEditingController(text: customer?.address ?? '');
    String currentLimit = (customer?.creditLimit ?? 0).toString();
    final limitController =
        TextEditingController(text: currentLimit == "0" ? "" : currentLimit);
    bool isSaving = false;
    final bool isEdit = customer != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
                side: BorderSide(color: colorScheme.outline, width: 2),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesktopDimensions.dialogWidth,
                  maxHeight: DesktopDimensions.dialogHeight,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(DesktopDimensions.dialogPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer == null ? loc.addCustomer : loc.editCustomer,
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: DesktopDimensions.spacingLarge),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: nameEnController,
                                decoration: _cleanInput("${loc.nameEnglish} *",
                                    Icons.person, colorScheme),
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                                readOnly: isEdit,
                                enabled: !isEdit,
                              ),
                              const SizedBox(
                                  height: DesktopDimensions.spacingMedium),
                              TextFormField(
                                controller: nameUrController,
                                textAlign: TextAlign.start,
                                decoration: _cleanInput("${loc.nameUrdu} *",
                                    Icons.translate, colorScheme),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'NooriNastaleeq',
                                  fontSize: DesktopDimensions.bodyLargeSize,
                                  color: colorScheme.onSurface,
                                ),
                                readOnly: isEdit,
                                enabled: !isEdit,
                              ),
                              const SizedBox(
                                  height: DesktopDimensions.spacingMedium),
                              TextFormField(
                                controller: phoneController,
                                decoration: _cleanInput("${loc.phoneLabel} *",
                                    Icons.phone, colorScheme),
                                keyboardType: TextInputType.phone,
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                                readOnly: isEdit,
                                enabled: !isEdit,
                              ),
                              const SizedBox(
                                  height: DesktopDimensions.spacingMedium),
                              TextFormField(
                                controller: addressController,
                                decoration: _cleanInput(loc.addressLabel,
                                    Icons.location_on, colorScheme),
                                maxLines: 2,
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                              ),
                              const SizedBox(
                                  height: DesktopDimensions.spacingMedium),
                              TextFormField(
                                controller: limitController,
                                decoration: _cleanInput(loc.creditLimit,
                                    Icons.credit_card, colorScheme),
                                keyboardType: TextInputType.number,
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DesktopDimensions.spacingLarge),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                isSaving ? null : () => Navigator.pop(context),
                            child: Text(loc.cancel,
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onSurface)),
                          ),
                          const SizedBox(
                              width: DesktopDimensions.spacingStandard),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              minimumSize:
                                  const Size(0, DesktopDimensions.buttonHeight),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (nameEnController.text.trim().isEmpty) {
                                      _showSnack(
                                          "${loc.nameEnglish} ${loc.requiredField}",
                                          colorScheme.error);
                                      return;
                                    }
                                    if (nameUrController.text.trim().isEmpty) {
                                      _showSnack(
                                          "${loc.nameUrdu} ${loc.requiredField}",
                                          colorScheme.error);
                                      return;
                                    }
                                    if (phoneController.text.trim().isEmpty) {
                                      _showSnack(
                                          "${loc.phoneLabel} ${loc.requiredField}",
                                          colorScheme.error);
                                      return;
                                    }

                                    setStateDialog(() => isSaving = true);
                                    try {
                                      await _addOrUpdateCustomer(
                                        id: customer?.id,
                                        nameEng: nameEnController.text.trim(),
                                        nameUrdu: nameUrController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        address: addressController.text.trim(),
                                        limit: Money.fromRupeesString(
                                                limitController.text)
                                            .paisas,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      setStateDialog(() => isSaving = false);
                                      _showSnack(
                                          e
                                              .toString()
                                              .replaceAll("Exception: ", ""),
                                          colorScheme.error);
                                    }
                                  },
                            child: isSaving
                                ? SizedBox(
                                    width: DesktopDimensions.iconSizeMedium,
                                    height: DesktopDimensions.iconSizeMedium,
                                    child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary),
                                  )
                                : Text(loc.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameEnController.dispose();
      nameUrController.dispose();
      phoneController.dispose();
      addressController.dispose();
      limitController.dispose();
    });
  }

  InputDecoration _cleanInput(
      String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.primary),
      prefixIcon: Icon(icon,
          size: DesktopDimensions.iconSizeMedium, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(DesktopDimensions.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(DesktopDimensions.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: DesktopDimensions.spacingMedium,
        horizontal: DesktopDimensions.spacingMedium,
      ),
      isDense: true,
    );
  }
}

// --- LEDGER ROW WIDGET ---
// PRESERVED AS PROVIDED (no UI violations in this class)

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
  bool _isLoadingItems = false;
  String? _error;

  Future<void> _toggleExpand() async {
    if (widget.row['type'] != 'SALE') return;

    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded && _items == null) {
      setState(() => _isLoadingItems = true);
      setState(() => _error = null);
      try {
        final invoiceId = _tryParseInt(widget.row['ref_no']);
        if (invoiceId == null) {
          if (mounted) {
            setState(() => _error = AppLocalizations.of(context)!.failedToLoadDetails);
          }
          return;
        }
        final invoice =
            await widget.invoiceRepository.getInvoiceWithItems(invoiceId);
        if (mounted) setState(() => _items = invoice?.items);
      } catch (e) {
        if (mounted) {
          setState(() => _error = AppLocalizations.of(context)!.failedToLoadDetails);
        }
      } finally {
        if (mounted) setState(() => _isLoadingItems = false);
      }
    }
  }

  Future<void> _cancelInvoice() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DesktopDimensions.dialogWidth,
            maxHeight: DesktopDimensions.dialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.confirmCancellationTitle,
                  style: textTheme.titleLarge
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                Text(
                  AppLocalizations.of(context)!.confirmCancelInvoiceMessage,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.no,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        minimumSize:
                            const Size(0, DesktopDimensions.buttonHeight),
                      ),
                      child: Text(AppLocalizations.of(context)!.yesCancelButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final invoiceId = _tryParseInt(widget.row['ref_no']);
        if (invoiceId == null) {
          throw StateError('Invalid invoice id for cancellation');
        }
        await widget.invoiceRepository.cancelInvoice(
          invoiceId: invoiceId,
          cancelledBy: 'User',
          reason: 'Cancelled from customer ledger',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.invoiceCancelledSuccess),
              backgroundColor: colorScheme.primary,
            ),
          );
        }
        widget.onInvoiceCancelled();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorMessage(e.toString())),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    final Money debit = Money(_tryParseInt(row['debit']) ?? 0);
    final Money credit = Money(_tryParseInt(row['credit']) ?? 0);
    final Money balance = Money(_tryParseInt(row['balance']) ?? 0);
    final isSale = row['type'] == 'SALE';
    final isReceipt = row['type'] == 'PAYMENT' || row['type'] == 'RECEIPT';

    final bgColor = _isExpanded
        ? colorScheme.primaryContainer.withOpacity(0.1)
        : (isReceipt
            ? colorScheme.primaryContainer.withOpacity(0.05)
            : (widget.isEven
                ? colorScheme.surface
                : colorScheme.surfaceVariant));

    return Column(
      children: [
        InkWell(
          onTap: isSale ? _toggleExpand : null,
          hoverColor: colorScheme.primaryContainer.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: DesktopDimensions.spacingSmall,
              horizontal: DesktopDimensions.spacingMedium,
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
                    child: Text(dateStr,
                        style: textTheme.bodySmall
                            ?.copyWith(fontFamily: 'RobotoMono'))),
                Expanded(
                    flex: 2,
                    child: Text(
                        isSale
                            ? "INV-${row['ref_no']}"
                            : "RCP-${row['ref_no']}",
                        style: textTheme.bodySmall
                            ?.copyWith(fontFamily: 'RobotoMono'))),
                Expanded(
                    flex: 2,
                    child: Text(
                      isSale
                          ? AppLocalizations.of(context)!.saleType
                          : AppLocalizations.of(context)!.receiptType,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isSale ? colorScheme.primary : colorScheme.tertiary,
                      ),
                    )),
                Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        if (isSale)
                          Icon(
                            _isExpanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: DesktopDimensions.iconSizeSmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        Expanded(
                          child: Text(
                            row['description'] ?? '',
                            style: textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSale)
                          IconButton(
                            icon: Icon(
                              Icons.cancel,
                              color: colorScheme.error,
                              size: DesktopDimensions.iconSizeSmall,
                            ),
                            tooltip:
                                AppLocalizations.of(context)!.cancelInvoiceTooltip,
                            onPressed: _cancelInvoice,
                          ),
                      ],
                    )),
                Expanded(
                    flex: 2,
                    child: Text(
                      debit > const Money(0) ? debit.toString() : '-',
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall
                          ?.copyWith(fontFamily: 'RobotoMono'),
                    )),
                Expanded(
                    flex: 2,
                    child: Text(
                      credit > const Money(0) ? credit.toString() : '-',
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
                        color: balance > const Money(0)
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
            color: colorScheme.surfaceVariant,
            padding: const EdgeInsets.fromLTRB(
              DesktopDimensions.spacingXXLarge,
              DesktopDimensions.spacingSmall,
              DesktopDimensions.spacingMedium,
              DesktopDimensions.spacingMedium,
            ),
            child: _isLoadingItems
                ? const Center(
                    child: SizedBox(
                      width: DesktopDimensions.iconSizeMedium,
                      height: DesktopDimensions.iconSizeMedium,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                      )
                    : _items == null || _items!.isEmpty
                        ? Center(
                            child: Text(
                              "No items found",
                              style: textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Table(
                                border: TableBorder(
                                    bottom:
                                        BorderSide(color: colorScheme.outline)),
                                columnWidths: const {
                                  0: FlexColumnWidth(4),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(2),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(
                                            DesktopDimensions.spacingXSmall),
                                        child: Text(
                                            AppLocalizations.of(context)!.item,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(
                                            DesktopDimensions.spacingXSmall),
                                        child: Text(
                                            AppLocalizations.of(context)!.qty,
                                            textAlign: TextAlign.center,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(
                                            DesktopDimensions.spacingXSmall),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .rateHeader,
                                            textAlign: TextAlign.right,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(
                                            DesktopDimensions.spacingXSmall),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .totalHeader,
                                            textAlign: TextAlign.right,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  ..._items!.map((item) => TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(
                                                DesktopDimensions
                                                    .spacingXSmall),
                                            child: Text(item.itemNameSnapshot,
                                                style: textTheme.bodySmall),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(
                                                DesktopDimensions
                                                    .spacingXSmall),
                                            child: Text(
                                              item.quantity.toString(),
                                              textAlign: TextAlign.center,
                                              style: textTheme.bodySmall,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(
                                                DesktopDimensions
                                                    .spacingXSmall),
                                            child: Text(
                                              Money(item.unitPrice).toString(),
                                              textAlign: TextAlign.right,
                                              style: textTheme.bodySmall,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(
                                                DesktopDimensions
                                                    .spacingXSmall),
                                            child: Text(
                                              Money(item.totalPrice).toString(),
                                              textAlign: TextAlign.right,
                                              style: textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      )),
                                ],
                              ),
                            ],
                          ),
          ),
      ],
    );
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
