import 'package:equatable/equatable.dart';

enum SettingsCategory {
  dashboard,
  profile,
  backup,
  receipt,
  preferences,
  about,
}

class SettingsState extends Equatable {
  final SettingsCategory selectedCategory;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> shopProfile;
  final List<Map<String, dynamic>> backups;
  final Map<String, dynamic> databaseStats;

  const SettingsState({
    this.selectedCategory = SettingsCategory.dashboard,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.preferences = const {},
    this.shopProfile = const {},
    this.backups = const [],
    this.databaseStats = const {},
  });

  SettingsState copyWith({
    SettingsCategory? selectedCategory,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? shopProfile,
    List<Map<String, dynamic>>? backups,
    Map<String, dynamic>? databaseStats,
  }) {
    return SettingsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      preferences: preferences ?? this.preferences,
      shopProfile: shopProfile ?? this.shopProfile,
      backups: backups ?? this.backups,
      databaseStats: databaseStats ?? this.databaseStats,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        isLoading,
        errorMessage,
        successMessage,
        preferences,
        shopProfile,
        backups,
        databaseStats,
      ];
}
