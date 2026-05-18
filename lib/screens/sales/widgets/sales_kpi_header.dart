import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/cash_repository.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../core/repositories/items_repository.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/invoice_model.dart';
import '../../../widgets/app_shell.dart';

class SalesKpiHeader extends StatefulWidget {
  const SalesKpiHeader({super.key});

  @override
  State<SalesKpiHeader> createState() => _SalesKpiHeaderState();
}

class _SalesKpiHeaderState extends State<SalesKpiHeader> {
  /// Keep KPIs near-live without re-querying every frame.
  static const Duration _refreshInterval = Duration(minutes: 5);

  Timer? _timer;

  int _todaySales = 0;
  int _lowStockCount = 0;
  Money _cashBalance = Money.zero;
  Invoice? _latestInvoice;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(_refreshInterval, (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final cashRepository = context.read<CashRepository>();
    final invoiceRepository = context.read<InvoiceRepository>();
    final itemsRepository = context.read<ItemsRepository>();

    try {
      final results = await Future.wait([
        invoiceRepository.getTodaySalesTotal(),
        itemsRepository.getLowStockCount(),
        invoiceRepository.getRecentInvoicesWithCustomer(limit: 1),
        cashRepository.getCurrentCashBalance(),
      ]);

      if (!mounted) return;
      final recentInvoices = results[2] as List<Invoice>;
      setState(() {
        _todaySales = results[0] as int;
        _lowStockCount = results[1] as int;
        _latestInvoice = recentInvoices.isNotEmpty ? recentInvoices.first : null;
        _cashBalance = results[3] as Money;
        _loading = false;
        _hasError = false;
      });
    } catch (e, st) {
      debugPrint('SalesKpiHeader load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final latestInvoiceDisplay = _latestInvoice?.invoiceNumber ?? loc.noSalesYet;

    return Container(
      height: 46,
      width: double.infinity,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _loading
          ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_hasError) ...[
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _KpiChip(
                    icon: Icons.point_of_sale,
                    label: loc.todaySales,
                    value: Money(_todaySales).formattedNoDecimal,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.receipt_long,
                    label: loc.recentSales,
                    value: latestInvoiceDisplay,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.warning_amber_rounded,
                    label: loc.lowStockCount,
                    value: _lowStockCount.toString(),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () => AppShell.navigateTo(context, AppRoutes.stock),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.account_balance_wallet,
                    label: loc.cashSnapshot,
                    value: _cashBalance.formattedNoDecimal,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () =>
                        AppShell.navigateTo(context, AppRoutes.cashLedger),
                  ),
                ],
              ),
            ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: child,
    );
  }
}
