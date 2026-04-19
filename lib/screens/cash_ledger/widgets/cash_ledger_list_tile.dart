import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/cash_ledger_model.dart';
import '../../../../domain/entities/money.dart';
import '../../../../core/res/app_tokens.dart';

class CashLedgerListTile extends StatelessWidget {
  final CashLedger entry;

  const CashLedgerListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isIncome = entry.isInflow;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome
                ? colorScheme.primaryContainer
                : colorScheme.errorContainer,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? colorScheme.primary : colorScheme.error,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.description,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSmall),
              // Payment Mode Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingSmall,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: entry.paymentMode.isCash
                      ? colorScheme.tertiaryContainer
                      : colorScheme.secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppTokens.badgeBorderRadius),
                ),
                child: Text(
                  entry.paymentMode.dbValue,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: entry.paymentMode.isCash
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            [
              DateFormat.yMMMd(Localizations.localeOf(context).toString())
                  .format(entry.transactionDate),
              if (entry.transactionTime?.isNotEmpty ?? false)
                entry.transactionTime!,
            ].join(' | '),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isIncome
                    ? loc.ledgerAmountIn(Money(entry.amount).formattedNoDecimal)
                    : loc.ledgerAmountOut(
                        Money(entry.amount).formattedNoDecimal),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? colorScheme.primary : colorScheme.error,
                ),
              ),
              if (entry.balanceAfter != null)
                Text(
                  loc.balanceShort(
                      Money(entry.balanceAfter!).formattedNoDecimal),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
