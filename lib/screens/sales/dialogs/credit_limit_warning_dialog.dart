import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/money.dart';

class CreditLimitWarningDialog extends StatelessWidget {
  final Money creditLimit;
  final Money currentBalance;
  final Money billTotal;
  final Money potentialBalance;
  final VoidCallback onContinueAnyway;
  final VoidCallback onIncreaseLimit;

  const CreditLimitWarningDialog({
    super.key,
    required this.creditLimit,
    required this.currentBalance,
    required this.billTotal,
    required this.potentialBalance,
    required this.onContinueAnyway,
    required this.onIncreaseLimit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppTokens.dialogBorderRadius)),
      child: Container(
        constraints: RTLHelper.getDialogConstraints(
          context: context,
          size: DialogSize.large,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.dialogPadding,
          vertical: RTLHelper.isRTL(context) 
              ? AppTokens.dialogPadding + 16
              : AppTokens.dialogPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: colorScheme.error),
                const SizedBox(width: AppTokens.spacingSmall),
                Text(
                  loc.creditLimitExceeded,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppTokens.spacingMedium),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.creditLimitWarningMsg(creditLimit.toString()),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTokens.spacingLarge),
                    Container(
                      padding:
                          const EdgeInsets.all(AppTokens.cardPadding),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(
                            AppTokens.cardBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(context, '${loc.customerCreditLimit}:',
                              creditLimit.toString(),
                              color: colorScheme.onErrorContainer),
                          _infoRow(context, '${loc.currentBalance}:',
                              currentBalance.toString(),
                              color: colorScheme.onErrorContainer),
                          _infoRow(context, '${loc.billTotal}:',
                              billTotal.toString(),
                              color: colorScheme.onErrorContainer),
                          Divider(
                              color: colorScheme.onErrorContainer
                                  .withOpacity(0.5)),
                          _infoRow(
                            context,
                            '${loc.totalBalance}:',
                            potentialBalance.toString(),
                            isBold: true,
                            color: colorScheme.error,
                          ),
                          const SizedBox(
                              height: AppTokens.spacingSmall),
                          Text(
                            '${loc.excessAmount}: ${(potentialBalance - creditLimit).toString()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onIncreaseLimit();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary),
                    foregroundColor: colorScheme.primary,
                  ),
                  child: Text(loc.increaseLimit),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onContinueAnyway();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: Text(loc.continueAnyway),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel,
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {bool isBold = false, double? size, Color? color}) {
    final textTheme = Theme.of(context).textTheme;
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    TextStyle? baseStyle;
    if (size == null) {
      baseStyle = textTheme.bodyMedium;
    } else if (size >= 24.0) {
      baseStyle = textTheme.titleMedium;
    } else if (size >= (textTheme.bodyLarge?.fontSize ?? 16.0)) {
      baseStyle = textTheme.bodyLarge;
    } else {
      baseStyle = textTheme.bodyMedium;
    }

    final finalStyle = baseStyle?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? defaultColor,
      fontSize: size,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppTokens.spacingXXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: finalStyle),
          Text(value, style: finalStyle),
        ],
      ),
    );
  }
}
