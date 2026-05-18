import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/sales_kpi_service.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_shell.dart';

class SalesKpiHeader extends StatefulWidget {
  const SalesKpiHeader({
    super.key,
    required this.service,
  });

  final SalesKpiService service;

  @override
  State<SalesKpiHeader> createState() => _SalesKpiHeaderState();
}

class _SalesKpiHeaderState extends State<SalesKpiHeader> {
  static const double _headerHeight = 46;
  final String _zeroCashDisplay = Money.zero.formattedNoDecimal;

  SalesKpiSnapshot? _snapshot;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final snapshot =
          await widget.service.getSnapshot(forceRefresh: forceRefresh);

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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

    final recentInvoiceLabel =
        _snapshot?.latestInvoice?.invoiceNumber ?? loc.noSalesYet;
    final todaySalesValue = _snapshot?.todaySalesTotal ?? 0;
    final lowStockValue = _snapshot?.lowStockCount ?? 0;
    final cashSnapshotValue =
        _snapshot?.cashSnapshot.formattedNoDecimal ?? _zeroCashDisplay;

    return Container(
      height: _headerHeight,
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
                  IconButton(
                    tooltip: loc.refresh,
                    onPressed: () => _loadData(forceRefresh: true),
                    icon:
                        Icon(Icons.refresh, size: 16, color: colorScheme.primary),
                  ),
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
                    value: Money(todaySalesValue).formattedNoDecimal,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.receipt_long,
                    label: loc.latestInvoice,
                    value: recentInvoiceLabel,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.warning_amber_rounded,
                    label: loc.lowStockCount,
                    value: lowStockValue.toString(),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onTap: () => AppShell.navigateTo(context, AppRoutes.stock),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    icon: Icons.account_balance_wallet,
                    label: loc.cashSnapshot,
                    value: cashSnapshotValue,
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
