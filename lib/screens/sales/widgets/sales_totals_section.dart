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
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: AppTokens.spacingSmall,
          )
        ],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.subtotal, style: textTheme.bodyLarge),
            Text(subtotal.toString(),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ))
          ]),
          const SizedBox(height: AppTokens.spacingStandard),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.discount, style: textTheme.bodyLarge),
            SizedBox(
              width: 120,
              height: AppTokens.buttonHeight,
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
                      borderRadius: BorderRadius.circular(
                          AppTokens.buttonBorderRadius)),
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
              padding:
                  const EdgeInsets.only(top: AppTokens.spacingStandard),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.prevBalance,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colorScheme.error)),
                    Text(previousBalance.toString(),
                        style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold))
                  ]),
            ),
          const SizedBox(height: AppTokens.spacingStandard),
          const Divider(),
          const SizedBox(height: AppTokens.spacingStandard),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc.grandTotal.toUpperCase(),
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(grandTotal.toString(),
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: colorScheme.primary))
          ]),
          const SizedBox(height: AppTokens.spacingMedium),
          SizedBox(
            width: double.infinity,
            height: AppTokens.buttonHeight * 1.4,
            child: ElevatedButton(
              onPressed: isCheckoutEnabled ? onCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: AppTokens.cardElevation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppTokens.cardBorderRadius)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment,
                      size: AppTokens.iconSizeXLarge),
                  const SizedBox(width: AppTokens.spacingStandard),
                  Text(
                    loc.checkoutButton.toUpperCase(),
                    style: textTheme.titleLarge
                        ?.copyWith(color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: AppTokens.spacingStandard),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingSmall,
                        vertical: AppTokens.spacingXSmall),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          AppTokens.smallBorderRadius),
                    ),
                    child: Text(
                      "F9",
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onPrimary),
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
