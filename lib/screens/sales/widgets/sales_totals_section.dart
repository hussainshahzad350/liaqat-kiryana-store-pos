import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';

class SalesTotalsSection extends StatelessWidget {
  final TextEditingController discountController;
  final Money subtotal;
  final Money discount;
  final Money previousBalance;
  final Money grandTotal;
  final bool isCheckoutEnabled;
  final VoidCallback onCheckout;
  final Function(String) onDiscountChanged;

  const SalesTotalsSection({
    super.key,
    required this.discountController,
    required this.subtotal,
    required this.discount,
    required this.previousBalance,
    required this.grandTotal,
    required this.isCheckoutEnabled,
    required this.onCheckout,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: AppTokens.spacingSmall,
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(
              width: double.infinity,
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(loc.subtotal, style: textTheme.bodyLarge),
                    Text(subtotal.toString(),
                        textDirection: TextDirection.ltr,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ))
                  ])),
          const SizedBox(height: AppTokens.spacingStandard),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.discount, style: textTheme.bodyLarge),
            SizedBox(
              width: 120,
              height: AppTokens.controlMinHeight,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spacingStandard,
                      horizontal: AppTokens.spacingStandard),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.buttonBorderRadius)),
                  hintText: '0',
                ),
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                onChanged: onDiscountChanged,
              ),
            ),
          ]),
          if (previousBalance > const Money(0))
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingStandard),
              child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(loc.prevBalance,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.error)),
                        Text(previousBalance.toString(),
                            textDirection: TextDirection.ltr,
                            style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold))
                      ])),
            ),
          const SizedBox(height: AppTokens.spacingStandard),
          const Divider(),
          const SizedBox(height: AppTokens.spacingStandard),
          SizedBox(
              width: double.infinity,
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(loc.grandTotal.toUpperCase(),
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(grandTotal.toString(),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.end,
                        style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary))
                  ])),
          const SizedBox(height: AppTokens.spacingMedium),
          ConstrainedBox(
            constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: AppTokens.controlMinHeight),
            child: ElevatedButton(
              onPressed: isCheckoutEnabled ? onCheckout : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: AppTokens.iconSizeLarge),
                  const SizedBox(width: AppTokens.spacingStandard),
                  Flexible(
                      child: Text(
                    loc.checkoutButton.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCheckoutEnabled
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant),
                  )),
                  const SizedBox(width: AppTokens.spacingStandard),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingSmall,
                        vertical: AppTokens.spacingXSmall),
                    decoration: BoxDecoration(
                      color: (isCheckoutEnabled
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface)
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTokens.smallBorderRadius),
                    ),
                    child: Text(
                      "F9",
                      style: textTheme.bodySmall?.copyWith(
                          color: isCheckoutEnabled
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
