import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../widgets/info_item.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildNumber = packageInfo.buildNumber;
    final version = packageInfo.version;
    final formattedVersion =
        buildNumber.isNotEmpty ? '$version+$buildNumber' : version;

    if (!mounted) return;

    setState(() {
      _appVersion = formattedVersion;
    });
  }

  Future<void> _launchExternalUri(String uriString) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final didLaunch = await launchUrl(
        Uri.parse(uriString),
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.unableToOpenLink)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unableToOpenLink)),
      );
    }
  }

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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${loc.version}: ${_appVersion.isNotEmpty ? _appVersion : '-'}',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    const SizedBox(height: AppTokens.spacingLarge),
                    InfoItem(
                        label: loc.developedBy,
                        value: loc.developedByCompanyName),
                    const SizedBox(height: AppTokens.spacingMedium),
                    OutlinedButton.icon(
                      onPressed: null,
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
                    InfoItem(
                        label: loc.totalItems,
                        value: '${stats['products'] ?? 0}'),
                    InfoItem(
                        label: loc.totalCustomers,
                        value: '${stats['customers'] ?? 0}'),
                    InfoItem(
                        label: loc.totalSales,
                        value: '${stats['invoices'] ?? 0}'),
                    InfoItem(
                        label: loc.dbSize,
                        value:
                            '${(stats['databaseSize'] as double?)?.toStringAsFixed(2) ?? '0.00'} MB'),
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
                      onTap: () async {
                        await _launchExternalUri(
                          'mailto:hussainshahzad350@gmail.com',
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(loc.phone),
                      subtitle: const Text('0310-4523235'),
                      onTap: () async {
                        await _launchExternalUri('tel:0310-4523235');
                      },
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.outline),
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
