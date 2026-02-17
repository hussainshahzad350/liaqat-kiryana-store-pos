import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../core/constants/desktop_dimensions.dart';
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
  final creditLimitCtrl = TextEditingController(text: '0');

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
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
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
            const SizedBox(height: DesktopDimensions.spacingMedium),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameEngCtrl,
                        decoration:
                            InputDecoration(labelText: loc.nameEnglish)),
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                    TextField(
                        controller: nameUrduCtrl,
                        decoration: InputDecoration(labelText: loc.nameUrdu)),
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                    TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: loc.phoneNum)),
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                    TextField(
                        controller: addressCtrl,
                        decoration: InputDecoration(labelText: loc.address)),
                    const SizedBox(height: DesktopDimensions.spacingMedium),
                    TextField(
                        controller: creditLimitCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: loc.creditLimit)),
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
                    child: Text(loc.cancel)),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary),
                  onPressed: () {
                    // Validation
                    if (nameEngCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.nameRequired)));
                      return;
                    }
                    String phoneNumber = phoneCtrl.text.trim();
                    if (phoneNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.phoneRequired)));
                      return;
                    }

                    try {
                      final creditLimit =
                          Money.fromRupeesString(creditLimitCtrl.text);

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
                  child: Text(loc.saveSelect),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
