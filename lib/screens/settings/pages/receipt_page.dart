import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../widgets/option_switch.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final prefs = state.preferences;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              SettingSection(
                title: loc.receiptOptions,
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: [
                    OptionSwitch(
                      title: loc.showLogo,
                      value: prefs['showLogo'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showLogo': v}),
                    ),
                    OptionSwitch(
                      title: loc.showShopAddress,
                      value: prefs['showAddress'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showAddress': v}),
                    ),
                    OptionSwitch(
                      title: loc.showPhone,
                      value: prefs['showPhone'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showPhone': v}),
                    ),
                    OptionSwitch(
                      title: loc.showDateTime,
                      value: prefs['showDateTime'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showDateTime': v}),
                    ),
                    OptionSwitch(
                      title: loc.showCustomerDetails,
                      value: prefs['showCustomer'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showCustomer': v}),
                    ),
                    OptionSwitch(
                      title: loc.showPaymentDetails,
                      value: prefs['showPayment'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'showPayment': v}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.printerSettings,
                icon: Icons.print_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.fontSize, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: prefs['receiptFontSize'] ?? 'medium',
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'small', child: Text(loc.small)),
                        DropdownMenuItem(value: 'medium', child: Text(loc.medium)),
                        DropdownMenuItem(value: 'large', child: Text(loc.large)),
                      ],
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'receiptFontSize': v}),
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    Text(loc.paperWidth, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: prefs['paperWidth'] ?? '80mm',
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: '58mm', child: Text(loc.paper58)),
                        DropdownMenuItem(value: '80mm', child: Text(loc.paper80)),
                        DropdownMenuItem(value: 'A4', child: Text(loc.paperA4)),
                      ],
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'paperWidth': v}),
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    Text(loc.selectPrinter, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: prefs['printerType'] ?? 'usb',
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'default', child: Text(loc.printerDefault)),
                        DropdownMenuItem(value: 'usb', child: Text(loc.printerUsb)),
                        DropdownMenuItem(value: 'network', child: Text(loc.printerNetwork)),
                        DropdownMenuItem(value: 'pdf', child: Text(loc.printerPdf)),
                      ],
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'printerType': v}),
                    ),
                    const SizedBox(height: AppTokens.spacingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.print),
                        label: Text(loc.printTestReceipt),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
