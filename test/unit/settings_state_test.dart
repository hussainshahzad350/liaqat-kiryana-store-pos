import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';

void main() {
  // ── SettingsCategory enum ────────────────────────────────────────────────

  group('SettingsCategory', () {
    test('has expected 6 values', () {
      expect(SettingsCategory.values.length, 6);
    });

    test('contains all expected categories', () {
      expect(
          SettingsCategory.values,
          containsAll([
            SettingsCategory.dashboard,
            SettingsCategory.profile,
            SettingsCategory.backup,
            SettingsCategory.receipt,
            SettingsCategory.preferences,
            SettingsCategory.about,
          ]));
    });
  });

  // ── SettingsState defaults ───────────────────────────────────────────────

  group('SettingsState defaults', () {
    test('creates state with correct default values', () {
      final state = SettingsState();
      expect(state.selectedCategory, SettingsCategory.dashboard);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.messageKey, isNull);
      expect(state.messageType, isNull);
      expect(state.preferences, isEmpty);
      expect(state.shopProfile, isEmpty);
      expect(state.backups, isEmpty);
      expect(state.databaseStats, isEmpty);
    });
  });

  // ── SettingsState copyWith ───────────────────────────────────────────────

  group('SettingsState.copyWith', () {
    final original = SettingsState(
      selectedCategory: SettingsCategory.dashboard,
      isLoading: false,
      errorMessage: null,
      successMessage: null,
      preferences: const {'theme': 'green'},
      shopProfile: const {'name_english': 'Store'},
      backups: const [],
      databaseStats: const {'products': 5},
    );

    test('copyWith updates selectedCategory only', () {
      final updated =
          original.copyWith(selectedCategory: SettingsCategory.profile);
      expect(updated.selectedCategory, SettingsCategory.profile);
      expect(updated.isLoading, false);
      expect(updated.preferences, {'theme': 'green'});
    });

    test('copyWith updates isLoading only', () {
      final updated = original.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.selectedCategory, SettingsCategory.dashboard);
      expect(updated.shopProfile, {'name_english': 'Store'});
    });

    test('copyWith updates preferences only', () {
      final newPrefs = {'theme': 'blue', 'language': 'ur'};
      final updated = original.copyWith(preferences: newPrefs);
      expect(updated.preferences, newPrefs);
      expect(updated.shopProfile, {'name_english': 'Store'});
    });

    test('copyWith updates shopProfile only', () {
      final newProfile = {'name_english': 'New Store', 'address': 'Main St'};
      final updated = original.copyWith(shopProfile: newProfile);
      expect(updated.shopProfile, newProfile);
      expect(updated.preferences, {'theme': 'green'});
    });

    test('copyWith updates backups only', () {
      final newBackups = [
        {'name': 'backup.db', 'size': 1024}
      ];
      final updated = original.copyWith(backups: newBackups);
      expect(updated.backups, newBackups);
      expect(updated.databaseStats, {'products': 5});
    });

    test('copyWith updates databaseStats only', () {
      final newStats = {'products': 99, 'databaseSize': 2.5};
      final updated = original.copyWith(databaseStats: newStats);
      expect(updated.databaseStats, newStats);
      expect(updated.preferences, {'theme': 'green'});
    });

    test('copyWith sets errorMessage to provided value', () {
      final updated = original.copyWith(errorMessage: 'something went wrong');
      expect(updated.errorMessage, 'something went wrong');
    });

    test('copyWith sets successMessage to provided value', () {
      final updated = original.copyWith(successMessage: 'done!');
      expect(updated.successMessage, 'done!');
    });

    test('copyWith preserves errorMessage when not provided', () {
      final stateWithError = SettingsState(errorMessage: 'old error');
      final updated = stateWithError.copyWith(isLoading: false);
      expect(updated.errorMessage, 'old error');
    });

    test('copyWith preserves successMessage when not provided', () {
      final stateWithSuccess = SettingsState(successMessage: 'old success');
      final updated = stateWithSuccess.copyWith(isLoading: false);
      expect(updated.successMessage, 'old success');
    });

    test('copyWith with no arguments preserves both messages', () {
      final stateWithMessages = SettingsState(
        errorMessage: 'error',
        successMessage: 'success',
      );
      final updated = stateWithMessages.copyWith();
      expect(updated.errorMessage, 'error');
      expect(updated.successMessage, 'success');
    });

    test('copyWith clears all message fields when clear flags are set', () {
      final stateWithMessages = SettingsState(
        errorMessage: 'error',
        successMessage: 'success',
        messageKey: 'save_changes_success',
        messageType: SettingsMessageType.success,
      );

      final updated = stateWithMessages.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearMessageKey: true,
        clearMessageType: true,
      );

      expect(updated.errorMessage, isNull);
      expect(updated.successMessage, isNull);
      expect(updated.messageKey, isNull);
      expect(updated.messageType, isNull);
    });

    test('copyWith preserves all non-specified fields', () {
      final updated = original.copyWith(isLoading: true);
      expect(updated.selectedCategory, original.selectedCategory);
      expect(updated.preferences, original.preferences);
      expect(updated.shopProfile, original.shopProfile);
      expect(updated.backups, original.backups);
      expect(updated.databaseStats, original.databaseStats);
    });
  });

  // ── Equatable props ──────────────────────────────────────────────────────

  group('SettingsState equality (Equatable)', () {
    test('two states with same values are equal', () {
      final stateA = SettingsState(
        selectedCategory: SettingsCategory.profile,
        isLoading: true,
      );
      final stateB = SettingsState(
        selectedCategory: SettingsCategory.profile,
        isLoading: true,
      );
      expect(stateA, equals(stateB));
    });

    test('states with different selectedCategory are not equal', () {
      final stateA = SettingsState(selectedCategory: SettingsCategory.profile);
      final stateB = SettingsState(selectedCategory: SettingsCategory.backup);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different isLoading are not equal', () {
      final stateA = SettingsState(isLoading: true);
      final stateB = SettingsState(isLoading: false);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different errorMessage are not equal', () {
      final stateA = SettingsState(errorMessage: 'error');
      final stateB = SettingsState(errorMessage: null);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different successMessage are not equal', () {
      final stateA = SettingsState(successMessage: 'ok');
      final stateB = SettingsState(successMessage: null);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different preferences are not equal', () {
      final stateA = SettingsState(preferences: const {'theme': 'green'});
      final stateB = SettingsState(preferences: const {'theme': 'blue'});
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different shopProfile are not equal', () {
      final stateA = SettingsState(shopProfile: const {'name': 'A'});
      final stateB = SettingsState(shopProfile: const {'name': 'B'});
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different backups are not equal', () {
      final stateA = SettingsState(backups: const []);
      final stateB = SettingsState(backups: const [
        {'name': 'b.db'}
      ]);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different databaseStats are not equal', () {
      final stateA = SettingsState(databaseStats: const {'products': 1});
      final stateB = SettingsState(databaseStats: const {'products': 2});
      expect(stateA, isNot(equals(stateB)));
    });

    test('props list has 10 elements', () {
      final state = SettingsState();
      expect(state.props.length, 10);
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────────

  group('SettingsState edge cases', () {
    test('can hold non-empty backups list', () {
      final backups = [
        {'name': 'b1.db', 'size': 1024, 'modified': DateTime(2024, 1, 1)},
        {'name': 'b2.db', 'size': 2048, 'modified': DateTime(2024, 6, 1)},
      ];
      final state = SettingsState(backups: backups);
      expect(state.backups.length, 2);
      expect(state.backups[0]['name'], 'b1.db');
    });

    test('can hold deeply nested preferences map', () {
      final state = SettingsState(preferences: const {
        'theme': 'green',
        'receiptFontSize': 'medium',
        'showLogo': true,
        'requirePassword': false,
      });
      expect(state.preferences['showLogo'], true);
      expect(state.preferences['requirePassword'], false);
    });

    test('default states with same values are equal', () {
      final s1 = SettingsState();
      final s2 = SettingsState();
      expect(s1, equals(s2));
    });
  });
}
