import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              SettingSection(
                title: loc.currentDatabase,
                icon: Icons.storage_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.file_present, color: colorScheme.primary),
                      title: const Text("app_database.db"),
                      subtitle: Text('${loc.size}: ${state.databaseStats['databaseSize']?.toStringAsFixed(2) ?? '0.00'} MB'),
                      trailing: OutlinedButton.icon(
                        onPressed: () => context.read<SettingsCubit>().optimizeDatabase(),
                        icon: const Icon(Icons.bolt, size: 16),
                        label: Text(loc.repairDb),
                      ),
                    ),
                    const Divider(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.read<SettingsCubit>().createBackup(),
                        icon: const Icon(Icons.add_to_photos_outlined),
                        label: Text(loc.createBackupNow),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMedium),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.recentBackups,
                icon: Icons.history_outlined,
                child: state.backups.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppTokens.spacingLarge),
                        child: Center(child: Text(loc.noBackupsFound, style: TextStyle(color: colorScheme.outline))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.backups.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final backup = state.backups[index];
                          final date = DateFormat('dd-MM-yyyy HH:mm').format(backup['modified'] as DateTime);
                          final size = ((backup['size'] as int) / (1024 * 1024)).toStringAsFixed(2);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(backup['name']),
                            subtitle: Text('$date • $size MB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.restore, color: colorScheme.primary),
                                  onPressed: () => _confirmRestore(context, backup['path']),
                                  tooltip: loc.restore,
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                  onPressed: () => _confirmDelete(context, backup['path']),
                                  tooltip: loc.delete,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              SettingSection(
                title: loc.backupOptions,
                icon: Icons.settings_backup_restore_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.usb_outlined),
                      title: Text(loc.exportToUsb),
                      onTap: () => _showNotImplemented(context),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(loc.importFromUsb),
                      onTap: () => _showNotImplemented(context),
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

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Functionality coming soon")),
    );
  }

  Future<void> _confirmRestore(BuildContext context, String path) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.restoreBackup),
        content: Text(loc.restoreConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(loc.restore, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<SettingsCubit>().restoreBackup(path);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String path) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteBackup),
        content: Text(loc.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(loc.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<SettingsCubit>().deleteBackup(path);
    }
  }
}
