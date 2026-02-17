import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/money.dart';
import 'credit_limit_warning_dialog.dart';
import 'increase_limit_dialog.dart';

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

  Money? _tryParseMoney(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return Money.zero;
    final validPattern = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!validPattern.hasMatch(normalized)) {
      return null;
    }
    return Money.fromRupeesString(normalized);
  }

  Money safeMoney(String text) {
    return _tryParseMoney(text) ?? Money.zero;
  }

  @override
  void initState() {
    super.initState();
    // Initialize fields if needed, or leave empty
    // Logic from _showCheckoutPaymentDialog:
    // if (!isWalkInCustomer) { creditCtrl.text = '0'; }
    final state = context.read<SalesBloc>().state;
    final isWalkInCustomer =
      state.selectedCustomer == null || state.selectedCustomer?.id == 1;
    if (!isWalkInCustomer) {
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
            // Re-show checkout dialog with ignoreCreditLimit = true
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
                      // Re-show checkout dialog with ignoreCreditLimit = true
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

    final selectedCustomerMap = state.selectedCustomer;
    final isWalkInCustomer =
        selectedCustomerMap == null || selectedCustomerMap.id == 1;
    final Money billTotal = state.grandTotal;
    final Money oldBalance = state.previousBalance;

    return StatefulBuilder(builder: (context, setDialogState) {
      final parsedCash = _tryParseMoney(cashCtrl.text);
      final parsedBank = _tryParseMoney(bankCtrl.text);
      final parsedCredit = _tryParseMoney(creditCtrl.text);
      final cashError = parsedCash == null ? loc.invalidAmount : null;
      final bankError = parsedBank == null ? loc.invalidAmount : null;
      final creditError = parsedCredit == null ? loc.invalidAmount : null;
      final hasParseError = cashError != null ||
          bankError != null ||
          (!isWalkInCustomer && creditError != null);

      final Money cash = parsedCash ?? Money.zero;
      final Money bank = parsedBank ?? Money.zero;
      final Money credit = parsedCredit ?? Money.zero;
      Money totalPayment = cash + bank + credit;
      Money change = const Money(0);
      bool isValid = false;

      if (hasParseError) {
        isValid = false;
      } else if (!isWalkInCustomer) {
        isValid = totalPayment == billTotal;
      } else {
        isValid = (cash + bank) >= billTotal;
        if (isValid) {
          change = (cash + bank) - billTotal;
        }
      }

      void processSaleAction() {
        Navigator.pop(context);
        _processSale(cash, bank, credit, change);
      }

      void checkCreditLimitAndProcess() {
        if (hasParseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.invalidAmount),
              backgroundColor: colorScheme.error,
            ),
          );
          return;
        }

        if (widget.ignoreCreditLimit) {
          processSaleAction();
          return;
        }

        if (isWalkInCustomer || credit <= const Money(0)) {
          processSaleAction();
          return;
        }

        final selectedCustomer = selectedCustomerMap;
        final Money creditLimit = Money(selectedCustomer.creditLimit);
        final Money potentialBalance = oldBalance + credit;

        if (potentialBalance > creditLimit) {
          Navigator.pop(context); // Close current dialog
          _showCreditLimitWarning(
            creditLimit: creditLimit,
            currentBalance: oldBalance,
            billTotal: credit,
            potentialBalance: potentialBalance,
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
          constraints: BoxConstraints(
            minWidth: DesktopDimensions.dialogWidth * 1.5,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
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
                      if (!isWalkInCustomer) ...[
                        Text(
                            '${loc.searchCustomerHint}: ${selectedCustomerMap.nameEnglish}',
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
                          if (!isWalkInCustomer) {
                            Money cash = safeMoney(cashCtrl.text);
                            Money bank = safeMoney(bankCtrl.text);
                            Money remaining = billTotal - cash - bank;
                            creditCtrl.text = remaining > const Money(0)
                                ? remaining.toRupeesString()
                                : '0';
                          }
                        });
                      }, errorText: cashError),
                      _input(context, loc.bankInput, bankCtrl, (v) {
                        setDialogState(() {
                          if (!isWalkInCustomer) {
                            Money cash = safeMoney(cashCtrl.text);
                            Money bank = safeMoney(bankCtrl.text);
                            Money remaining = billTotal - cash - bank;
                            creditCtrl.text = remaining > const Money(0)
                                ? remaining.toRupeesString()
                                : '0';
                          }
                        });
                      }, errorText: bankError),
                      if (!isWalkInCustomer)
                        _input(context, loc.creditInput, creditCtrl, (v) {
                          setDialogState(() {});
                        }, errorText: creditError),
                      const SizedBox(height: DesktopDimensions.spacingStandard),
                      if (isWalkInCustomer)
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
