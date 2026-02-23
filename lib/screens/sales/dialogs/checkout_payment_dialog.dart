import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/money.dart';
import 'credit_limit_warning_dialog.dart';
import 'increase_limit_dialog.dart';
import '../../../core/utils/rtl_helper.dart';

class CheckoutPaymentDialog extends StatefulWidget {
  final bool ignoreCreditLimit;

  const CheckoutPaymentDialog({
    super.key,
    this.ignoreCreditLimit = false,
  });

  @override
  State<CheckoutPaymentDialog> createState() => _CheckoutPaymentDialogState();
}

class _CheckoutPaymentDialogState extends State<CheckoutPaymentDialog> {
  final cashCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final creditCtrl = TextEditingController();

  Money safeMoney(String text) {
    return Money.tryParse(text) ?? Money.zero;
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<SalesBloc>().state;
    final isWalkIn = state.selectedCustomer?.isWalkIn ?? true;
    if (!isWalkIn) {
      creditCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    cashCtrl.dispose();
    bankCtrl.dispose();
    creditCtrl.dispose();
    super.dispose();
  }

  void _showCreditLimitWarning({
    required Money creditLimit,
    required Money currentBalance,
    required Money billTotal,
    required Money potentialBalance,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesBloc>(),
        child: CreditLimitWarningDialog(
          creditLimit: creditLimit,
          currentBalance: currentBalance,
          billTotal: billTotal,
          potentialBalance: potentialBalance,
          onContinueAnyway: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: context.read<SalesBloc>(),
                child: const CheckoutPaymentDialog(ignoreCreditLimit: true),
              ),
            );
          },
          onIncreaseLimit: () {
            final state = context.read<SalesBloc>().state;
            final selected = state.selectedCustomer;
            final int? custId = selected?.id;
            if (custId != null) {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<SalesBloc>(),
                  child: IncreaseLimitDialog(
                    customerId: custId,
                    currentLimit: Money(selected!.creditLimit),
                    onLimitUpdated: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => BlocProvider.value(
                          value: context.read<SalesBloc>(),
                          child: const CheckoutPaymentDialog(
                              ignoreCreditLimit: true),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _processSale(
      Money cash, Money bank, Money credit, Money change) async {
    final bloc = context.read<SalesBloc>();
    final currentLanguage = Localizations.localeOf(context).languageCode;

    bloc.add(InvoiceProcessed(
      cash: cash,
      bank: bank,
      credit: credit,
      change: change,
      languageCode: currentLanguage,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.read<SalesBloc>().state;

    final customer = state.selectedCustomer;
    final bool isWalkIn = customer?.isWalkIn ?? true;
    final Money billTotal = state.grandTotal;
    final Money oldBalance = state.previousBalance;

    return StatefulBuilder(builder: (context, setDialogState) {
      final parsedCash = Money.tryParse(cashCtrl.text);
      final parsedBank = Money.tryParse(bankCtrl.text);
      final parsedCredit =
          isWalkIn ? Money.zero : Money.tryParse(creditCtrl.text);

      final cashError = parsedCash == null ? loc.invalidAmount : null;
      final bankError = parsedBank == null ? loc.invalidAmount : null;
      final creditError = parsedCredit == null ? loc.invalidAmount : null;
      final hasParseError =
          cashError != null || bankError != null || creditError != null;

      final Money cash = parsedCash ?? Money.zero;
      final Money bank = parsedBank ?? Money.zero;
      final Money credit = parsedCredit ?? Money.zero;
      Money totalPayment = cash + bank + credit;
      Money change = const Money(0);
      bool isValid = false;

      if (!hasParseError) {
        if (isWalkIn) {
          isValid = (cash + bank) >= billTotal;
          if (isValid) {
            change = (cash + bank) - billTotal;
          }
        } else {
          isValid = totalPayment == billTotal;
        }
      }

      void processSaleAction() {
        Navigator.pop(context);
        _processSale(cash, bank, credit, change);
      }

      void checkCreditLimitAndProcess() {
        if (hasParseError) return;

        if (widget.ignoreCreditLimit || isWalkIn || credit <= const Money(0)) {
          processSaleAction();
          return;
        }

        // Use BLoC logic for warning check
        if (state.shouldShowCreditWarning) {
          Navigator.pop(context);
          _showCreditLimitWarning(
            creditLimit: Money(customer!.creditLimit),
            currentBalance: oldBalance,
            billTotal: credit,
            potentialBalance: oldBalance + credit,
          );
        } else {
          processSaleAction();
        }
      }

      return Dialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
        child: Container(
          constraints: RTLHelper.getDialogConstraints(
            context: context,
            size: DialogSize.large,
          ),
          padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: colorScheme.primary),
                  const SizedBox(width: DesktopDimensions.spacingSmall),
                  Text(loc.checkoutButton,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
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
              const SizedBox(height: DesktopDimensions.spacingMedium),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isWalkIn) ...[
                        Text(
                            '${loc.searchCustomerHint}: ${RTLHelper.getLocalizedName(context: context, nameEnglish: customer?.nameEnglish ?? '', nameUrdu: customer?.nameUrdu)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: DesktopDimensions.spacingSmall),
                        Container(
                          padding: const EdgeInsets.all(
                              DesktopDimensions.spacingSmall),
                          decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(
                                  DesktopDimensions.smallBorderRadius),
                              border: Border.all(color: colorScheme.secondary)),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: DesktopDimensions.iconSizeSmall,
                                  color: colorScheme.secondary),
                              const SizedBox(
                                  width: DesktopDimensions.spacingSmall),
                              Text(
                                  '${loc.prevBalance}: ${oldBalance.toString()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: colorScheme
                                              .onSecondaryContainer)),
                            ],
                          ),
                        ),
                        const Divider(height: DesktopDimensions.spacingLarge),
                      ],
                      _infoRow(context, loc.billTotal, billTotal.toString(),
                          isBold: true,
                          size: DesktopDimensions.headingSize,
                          color: colorScheme.onSurface),
                      const Divider(),
                      const SizedBox(height: DesktopDimensions.spacingStandard),
                      Text(loc.paymentLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: DesktopDimensions.spacingStandard),
                      _input(context, loc.cashInput, cashCtrl, (v) {
                        setDialogState(() {
                          if (!isWalkIn) {
                            Money cashValue = safeMoney(cashCtrl.text);
                            Money bankValue = safeMoney(bankCtrl.text);
                            Money remaining = billTotal - cashValue - bankValue;
                            creditCtrl.text = remaining > const Money(0)
                                ? remaining.toRupeesString()
                                : '0';
                          }
                        });
                      }, errorText: cashError),
                      _input(context, loc.bankInput, bankCtrl, (v) {
                        setDialogState(() {
                          if (!isWalkIn) {
                            Money cashValue = safeMoney(cashCtrl.text);
                            Money bankValue = safeMoney(bankCtrl.text);
                            Money remaining = billTotal - cashValue - bankValue;
                            creditCtrl.text = remaining > const Money(0)
                                ? remaining.toRupeesString()
                                : '0';
                          }
                        });
                      }, errorText: bankError),
                      if (!isWalkIn)
                        _input(context, loc.creditInput, creditCtrl, (v) {
                          setDialogState(() {});
                        }, errorText: creditError),
                      const SizedBox(height: DesktopDimensions.spacingStandard),
                      if (isWalkIn)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.changeDue,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(change.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: change >= const Money(0)
                                            ? colorScheme.primary
                                            : colorScheme.error)),
                          ],
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: DesktopDimensions.spacingMedium),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: isValid ? checkCreditLimitAndProcess : null,
                    child: Text(loc.savePrint),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {bool isBold = false, double? size, Color? color}) {
    final textTheme = Theme.of(context).textTheme;
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    TextStyle? baseStyle;
    if (size == null) {
      baseStyle = textTheme.bodyMedium;
    } else if (size >= DesktopDimensions.headingSize) {
      baseStyle = textTheme.titleMedium;
    } else if (size >= DesktopDimensions.bodyLargeSize) {
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
          vertical: DesktopDimensions.spacingXXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: finalStyle),
          Text(value, style: finalStyle),
        ],
      ),
    );
  }

  Widget _input(BuildContext context, String label, TextEditingController ctrl,
      Function(String) onChanged,
      {bool enabled = true, String? errorText}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopDimensions.spacingStandard),
      child: Row(children: [
        SizedBox(
            width: DesktopDimensions.labelWidthStandard,
            child: Text(label, style: textTheme.bodyLarge)),
        Expanded(
          child: SizedBox(
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: ctrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingStandard),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.formFieldBorderRadius)),
                prefixText: 'Rs ',
                filled: !enabled,
                fillColor: enabled ? null : colorScheme.surfaceVariant,
                errorText: errorText,
              ),
              style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}
