import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/money.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final nameEngCtrl = TextEditingController();
  final nameUrduCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final creditLimitCtrl = TextEditingController();

  @override
  void dispose() {
    nameEngCtrl.dispose();
    nameUrduCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    creditLimitCtrl.dispose();
    super.dispose();
  }

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
          size: DialogSize.medium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.dialogPadding,
          vertical: RTLHelper.isRTL(context)
              ? AppTokens.dialogPadding + 12
              : AppTokens.dialogPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.addNewCustomer,
                    style: Theme.of(context).textTheme.titleLarge),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameEngCtrl,
                        textAlign: TextAlign.center,
                        decoration:
                            InputDecoration(labelText: '${loc.nameEnglish} *')),
                    const SizedBox(height: AppTokens.spacingLarge),
                    TextField(
                        controller: nameUrduCtrl,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(labelText: '${loc.nameUrdu} *')),
                    const SizedBox(height: AppTokens.spacingLarge),
                    TextField(
                        controller: phoneCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: '${loc.phoneNum} *')),
                    const SizedBox(height: AppTokens.spacingLarge),
                    TextField(
                        controller: addressCtrl,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(labelText: '${loc.address} *')),
                    const SizedBox(height: AppTokens.spacingLarge),
                    TextField(
                        controller: creditLimitCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: '${loc.creditLimit} *')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel)),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(120, 48)),
                  onPressed: () {
                    // Validation
                    if (nameEngCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.nameRequired)));
                      return;
                    }
                    if (nameUrduCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.urduNameRequired)));
                      return;
                    }
                    String phoneNumber = phoneCtrl.text.trim();
                    if (phoneNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.phoneRequired)));
                      return;
                    }
                    if (addressCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.addressRequired)));
                      return;
                    }

                    try {
                      final creditText = creditLimitCtrl.text.trim();
                      if (creditText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(loc.creditLimitRequired)));
                        return;
                      }

                      final creditLimit =
                          Money.fromRupeesString(creditText);

                      context.read<SalesBloc>().add(
                            QuickCustomerAddRequested(
                              nameEnglish: nameEngCtrl.text.trim(),
                              nameUrdu: nameUrduCtrl.text.trim(),
                              phone: phoneNumber,
                              address: addressCtrl.text.trim(),
                              creditLimitPaisas: creditLimit.paisas,
                            ),
                          );
                      Navigator.of(context).pop();
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(loc.invalidAmount),
                          backgroundColor: colorScheme.error));
                      return;
                    }
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(loc.saveSelect),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
