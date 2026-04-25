import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';
import '../../core/repositories/settings_repository.dart';
import 'widgets/settings_tile.dart';
import 'pages/profile_page.dart';
import 'pages/backup_page.dart';
import 'pages/receipt_page.dart';
import 'pages/preferences_page.dart';
import 'pages/about_page.dart';
import '../../core/res/app_tokens.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsCubit(context.read<SettingsRepository>())..loadAll(),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.messageKey != null && state.messageType != null) {
          final localizedMessage = _resolveMessageKey(loc, state.messageKey!);
          final isError = state.messageType == SettingsMessageType.error;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizedMessage),
              backgroundColor:
                  isError ? colorScheme.error : colorScheme.primary,
            ),
          );
          context.read<SettingsCubit>().clearMessages();
          return;
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colorScheme.error),
          );
          context.read<SettingsCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: colorScheme.primary),
          );
          context.read<SettingsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isDashboard =
            state.selectedCategory == SettingsCategory.dashboard;

        return LoadingOverlay(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingLarge),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    if (!isDashboard)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context
                            .read<SettingsCubit>()
                            .selectCategory(SettingsCategory.dashboard),
                      ),
                    const SizedBox(width: AppTokens.spacingSmall),
                    Text(
                      isDashboard
                          ? loc.settings
                          : _getCategoryTitle(state.selectedCategory, loc),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isDashboard
                        ? _buildDashboard(context, loc)
                        : _getPage(state.selectedCategory),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveMessageKey(AppLocalizations loc, String key) {
    switch (key) {
      case 'save_changes_success':
        return loc.saveChangesSuccess;
      case 'preferences_saved':
        return loc.preferencesSaved;
      case 'backup_created':
        return loc.backupCreated;
      case 'backup_failed':
        return loc.backupFailed;
      case 'backup_deleted':
        return loc.backupDeleted;
      case 'delete_failed':
        return loc.deleteFailed;
      case 'restore_success':
        return loc.restoreSuccess;
      case 'restore_failed':
        return loc.restoreFailed;
      case 'database_optimized':
        return loc.databaseOptimized;
      case 'database_optimization_failed':
        return loc.databaseOptimizationFailed;
      default:
        return key;
    }
  }

  Widget _buildDashboard(BuildContext context, AppLocalizations loc) {
    return GridView.count(
      padding: const EdgeInsets.all(AppTokens.spacingXLarge),
      crossAxisCount: 3,
      mainAxisSpacing: AppTokens.spacingLarge,
      crossAxisSpacing: AppTokens.spacingLarge,
      children: [
        SettingsTile(
          icon: Icons.store_outlined,
          title: loc.shopProfile,
          subtitle: loc.shopProfileSubtitle,
          onTap: () => context
              .read<SettingsCubit>()
              .selectCategory(SettingsCategory.profile),
        ),
        SettingsTile(
          icon: Icons.backup_outlined,
          title: loc.backup,
          subtitle: loc.backupSubtitle,
          onTap: () => context
              .read<SettingsCubit>()
              .selectCategory(SettingsCategory.backup),
        ),
        SettingsTile(
          icon: Icons.receipt_long_outlined,
          title: loc.receiptFormat,
          subtitle: loc.receiptSubtitle,
          onTap: () => context
              .read<SettingsCubit>()
              .selectCategory(SettingsCategory.receipt),
        ),
        SettingsTile(
          icon: Icons.settings_outlined,
          title: loc.preferences,
          subtitle: loc.preferencesSubtitle,
          onTap: () => context
              .read<SettingsCubit>()
              .selectCategory(SettingsCategory.preferences),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: loc.about,
          subtitle: loc.aboutSubtitle,
          onTap: () => context
              .read<SettingsCubit>()
              .selectCategory(SettingsCategory.about),
        ),
      ],
    );
  }

  String _getCategoryTitle(SettingsCategory category, AppLocalizations loc) {
    switch (category) {
      case SettingsCategory.profile:
        return loc.shopProfile;
      case SettingsCategory.backup:
        return loc.backup;
      case SettingsCategory.receipt:
        return loc.receiptFormat;
      case SettingsCategory.preferences:
        return loc.preferences;
      case SettingsCategory.about:
        return loc.about;
      default:
        return loc.settings;
    }
  }

  Widget _getPage(SettingsCategory category) {
    switch (category) {
      case SettingsCategory.profile:
        return const ProfilePage(key: ValueKey('profile'));
      case SettingsCategory.backup:
        return const BackupPage(key: ValueKey('backup'));
      case SettingsCategory.receipt:
        return const ReceiptPage(key: ValueKey('receipt'));
      case SettingsCategory.preferences:
        return const PreferencesPage(key: ValueKey('preferences'));
      case SettingsCategory.about:
        return const AboutPage(key: ValueKey('about'));
      default:
        return const SizedBox.shrink();
    }
  }
}

// Re-implementing LoadingOverlay wrapper logic since the base widget is just the overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay(
      {super.key, required this.child, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}
