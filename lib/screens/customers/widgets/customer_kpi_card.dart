import 'package:flutter/material.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/res/app_tokens.dart';

class CustomerKpiCard extends StatelessWidget {
  final String title;
  final int count;
  final Money balance;
  final VoidCallback? onTap;
  final bool isTertiary;

  const CustomerKpiCard({
    super.key,
    required this.title,
    required this.count,
    required this.balance,
    this.onTap,
    this.isTertiary = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final containerColor = isTertiary
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final contentColor = isTertiary
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;
    final borderColor = isTertiary ? colorScheme.tertiary : colorScheme.primary;

    return Card(
      elevation: AppTokens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      color: containerColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.cardPadding),
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
                  Icon(Icons.people,
                      size: AppTokens.iconSizeLarge, color: contentColor),
                  Flexible(
                    child: Text(
                      '$count',
                      style: textTheme.titleMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                loc.balanceShort(balance),
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
}
