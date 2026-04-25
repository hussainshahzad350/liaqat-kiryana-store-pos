import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  static const String _msgSaveChangesSuccess = 'save_changes_success';
  static const String _msgPreferencesSaved = 'preferences_saved';
  static const String _msgBackupCreated = 'backup_created';
  static const String _msgBackupFailed = 'backup_failed';
  static const String _msgBackupDeleted = 'backup_deleted';
  static const String _msgDeleteFailed = 'delete_failed';
  static const String _msgRestoreSuccess = 'restore_success';
  static const String _msgRestoreFailed = 'restore_failed';
  static const String _msgDatabaseOptimized = 'database_optimized';
  static const String _msgDatabaseOptimizationFailed =
      'database_optimization_failed';

  SettingsCubit(this._repository) : super(SettingsState());

  Future<void> loadAll() async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      final profile = await _repository.getShopProfile() ?? {};
      final backups = await _repository.getBackupFiles();
      final prefs = await _repository.getAppPreferences();
      final stats = await _repository.getDatabaseStats();

      emit(state.copyWith(
        isLoading: false,
        shopProfile: profile,
        backups: backups,
        preferences: prefs,
        databaseStats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  void selectCategory(SettingsCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  Future<void> updateShopProfile(Map<String, dynamic> data) async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      await _repository.updateShopProfile(data);
      final profile = await _repository.getShopProfile() ?? {};
      emit(state.copyWith(
        isLoading: false,
        shopProfile: profile,
        messageKey: _msgSaveChangesSuccess,
        messageType: SettingsMessageType.success,
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      await _repository.updateAppPreferences(data);
      final prefs = await _repository.getAppPreferences();
      emit(state.copyWith(
        isLoading: false,
        preferences: prefs,
        messageKey: _msgPreferencesSaved,
        messageType: SettingsMessageType.success,
        clearSuccessMessage: true,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  Future<void> createBackup() async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      final path = await _repository.createManualBackup();
      if (path != null) {
        final backups = await _repository.getBackupFiles();
        emit(state.copyWith(
          isLoading: false,
          backups: backups,
          messageKey: _msgBackupCreated,
          messageType: SettingsMessageType.success,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          messageKey: _msgBackupFailed,
          messageType: SettingsMessageType.error,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  Future<void> deleteBackup(String path) async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      final success = await _repository.deleteBackup(path);
      if (success) {
        final backups = await _repository.getBackupFiles();
        emit(state.copyWith(
          isLoading: false,
          backups: backups,
          messageKey: _msgBackupDeleted,
          messageType: SettingsMessageType.success,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          messageKey: _msgDeleteFailed,
          messageType: SettingsMessageType.error,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  Future<void> restoreBackup(String path) async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      final success = await _repository.restoreBackup(path);
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          messageKey: _msgRestoreSuccess,
          messageType: SettingsMessageType.success,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          messageKey: _msgRestoreFailed,
          messageType: SettingsMessageType.error,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  Future<void> optimizeDatabase() async {
    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
    try {
      final success = await _repository.vacuumDatabase();
      if (success) {
        final stats = await _repository.getDatabaseStats();
        emit(state.copyWith(
          isLoading: false,
          databaseStats: stats,
          messageKey: _msgDatabaseOptimized,
          messageType: SettingsMessageType.success,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          messageKey: _msgDatabaseOptimizationFailed,
          messageType: SettingsMessageType.error,
          clearSuccessMessage: true,
          clearErrorMessage: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      ));
    }
  }

  void clearMessages() {
    emit(state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
      clearMessageKey: true,
      clearMessageType: true,
    ));
  }
}
