import 'package:equatable/equatable.dart';

enum SettingsCategory {
  dashboard,
  profile,
  backup,
  receipt,
  preferences,
  about,
}

enum SettingsMessageType {
  success,
  error,
}

class SettingsState extends Equatable {
  final SettingsCategory selectedCategory;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? messageKey;
  final SettingsMessageType? messageType;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> shopProfile;
  final List<Map<String, dynamic>> backups;
  final Map<String, dynamic> databaseStats;

  SettingsState({
    this.selectedCategory = SettingsCategory.dashboard,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.messageKey,
    this.messageType,
    Map<String, dynamic> preferences = const {},
    Map<String, dynamic> shopProfile = const {},
    List<Map<String, dynamic>> backups = const [],
    Map<String, dynamic> databaseStats = const {},
  })  : preferences = Map.unmodifiable(preferences),
        shopProfile = Map.unmodifiable(shopProfile),
        backups = List.unmodifiable(
          backups.map((backup) => Map<String, dynamic>.unmodifiable(backup)),
        ),
        databaseStats = Map.unmodifiable(databaseStats);

  SettingsState copyWith({
    SettingsCategory? selectedCategory,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? messageKey,
    SettingsMessageType? messageType,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
    bool clearMessageKey = false,
    bool clearMessageType = false,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? shopProfile,
    List<Map<String, dynamic>>? backups,
    Map<String, dynamic>? databaseStats,
  }) {
    return SettingsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      messageKey: clearMessageKey ? null : (messageKey ?? this.messageKey),
      messageType: clearMessageType ? null : (messageType ?? this.messageType),
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
        messageKey,
        messageType,
        preferences,
        shopProfile,
        backups,
        databaseStats,
      ];
}
