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

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late final TextEditingController _passwordController;
  bool _isPasswordDirty = false;
  String _lastSyncedPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _syncPasswordDraft(Map<String, dynamic> prefs) {
    final incomingPassword = (prefs['password'] as String?) ?? '';
    if (_isPasswordDirty) return;
    if (_passwordController.text == incomingPassword) {
      _lastSyncedPassword = incomingPassword;
      return;
    }

    _passwordController.text = incomingPassword;
    _lastSyncedPassword = incomingPassword;
  }

  void _savePasswordDraft(BuildContext context) {
    final value = _passwordController.text;
    _lastSyncedPassword = value;
    setState(() {
      _isPasswordDirty = false;
    });
    context.read<SettingsCubit>().updatePreferences({'password': value});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final prefs = state.preferences;
        _syncPasswordDraft(prefs);
        const allowedFormats = ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD'];
        final dateFormatPref = prefs['dateFormat'];
        final selectedDateFormat =
            dateFormatPref is String && allowedFormats.contains(dateFormatPref)
                ? dateFormatPref
                : 'DD-MM-YYYY';
        final String currentLangCode =
            Localizations.localeOf(context).languageCode;
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
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) {
                        final settingsCubit = context.read<SettingsCubit>();
                        final locale = v == 'English'
                            ? const Locale('en', '')
                            : const Locale('ur', '');

                        LiaqatStoreApp.setLocale(context, locale);
                        settingsCubit.updatePreferences(
                            {'language': locale.languageCode});
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    Text(loc.dateFormat, style: const TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      value: selectedDateFormat,
                      isExpanded: true,
                      items: allowedFormats
                          .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          context
                              .read<SettingsCubit>()
                              .updatePreferences({'dateFormat': v});
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SettingSection(
                    title: loc.themeTitle,
                    icon: Icons.palette_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.themeColor,
                            style: const TextStyle(fontSize: 14)),
                        DropdownButton<String>(
                          value: themeProvider.currentColor,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                                value: 'green',
                                child: Text(loc.themeColorGreen)),
                            DropdownMenuItem(
                                value: 'blue', child: Text(loc.themeColorBlue)),
                            DropdownMenuItem(
                                value: 'orange',
                                child: Text(loc.themeColorOrange)),
                          ],
                          onChanged: (v) {
                            if (v != null) themeProvider.setColor(v);
                          },
                        ),
                        const SizedBox(height: AppTokens.spacingMedium),
                        Text(loc.themeMode,
                            style: const TextStyle(fontSize: 14)),
                        Row(
                          children: [
                            _ThemeModeButton(
                              mode: ThemeMode.light,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: loc.themeModeLight,
                            ),
                            _ThemeModeButton(
                              mode: ThemeMode.dark,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: loc.themeModeDark,
                            ),
                            _ThemeModeButton(
                              mode: ThemeMode.system,
                              currentMode: themeProvider.themeMode,
                              onChanged: themeProvider.setMode,
                              label: loc.themeModeSystem,
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
                      onChanged: (v) => context
                          .read<SettingsCubit>()
                          .updatePreferences({'requirePassword': v}),
                    ),
                    if (prefs['requirePassword'] == true)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppTokens.spacingSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: loc.password,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) {
                                _isPasswordDirty = _passwordController.text !=
                                    _lastSyncedPassword;
                              },
                              onFieldSubmitted: (_) =>
                                  _savePasswordDraft(context),
                            ),
                            const SizedBox(height: AppTokens.spacingSmall),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _isPasswordDirty
                                    ? () => _savePasswordDraft(context)
                                    : null,
                                child: Text(loc.save),
                              ),
                            ),
                          ],
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
                      onChanged: (v) => context
                          .read<SettingsCubit>()
                          .updatePreferences({'lowStockAlert': v}),
                    ),
                    OptionSwitch(
                      title: loc.dayCloseReminder,
                      value: prefs['dayCloseReminder'] ?? true,
                      onChanged: (v) => context
                          .read<SettingsCubit>()
                          .updatePreferences({'dayCloseReminder': v}),
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
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
