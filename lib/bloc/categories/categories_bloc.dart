import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/categories_repository.dart';
import '../../models/category_models.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesBloc(this._repository) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SearchCategories>(
      _onSearchCategories,
      transformer: restartable(),
    );
    on<SelectDepartment>(_onSelectDepartment);
    on<SelectCategory>(_onSelectCategory);
    on<SelectSubCategory>(_onSelectSubCategory);
    on<PreloadCategorySubCategories>(_onPreloadCategorySubCategories);

    // CRUD
    on<AddDepartment>(_onAddDepartment);
    on<UpdateDepartment>(_onUpdateDepartment);
    on<DeleteDepartment>(_onDeleteDepartment);

    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);

    on<AddSubCategory>(_onAddSubCategory);
    on<UpdateSubCategory>(_onUpdateSubCategory);
    on<DeleteSubCategory>(_onDeleteSubCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoriesState> emit) async {
    final previousReady =
        state is CategoriesReady ? state as CategoriesReady : null;
    emit(CategoriesLoading());
    try {
      final depts = await _repository.getAllDepartments();

      CategoriesReady nextState = CategoriesReady(
        departments: depts,
        categories: const [],
        subCategoryCache: const {},
      );

      if (depts.isNotEmpty) {
        final firstDept = depts.first;
        final cats = await _repository.getCategoriesByDepartment(firstDept.id!);
        final subs = await _repository.getCategoryCount(firstDept.id!);
        final items =
            await _repository.getProductCountByDepartment(firstDept.id!);

        nextState = nextState.copyWith(
          selectedDepartment: firstDept,
          categories: cats,
          selectionLevel: 1,
          detailsSubCount: subs,
          detailsItemCount: items,
        );
      }

      emit(nextState);
    } catch (e) {
      _emitFailure(emit, e.toString(), previousReady: previousReady);
    }
  }

  Future<void> _onSearchCategories(
      SearchCategories event, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(searchQuery: '', clearSearchResults: true));
      return;
    }

    try {
      final results = await _repository.searchHierarchy(event.query);
      if (emit.isDone) return;
      emit(currentState.copyWith(
          searchQuery: event.query, searchResults: results));
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onSelectDepartment(
      SelectDepartment event, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;

    if (event.department == null) {
      emit(currentState.copyWith(
        clearSelectedDepartment: true,
        clearSelectedCategory: true,
        clearSelectedSubCategory: true,
        categories: [],
        selectionLevel: 0,
        detailsSubCount: 0,
        detailsItemCount: 0,
      ));
      return;
    }

    try {
      final cats =
          await _repository.getCategoriesByDepartment(event.department!.id!);
      final subs = await _repository.getCategoryCount(event.department!.id!);
      final items =
          await _repository.getProductCountByDepartment(event.department!.id!);

      emit(currentState.copyWith(
        selectedDepartment: event.department,
        clearSelectedCategory: true,
        clearSelectedSubCategory: true,
        categories: cats,
        selectionLevel: 1,
        detailsSubCount: subs,
        detailsItemCount: items,
      ));
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onSelectCategory(
      SelectCategory event, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;

    if (event.category == null) {
      emit(currentState.copyWith(
          clearSelectedCategory: true,
          clearSelectedSubCategory: true,
          selectionLevel: 1));
      return;
    }

    try {
      final subs = await _repository.getSubCategoryCount(event.category!.id!);
      final items =
          await _repository.getProductCountByCategory(event.category!.id!);

      // Lazy load subcategories if not in cache
      Map<int, List<SubCategory>> subCache =
          Map.from(currentState.subCategoryCache);
      if (!subCache.containsKey(event.category!.id)) {
        final subList =
            await _repository.getSubCategoriesByCategory(event.category!.id!);
        subCache[event.category!.id!] = subList;
      }

      emit(currentState.copyWith(
        selectedCategory: event.category,
        clearSelectedSubCategory: true,
        subCategoryCache: subCache,
        selectionLevel: 2,
        detailsSubCount: subs,
        detailsItemCount: items,
      ));
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onSelectSubCategory(
      SelectSubCategory event, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;

    emit(currentState.copyWith(
      selectedSubCategory: event.subCategory,
      selectionLevel: event.subCategory == null ? 2 : 3,
      // Selection Level 3 doesn't typically show direct items/subs in this schema
      detailsSubCount: 0,
      detailsItemCount: 0,
    ));
  }

  Future<void> _onPreloadCategorySubCategories(
      PreloadCategorySubCategories event, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;
    if (currentState.subCategoryCache.containsKey(event.categoryId)) return;

    await _refreshSubCategories(event.categoryId, emit);
  }

  // CRUD Handlers

  Future<void> _onAddDepartment(
      AddDepartment event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.addDepartment(event.department);
      add(LoadCategories());
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onUpdateDepartment(
      UpdateDepartment event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.updateDepartment(event.department);
      add(LoadCategories());
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onDeleteDepartment(
      DeleteDepartment event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.deleteDepartment(event.id);
      add(LoadCategories());
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onAddCategory(
      AddCategory event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.addCategory(event.category);
      if (state is CategoriesReady) {
        final selectedDeptId =
            (state as CategoriesReady).selectedDepartment?.id;
        if (selectedDeptId != null) {
          final cats =
              await _repository.getCategoriesByDepartment(selectedDeptId);
          final subs = await _repository.getCategoryCount(selectedDeptId);
          emit((state as CategoriesReady)
              .copyWith(categories: cats, detailsSubCount: subs));
        }
      }
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.updateCategory(event.category);
      if (state is CategoriesReady) {
        final selectedDeptId =
            (state as CategoriesReady).selectedDepartment?.id;
        if (selectedDeptId != null) {
          final cats =
              await _repository.getCategoriesByDepartment(selectedDeptId);
          emit((state as CategoriesReady).copyWith(categories: cats));
        }
      }
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.deleteCategory(event.id);
      if (state is CategoriesReady) {
        final selectedDeptId =
            (state as CategoriesReady).selectedDepartment?.id;
        if (selectedDeptId != null) {
          final cats =
              await _repository.getCategoriesByDepartment(selectedDeptId);
          final subs = await _repository.getCategoryCount(selectedDeptId);
          emit((state as CategoriesReady).copyWith(
              categories: cats,
              detailsSubCount: subs,
              clearSelectedCategory: true,
              selectionLevel: 1));
        }
      }
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onAddSubCategory(
      AddSubCategory event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.addSubCategory(event.subCategory);
      await _refreshSubCategories(event.subCategory.categoryId, emit);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onUpdateSubCategory(
      UpdateSubCategory event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.updateSubCategory(event.subCategory);
      await _refreshSubCategories(event.subCategory.categoryId, emit);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onDeleteSubCategory(
      DeleteSubCategory event, Emitter<CategoriesState> emit) async {
    try {
      final currentState = state;
      if (currentState is! CategoriesReady) return;
      final selectedSubCategory = currentState.selectedSubCategory;
      final catId =
          selectedSubCategory?.categoryId ?? currentState.selectedCategory?.id;
      if (catId == null) return;

      await _repository.deleteSubCategory(event.id);

      final deletedSelectedSubCategory = selectedSubCategory?.id == event.id;
      if (deletedSelectedSubCategory) {
        final fallbackSelectionLevel = currentState.selectedCategory != null
            ? 2
            : (currentState.selectedDepartment != null ? 1 : 0);

        emit(currentState.copyWith(
          clearSelectedSubCategory: true,
          selectionLevel: fallbackSelectionLevel,
        ));
      }

      await _refreshSubCategories(catId, emit);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _refreshSubCategories(
      int catId, Emitter<CategoriesState> emit) async {
    final currentState = state;
    if (currentState is! CategoriesReady) return;

    try {
      final subList = await _repository.getSubCategoriesByCategory(catId);
      final subsCount = await _repository.getSubCategoryCount(catId);
      final isSelectedCategory = currentState.selectedCategory?.id == catId;
      final itemsCount = isSelectedCategory
          ? await _repository.getProductCountByCategory(catId)
          : currentState.detailsItemCount;

      Map<int, List<SubCategory>> subCache =
          Map.from(currentState.subCategoryCache);
      subCache[catId] = subList;

      emit(currentState.copyWith(
        subCategoryCache: subCache,
        detailsSubCount:
            isSelectedCategory ? subsCount : currentState.detailsSubCount,
        detailsItemCount: itemsCount,
      ));
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  void _emitFailure(
    Emitter<CategoriesState> emit,
    String message, {
    CategoriesReady? previousReady,
  }) {
    final currentState = state;
    emit(CategoriesFailure(message));
    if (previousReady != null) {
      emit(previousReady);
    } else if (currentState is CategoriesReady) {
      emit(currentState);
    } else {
      emit(CategoriesInitial());
    }
  }
}
