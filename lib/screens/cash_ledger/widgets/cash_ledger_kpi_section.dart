import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/money.dart';
import '../../../../core/res/app_tokens.dart';
import '../controller/cash_ledger_controller.dart';

class CashLedgerKpiSection extends StatelessWidget {
  const CashLedgerKpiSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<CashLedgerController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge),
          child: Row(
            children: [
              Expanded(
                child: _CashLedgerKpiCard(
                  title: loc.dashboardTotal, // "Total Inflow"
                  amount: controller.totalInflow,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: _CashLedgerKpiCard(
                  title: "Digital Collections", // Needs arb
                  amount: controller.totalDigitalIn,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: _CashLedgerKpiCard(
                  title: "Cash In Drawer",
                  amount: controller.cashInDrawer,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CashLedgerKpiCard extends StatelessWidget {
  final String title;
  final Money amount;
  final bool isPrimary;

  const _CashLedgerKpiCard({
    required this.title,
    required this.amount,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppTokens.cardElevation,
      color: isPrimary ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spacingSmall),
            Text(
              amount.formattedNoDecimal,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
