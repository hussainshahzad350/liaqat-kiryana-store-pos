import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';

void main() {
  // ── SettingsCategory enum ────────────────────────────────────────────────

  group('SettingsCategory', () {
    test('has expected 6 values', () {
      expect(SettingsCategory.values.length, 6);
    });

    test('contains all expected categories', () {
      expect(SettingsCategory.values, containsAll([
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
      const state = SettingsState();
      expect(state.selectedCategory, SettingsCategory.dashboard);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.preferences, isEmpty);
      expect(state.shopProfile, isEmpty);
      expect(state.backups, isEmpty);
      expect(state.databaseStats, isEmpty);
    });
  });

  // ── SettingsState copyWith ───────────────────────────────────────────────

  group('SettingsState.copyWith', () {
    const original = SettingsState(
      selectedCategory: SettingsCategory.dashboard,
      isLoading: false,
      errorMessage: null,
      successMessage: null,
      preferences: {'theme': 'green'},
      shopProfile: {'name_english': 'Store'},
      backups: [],
      databaseStats: {'products': 5},
    );

    test('copyWith updates selectedCategory only', () {
      final updated = original.copyWith(selectedCategory: SettingsCategory.profile);
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
      final newBackups = [{'name': 'backup.db', 'size': 1024}];
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

    // IMPORTANT: copyWith always overwrites messages with what is passed (or null)
    test('copyWith resets errorMessage to null when not provided', () {
      const stateWithError = SettingsState(errorMessage: 'old error');
      final updated = stateWithError.copyWith(isLoading: false);
      // errorMessage not passed → becomes null (implementation sets it directly)
      expect(updated.errorMessage, isNull);
    });

    test('copyWith resets successMessage to null when not provided', () {
      const stateWithSuccess = SettingsState(successMessage: 'old success');
      final updated = stateWithSuccess.copyWith(isLoading: false);
      expect(updated.successMessage, isNull);
    });

    test('copyWith with no arguments resets both messages to null', () {
      const stateWithMessages = SettingsState(
        errorMessage: 'error',
        successMessage: 'success',
      );
      final updated = stateWithMessages.copyWith();
      expect(updated.errorMessage, isNull);
      expect(updated.successMessage, isNull);
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
      const stateA = SettingsState(
        selectedCategory: SettingsCategory.profile,
        isLoading: true,
      );
      const stateB = SettingsState(
        selectedCategory: SettingsCategory.profile,
        isLoading: true,
      );
      expect(stateA, equals(stateB));
    });

    test('states with different selectedCategory are not equal', () {
      const stateA = SettingsState(selectedCategory: SettingsCategory.profile);
      const stateB = SettingsState(selectedCategory: SettingsCategory.backup);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different isLoading are not equal', () {
      const stateA = SettingsState(isLoading: true);
      const stateB = SettingsState(isLoading: false);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different errorMessage are not equal', () {
      const stateA = SettingsState(errorMessage: 'error');
      const stateB = SettingsState(errorMessage: null);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different successMessage are not equal', () {
      const stateA = SettingsState(successMessage: 'ok');
      const stateB = SettingsState(successMessage: null);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different preferences are not equal', () {
      const stateA = SettingsState(preferences: {'theme': 'green'});
      const stateB = SettingsState(preferences: {'theme': 'blue'});
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different shopProfile are not equal', () {
      const stateA = SettingsState(shopProfile: {'name': 'A'});
      const stateB = SettingsState(shopProfile: {'name': 'B'});
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different backups are not equal', () {
      const stateA = SettingsState(backups: []);
      final stateB = SettingsState(backups: [{'name': 'b.db'}]);
      expect(stateA, isNot(equals(stateB)));
    });

    test('states with different databaseStats are not equal', () {
      const stateA = SettingsState(databaseStats: {'products': 1});
      const stateB = SettingsState(databaseStats: {'products': 2});
      expect(stateA, isNot(equals(stateB)));
    });

    test('props list has 8 elements', () {
      const state = SettingsState();
      expect(state.props.length, 8);
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
      const state = SettingsState(preferences: {
        'theme': 'green',
        'receiptFontSize': 'medium',
        'showLogo': true,
        'requirePassword': false,
      });
      expect(state.preferences['showLogo'], true);
      expect(state.preferences['requirePassword'], false);
    });

    test('default state is a const instance', () {
      const s1 = SettingsState();
      const s2 = SettingsState();
      expect(identical(s1, s2), isTrue);
    });
  });
}