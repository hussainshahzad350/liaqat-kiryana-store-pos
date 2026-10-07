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
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title, style: textTheme.bodySmall)),
                      const SizedBox(width: 8),
                      Text('$count',
                          style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isTertiary
                                  ? colorScheme.tertiary
                                  : colorScheme.primary))
                    ]),
                    const SizedBox(height: 4),
                    Text(loc.balanceShort(balance),
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]))),
    );
  }
}
