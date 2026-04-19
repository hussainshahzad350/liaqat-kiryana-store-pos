import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event.dart';
import '../../bloc/categories/categories_state.dart';
import '../../core/repositories/categories_repository.dart';
import '../../core/res/app_tokens.dart';
import '../../core/utils/error_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_models.dart';
import 'dialogs/category_dialog.dart';
import 'dialogs/department_dialog.dart';
import 'dialogs/sub_category_dialog.dart';
import 'widgets/category_tree_widget.dart';
import 'widgets/department_list_widget.dart';
import 'widgets/details_panel_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchControllerChanged);
  }

  void _onSearchControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchControllerChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearch(BuildContext context, String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      context.read<CategoriesBloc>().add(SearchCategories(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => CategoriesBloc(context.read<CategoriesRepository>())
        ..add(LoadCategories()),
      child: BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoriesFailure) {
            ErrorHandler.handleError(
              context,
              state.errorMessage,
              tag: 'Categories',
            );
          }
        },
        builder: (context, state) {
          if (state is CategoriesLoading || state is CategoriesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! CategoriesReady) {
            return Center(child: Text(loc.error));
          }

          return Padding(
            padding: const EdgeInsets.all(AppTokens.spacingLarge),
            child: Column(
              children: [
                // Top Search Bar
                _buildSearchBar(context, state, loc, colorScheme),
                const SizedBox(height: AppTokens.spacingMedium),

                // Main Content Area
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pane 1: Departments
                      SizedBox(
                        width: AppTokens.sidebarWidthSmall,
                        child: Card(
                          elevation: AppTokens.cardElevation,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.cardBorderRadius)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppTokens.cardBorderRadius),
                            child: DepartmentListWidget(
                              departments: state.departments,
                              selectedDepartment: state.selectedDepartment,
                              searchResults: state.searchResults,
                              searchQuery: state.searchQuery,
                              onSelect: (dept) => context
                                  .read<CategoriesBloc>()
                                  .add(SelectDepartment(dept)),
                              onAdd: () => _showAddDepartment(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingMedium),

                      // Pane 2: Taxonomy (Categories & Subcategories)
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: AppTokens.cardElevation,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.cardBorderRadius)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppTokens.cardBorderRadius),
                            child: CategoryTreeWidget(
                              categories: state.categories,
                              selectedDepartment: state.selectedDepartment,
                              selectedCategory: state.selectedCategory,
                              selectedSubCategory: state.selectedSubCategory,
                              subCategoryCache: state.subCategoryCache,
                              searchResults: state.searchResults,
                              searchQuery: state.searchQuery,
                              onCategorySelect: (cat) => context
                                  .read<CategoriesBloc>()
                                  .add(SelectCategory(cat)),
                              onPreloadSubCategories: (categoryId) => context
                                  .read<CategoriesBloc>()
                                  .add(
                                      PreloadCategorySubCategories(categoryId)),
                              onSubCategorySelect: (sub) => context
                                  .read<CategoriesBloc>()
                                  .add(SelectSubCategory(sub)),
                              onAddCategory: () =>
                                  _showAddCategory(context, state),
                              onAddSubCategory: (cat) =>
                                  _showAddSubCategory(context, state, cat),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingMedium),

                      // Pane 3: Details & Management
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: AppTokens.cardElevation,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.cardBorderRadius)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppTokens.cardBorderRadius),
                            child: DetailsPanelWidget(
                              selectionLevel: state.selectionLevel,
                              selectedDepartment: state.selectedDepartment,
                              selectedCategory: state.selectedCategory,
                              selectedSubCategory: state.selectedSubCategory,
                              detailsItemCount: state.detailsItemCount,
                              detailsSubCount: state.detailsSubCount,
                              onEdit: () => _showEditDialog(context, state),
                              onDelete: () => _confirmDelete(context, state),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, CategoriesReady state,
      AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      elevation: AppTokens.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => _onSearch(context, val),
          decoration: InputDecoration(
            hintText: loc.searchDepartmentsCategoriesHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch(context, '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius6),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingStandard,
                vertical: AppTokens.spacingStandard),
            isDense: true,
          ),
        ),
      ),
    );
  }

  // Dialog Helpers

  void _showAddDepartment(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    final repo = context.read<CategoriesRepository>();
    showDialog(
      context: context,
      builder: (ctx) => DepartmentDialog(
        onValidate: (name, {excludeId}) =>
            repo.departmentExists(name, excludeId: excludeId),
        onSave: (dept) => bloc.add(AddDepartment(dept)),
      ),
    );
  }

  void _showAddCategory(BuildContext context, CategoriesReady state) {
    final bloc = context.read<CategoriesBloc>();
    final repo = context.read<CategoriesRepository>();
    showDialog(
      context: context,
      builder: (ctx) => CategoryDialog(
        parentDeptId: state.selectedDepartment?.id,
        departments: state.departments,
        onValidate: (deptId, name, {excludeId}) =>
            repo.categoryExists(deptId, name, excludeId: excludeId),
        onSave: (cat) => bloc.add(AddCategory(cat)),
      ),
    );
  }

  void _showAddSubCategory(
      BuildContext context, CategoriesReady state, Category category) {
    final bloc = context.read<CategoriesBloc>();
    final repo = context.read<CategoriesRepository>();
    showDialog(
      context: context,
      builder: (ctx) => SubCategoryDialog(
        parentCatId: category.id,
        categories: state.categories,
        onValidate: (catId, name, {excludeId}) =>
            repo.subCategoryExists(catId, name, excludeId: excludeId),
        onSave: (sub) => bloc.add(AddSubCategory(sub)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, CategoriesReady state) {
    final bloc = context.read<CategoriesBloc>();
    final repo = context.read<CategoriesRepository>();
    if (state.selectionLevel == 1 && state.selectedDepartment != null) {
      showDialog(
        context: context,
        builder: (ctx) => DepartmentDialog(
          department: state.selectedDepartment,
          onValidate: (name, {excludeId}) =>
              repo.departmentExists(name, excludeId: excludeId),
          onSave: (dept) => bloc.add(UpdateDepartment(dept)),
        ),
      );
    } else if (state.selectionLevel == 2 && state.selectedCategory != null) {
      showDialog(
        context: context,
        builder: (ctx) => CategoryDialog(
          category: state.selectedCategory,
          departments: state.departments,
          onValidate: (deptId, name, {excludeId}) =>
              repo.categoryExists(deptId, name, excludeId: excludeId),
          onSave: (cat) => bloc.add(UpdateCategory(cat)),
        ),
      );
    } else if (state.selectionLevel == 3 && state.selectedSubCategory != null) {
      showDialog(
        context: context,
        builder: (ctx) => SubCategoryDialog(
          subCategory: state.selectedSubCategory,
          categories: state.categories,
          onValidate: (catId, name, {excludeId}) =>
              repo.subCategoryExists(catId, name, excludeId: excludeId),
          onSave: (sub) => bloc.add(UpdateSubCategory(sub)),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, CategoriesReady state) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final loc = AppLocalizations.of(ctx)!;
            return AlertDialog(
              title: Text(loc.confirmDeleteTitle),
              content: Text(loc.confirmDeleteMessage),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(loc.no)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.yesDelete,
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.onError)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!context.mounted) return;

    final bloc = context.read<CategoriesBloc>();

    if (!confirm) return;

    if (state.selectionLevel == 1 && state.selectedDepartment?.id != null) {
      bloc.add(DeleteDepartment(state.selectedDepartment!.id!));
    } else if (state.selectionLevel == 2 && state.selectedCategory?.id != null) {
      bloc.add(DeleteCategory(state.selectedCategory!.id!));
    } else if (state.selectionLevel == 3 && state.selectedSubCategory?.id != null) {
      bloc.add(DeleteSubCategory(state.selectedSubCategory!.id!));
    }
  }
}
