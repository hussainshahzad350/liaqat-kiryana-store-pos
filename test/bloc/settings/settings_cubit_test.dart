import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/bloc/settings/settings_cubit.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsRepository repository;

  setUp(() {
    repository = _MockSettingsRepository();
  });

  SettingsCubit buildCubit() => SettingsCubit(repository);

  // ── loadAll ──────────────────────────────────────────────────────────────

  group('loadAll', () {
    final profile = {'name_english': 'Test Store', 'name_urdu': 'ٹیسٹ'};
    final backups = [
      {
        'name': 'backup.db',
        'path': '/path/backup.db',
        'size': 1024,
        'modified': DateTime(2024)
      }
    ];
    final prefs = {'language': 'en', 'theme': 'green'};
    final stats = {'products': 10, 'databaseSize': 1.5};

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then populated state on success',
      build: () {
        when(() => repository.getShopProfile())
            .thenAnswer((_) async => profile);
        when(() => repository.getBackupFiles())
            .thenAnswer((_) async => backups);
        when(() => repository.getAppPreferences())
            .thenAnswer((_) async => prefs);
        when(() => repository.getDatabaseStats())
            .thenAnswer((_) async => stats);
        return buildCubit();
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          shopProfile: profile,
          backups: backups,
          preferences: prefs,
          databaseStats: stats,
        ),
      ],
      verify: (_) {
        verify(() => repository.getShopProfile()).called(1);
        verify(() => repository.getBackupFiles()).called(1);
        verify(() => repository.getAppPreferences()).called(1);
        verify(() => repository.getDatabaseStats()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'treats null shop profile as empty map',
      build: () {
        when(() => repository.getShopProfile()).thenAnswer((_) async => null);
        when(() => repository.getBackupFiles()).thenAnswer((_) async => []);
        when(() => repository.getAppPreferences()).thenAnswer((_) async => {});
        when(() => repository.getDatabaseStats()).thenAnswer((_) async => {});
        return buildCubit();
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          shopProfile: const {},
          backups: const [],
          preferences: const {},
          databaseStats: const {},
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then error state when repository throws',
      build: () {
        when(() => repository.getShopProfile())
            .thenThrow(Exception('network error'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('network error')),
      ],
    );
  });

  // ── selectCategory ───────────────────────────────────────────────────────

  group('selectCategory', () {
    for (final category in SettingsCategory.values) {
      blocTest<SettingsCubit, SettingsState>(
        'emits state with selectedCategory=$category',
        build: buildCubit,
        act: (cubit) => cubit.selectCategory(category),
        expect: () => [
          SettingsState(selectedCategory: category),
        ],
      );
    }
  });

  // ── updateShopProfile ────────────────────────────────────────────────────

  group('updateShopProfile', () {
    final profileData = {'name_english': 'Updated Store'};
    final updatedProfile = {
      'name_english': 'Updated Store',
      'address': '123 Main'
    };

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state with refreshed profile',
      build: () {
        when(() => repository.updateShopProfile(any()))
            .thenAnswer((_) async => 1);
        when(() => repository.getShopProfile())
            .thenAnswer((_) async => updatedProfile);
        return buildCubit();
      },
      act: (cubit) => cubit.updateShopProfile(profileData),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          shopProfile: updatedProfile,
          successMessage: 'Profile updated successfully',
        ),
      ],
      verify: (_) {
        verify(() => repository.updateShopProfile(profileData)).called(1);
        verify(() => repository.getShopProfile()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.updateShopProfile(any()))
            .thenThrow(Exception('db error'));
        return buildCubit();
      },
      act: (cubit) => cubit.updateShopProfile(profileData),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage', contains('db error'))
            .having((s) => s.successMessage, 'successMessage', isNull),
      ],
    );
  });

  // ── updatePreferences ────────────────────────────────────────────────────

  group('updatePreferences', () {
    final prefData = {'theme': 'blue'};
    final updatedPrefs = {'theme': 'blue', 'language': 'en'};

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state with refreshed preferences',
      build: () {
        when(() => repository.updateAppPreferences(any()))
            .thenAnswer((_) async {});
        when(() => repository.getAppPreferences())
            .thenAnswer((_) async => updatedPrefs);
        return buildCubit();
      },
      act: (cubit) => cubit.updatePreferences(prefData),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          preferences: updatedPrefs,
          successMessage: 'Preferences updated successfully',
        ),
      ],
      verify: (_) {
        verify(() => repository.updateAppPreferences(prefData)).called(1);
        verify(() => repository.getAppPreferences()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.updateAppPreferences(any()))
            .thenThrow(Exception('prefs error'));
        return buildCubit();
      },
      act: (cubit) => cubit.updatePreferences(prefData),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
                (s) => s.errorMessage, 'errorMessage', contains('prefs error')),
      ],
    );
  });

  // ── createBackup ─────────────────────────────────────────────────────────

  group('createBackup', () {
    final backupList = [
      {
        'name': 'backup_new.db',
        'path': '/path/backup_new.db',
        'size': 2048,
        'modified': DateTime(2024)
      }
    ];

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state when backup path is non-null',
      build: () {
        when(() => repository.createManualBackup())
            .thenAnswer((_) async => '/backups/backup_new.db');
        when(() => repository.getBackupFiles())
            .thenAnswer((_) async => backupList);
        return buildCubit();
      },
      act: (cubit) => cubit.createBackup(),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          backups: backupList,
          successMessage: 'Backup created successfully',
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when createManualBackup returns null',
      build: () {
        when(() => repository.createManualBackup())
            .thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.createBackup(),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
                (s) => s.errorMessage, 'errorMessage', equals('Backup failed')),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.createManualBackup())
            .thenThrow(Exception('disk full'));
        return buildCubit();
      },
      act: (cubit) => cubit.createBackup(),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
                (s) => s.errorMessage, 'errorMessage', contains('disk full')),
      ],
    );
  });

  // ── deleteBackup ─────────────────────────────────────────────────────────

  group('deleteBackup', () {
    const backupPath = '/backups/old_backup.db';

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state when delete succeeds',
      build: () {
        when(() => repository.deleteBackup(any()))
            .thenAnswer((_) async => true);
        when(() => repository.getBackupFiles()).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.deleteBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          backups: const [],
          successMessage: 'Backup deleted',
        ),
      ],
      verify: (_) {
        verify(() => repository.deleteBackup(backupPath)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when delete returns false',
      build: () {
        when(() => repository.deleteBackup(any()))
            .thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) => cubit.deleteBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
                (s) => s.errorMessage, 'errorMessage', equals('Delete failed')),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.deleteBackup(any()))
            .thenThrow(Exception('permission denied'));
        return buildCubit();
      },
      act: (cubit) => cubit.deleteBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('permission denied')),
      ],
    );
  });

  // ── restoreBackup ────────────────────────────────────────────────────────

  group('restoreBackup', () {
    const backupPath = '/backups/restore_me.db';

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state when restore succeeds',
      build: () {
        when(() => repository.restoreBackup(any()))
            .thenAnswer((_) async => true);
        return buildCubit();
      },
      act: (cubit) => cubit.restoreBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.successMessage, 'successMessage',
                contains('Restore successful')),
      ],
      verify: (_) {
        verify(() => repository.restoreBackup(backupPath)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when restore returns false',
      build: () {
        when(() => repository.restoreBackup(any()))
            .thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) => cubit.restoreBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                equals('Restore failed')),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.restoreBackup(any()))
            .thenThrow(Exception('file not found'));
        return buildCubit();
      },
      act: (cubit) => cubit.restoreBackup(backupPath),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('file not found')),
      ],
    );
  });

  // ── optimizeDatabase ─────────────────────────────────────────────────────

  group('optimizeDatabase', () {
    final updatedStats = {'products': 5, 'databaseSize': 0.8};

    blocTest<SettingsCubit, SettingsState>(
      'emits loading then success state with refreshed stats when vacuum succeeds',
      build: () {
        when(() => repository.vacuumDatabase()).thenAnswer((_) async => true);
        when(() => repository.getDatabaseStats())
            .thenAnswer((_) async => updatedStats);
        return buildCubit();
      },
      act: (cubit) => cubit.optimizeDatabase(),
      expect: () => [
        SettingsState(isLoading: true),
        SettingsState(
          isLoading: false,
          databaseStats: updatedStats,
          successMessage: 'Database optimized',
        ),
      ],
      verify: (_) {
        verify(() => repository.vacuumDatabase()).called(1);
        verify(() => repository.getDatabaseStats()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when vacuum returns false',
      build: () {
        when(() => repository.vacuumDatabase()).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) => cubit.optimizeDatabase(),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                equals('Optimization failed')),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error state when repository throws',
      build: () {
        when(() => repository.vacuumDatabase())
            .thenThrow(Exception('vacuum error'));
        return buildCubit();
      },
      act: (cubit) => cubit.optimizeDatabase(),
      expect: () => [
        SettingsState(isLoading: true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('vacuum error')),
      ],
    );
  });

  // ── clearMessages ────────────────────────────────────────────────────────

  group('clearMessages', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits state with both messages set to null',
      build: buildCubit,
      seed: () => SettingsState(
        errorMessage: 'some error',
        successMessage: 'some success',
      ),
      act: (cubit) => cubit.clearMessages(),
      expect: () => [
        SettingsState(errorMessage: null, successMessage: null),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'is idempotent when messages are already null',
      build: buildCubit,
      seed: () => SettingsState(),
      act: (cubit) => cubit.clearMessages(),
      expect: () => [
        SettingsState(errorMessage: null, successMessage: null),
      ],
    );
  });
}
