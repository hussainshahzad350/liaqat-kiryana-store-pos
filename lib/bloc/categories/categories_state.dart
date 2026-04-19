import 'package:equatable/equatable.dart';
import '../../models/category_models.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesReady extends CategoriesState {
  final List<Department> departments;
  final List<Category> categories; // Categories for the selected department
  final Map<int, List<SubCategory>> subCategoryCache;

  final Department? selectedDepartment;
  final Category? selectedCategory;
  final SubCategory? selectedSubCategory;

  final String searchQuery;
  final Map<String, Set<int>>? searchResults;

  final int detailsItemCount;
  final int detailsSubCount;

  // Selection Level to determine what to show in Details Pane
  // 0: None, 1: Department, 2: Category, 3: SubCategory
  final int selectionLevel;

  CategoriesReady({
    required List<Department> departments,
    required List<Category> categories,
    required Map<int, List<SubCategory>> subCategoryCache,
    this.selectedDepartment,
    this.selectedCategory,
    this.selectedSubCategory,
    this.searchQuery = '',
    Map<String, Set<int>>? searchResults,
    this.detailsItemCount = 0,
    this.detailsSubCount = 0,
    this.selectionLevel = 0,
  })  : departments = List.unmodifiable(departments),
        categories = List.unmodifiable(categories),
        subCategoryCache = Map.unmodifiable(
          subCategoryCache.map(
            (key, value) => MapEntry(key, List.unmodifiable(value)),
          ),
        ),
        searchResults = searchResults == null
            ? null
            : Map.unmodifiable(
                searchResults.map(
                  (key, value) => MapEntry(key, Set.unmodifiable(value)),
                ),
              );

  CategoriesReady copyWith({
    List<Department>? departments,
    List<Category>? categories,
    Map<int, List<SubCategory>>? subCategoryCache,
    Department? selectedDepartment,
    bool clearSelectedDepartment = false,
    Category? selectedCategory,
    bool clearSelectedCategory = false,
    SubCategory? selectedSubCategory,
    bool clearSelectedSubCategory = false,
    String? searchQuery,
    Map<String, Set<int>>? searchResults,
    bool clearSearchResults = false,
    int? detailsItemCount,
    int? detailsSubCount,
    int? selectionLevel,
  }) {
    return CategoriesReady(
      departments: departments ?? this.departments,
      categories: categories ?? this.categories,
      subCategoryCache: subCategoryCache ?? this.subCategoryCache,
      selectedDepartment: clearSelectedDepartment
          ? null
          : (selectedDepartment ?? this.selectedDepartment),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedSubCategory: clearSelectedSubCategory
          ? null
          : (selectedSubCategory ?? this.selectedSubCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults:
          clearSearchResults ? null : (searchResults ?? this.searchResults),
      detailsItemCount: detailsItemCount ?? this.detailsItemCount,
      detailsSubCount: detailsSubCount ?? this.detailsSubCount,
      selectionLevel: selectionLevel ?? this.selectionLevel,
    );
  }

  @override
  List<Object?> get props => [
        departments,
        categories,
        subCategoryCache,
        selectedDepartment,
        selectedCategory,
        selectedSubCategory,
        searchQuery,
        searchResults,
        detailsItemCount,
        detailsSubCount,
        selectionLevel,
      ];
}

class CategoriesFailure extends CategoriesState {
  final String errorMessage;
  const CategoriesFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
