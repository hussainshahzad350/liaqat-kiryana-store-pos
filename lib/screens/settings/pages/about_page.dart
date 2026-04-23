import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../widgets/info_item.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final stats = state.databaseStats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              SettingSection(
                title: loc.about,
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    Icon(Icons.store, size: 80, color: colorScheme.primary),
                    const SizedBox(height: AppTokens.spacingMedium),
                    Text(
                      loc.appTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${loc.version}: 1.0.0',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    const SizedBox(height: AppTokens.spacingLarge),
                    InfoItem(label: loc.developedBy, value: 'Smart Khata Technologies'),
                    const SizedBox(height: AppTokens.spacingMedium),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.update),
                      label: Text(loc.checkForUpdates),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.systemInfo,
                icon: Icons.analytics_outlined,
                child: Column(
                  children: [
                    InfoItem(label: loc.totalItems, value: '${stats['products'] ?? 0}'),
                    InfoItem(label: loc.totalCustomers, value: '${stats['customers'] ?? 0}'),
                    InfoItem(label: loc.totalSales, value: '${stats['invoices'] ?? 0}'),
                    InfoItem(label: loc.dbSize, value: '${(stats['databaseSize'] as double?)?.toStringAsFixed(2) ?? '0.00'} MB'),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.support,
                icon: Icons.contact_support_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: Text(loc.email),
                      subtitle: const Text('hussainshahzad350@gmail.com'),
                      onTap: () {},
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(loc.phone),
                      subtitle: const Text('0310-4523235'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMedium),
                child: Center(
                  child: Text(
                    '© ${DateTime.now().year} ${loc.appTitle}. ${loc.allRightsReserved}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
