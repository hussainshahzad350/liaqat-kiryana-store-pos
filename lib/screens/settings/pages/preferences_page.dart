import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../widgets/option_switch.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final prefs = state.preferences;
        final String currentLangCode = Localizations.localeOf(context).languageCode;
        String langLabel = currentLangCode == 'ur' ? 'اردو' : 'English';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              SettingSection(
                title: loc.languageAndRegion,
                icon: Icons.language_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.appLanguage, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: langLabel,
                      isExpanded: true,
                      items: const ['اردو', 'English']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) {
                        if (v == 'English') {
                          LiaqatStoreApp.setLocale(context, const Locale('en', ''));
                        } else {
                          LiaqatStoreApp.setLocale(context, const Locale('ur', ''));
                        }
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    Text(loc.dateFormat, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: prefs['dateFormat'] ?? 'DD-MM-YYYY',
                      isExpanded: true,
                      items: const ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'dateFormat': v}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SettingSection(
                    title: "Theme", // TODO: Add to localization
                    icon: Icons.palette_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Theme Color", style: TextStyle(fontSize: 14)),
                        DropdownButton<String>(
                          value: themeProvider.currentColor,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'green', child: Text('Green')),
                            DropdownMenuItem(value: 'blue', child: Text('Blue')),
                            DropdownMenuItem(value: 'orange', child: Text('Orange')),
                          ],
                          onChanged: (v) {
                            if (v != null) themeProvider.setColor(v);
                          },
                        ),
                        const SizedBox(height: AppTokens.spacingMedium),
                        const Text("Theme Mode", style: TextStyle(fontSize: 14)),
                        Row(
                          children: [
                            _ThemeModeButton(
                              mode: ThemeMode.light,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: 'Light',
                            ),
                            _ThemeModeButton(
                              mode: ThemeMode.dark,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: 'Dark',
                            ),
                            _ThemeModeButton(
                              mode: ThemeMode.system,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: 'System',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.security,
                icon: Icons.security_outlined,
                child: Column(
                  children: [
                    OptionSwitch(
                      title: loc.requirePasswordStartup,
                      value: prefs['requirePassword'] ?? false,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'requirePassword': v}),
                    ),
                    if (prefs['requirePassword'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTokens.spacingSmall),
                        child: TextFormField(
                          initialValue: prefs['password'],
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: loc.password,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'password': v}),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.notifications,
                icon: Icons.notifications_none_outlined,
                child: Column(
                  children: [
                    OptionSwitch(
                      title: loc.lowStockAlert,
                      value: prefs['lowStockAlert'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'lowStockAlert': v}),
                    ),
                    OptionSwitch(
                      title: loc.dayCloseReminder,
                      value: prefs['dayCloseReminder'] ?? true,
                      onChanged: (v) => context.read<SettingsCubit>().updatePreferences({'dayCloseReminder': v}),
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

class _ThemeModeButton extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode currentMode;
  final Function(ThemeMode) onChanged;
  final String label;

  const _ThemeModeButton({
    required this.mode,
    required this.currentMode,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Center(child: Text(label)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onChanged(mode);
          },
          selectedColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
