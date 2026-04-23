import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true));
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
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void selectCategory(SettingsCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  Future<void> updateShopProfile(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.updateShopProfile(data);
      final profile = await _repository.getShopProfile() ?? {};
      emit(state.copyWith(
        isLoading: false,
        shopProfile: profile,
        successMessage: 'Profile updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.updateAppPreferences(data);
      final prefs = await _repository.getAppPreferences();
      emit(state.copyWith(
        isLoading: false,
        preferences: prefs,
        successMessage: 'Preferences updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> createBackup() async {
    emit(state.copyWith(isLoading: true));
    try {
      final path = await _repository.createManualBackup();
      if (path != null) {
        final backups = await _repository.getBackupFiles();
        emit(state.copyWith(
          isLoading: false,
          backups: backups,
          successMessage: 'Backup created successfully',
        ));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Backup failed'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteBackup(String path) async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await _repository.deleteBackup(path);
      if (success) {
        final backups = await _repository.getBackupFiles();
        emit(state.copyWith(
          isLoading: false,
          backups: backups,
          successMessage: 'Backup deleted',
        ));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Delete failed'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> restoreBackup(String path) async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await _repository.restoreBackup(path);
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          successMessage: 'Restore successful. Restart app recommended.',
        ));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Restore failed'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> optimizeDatabase() async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await _repository.vacuumDatabase();
      if (success) {
        final stats = await _repository.getDatabaseStats();
        emit(state.copyWith(
          isLoading: false,
          databaseStats: stats,
          successMessage: 'Database optimized',
        ));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Optimization failed'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
