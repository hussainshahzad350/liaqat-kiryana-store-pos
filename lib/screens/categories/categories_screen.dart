import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_models.dart';
import '../../core/repositories/categories_repository.dart';
import '../../core/constants/desktop_dimensions.dart';

// ==========================================
// SCREEN IMPLEMENTATION
// ==========================================

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoriesRepository _repository = CategoriesRepository();
  // --- State Variables ---
  Department? _selectedDepartment;
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  // Selection Mode to determine what to show in Right Pane
  // 0: None, 1: Department, 2: Category, 3: SubCategory
  int _selectionLevel = 0;

  // --- Data Store ---
  List<Department> _departments = [];
  List<Category> _categories = [];
  // Cache for lazy loaded subcategories: categoryId -> List<SubCategory>
  final Map<int, List<SubCategory>> _subCategoryCache = {};
  bool _isLoading = true;
  bool _isLoadingCategories = false;

  // --- Search ---
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  Map<String, Set<int>>? _searchResults;

  // --- Details Pane Data ---
  int _detailsItemCount = 0; // Products count
  int _detailsSubCount = 0; // Sub-entities count (Cats or SubCats)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final depts = await _repository.getAllDepartments();

    if (!mounted) return;
    setState(() {
      _departments = depts;
      _isLoading = false;

      // Maintain selection if possible, else reset
      if (_selectedDepartment != null) {
        if (!_departments.any((d) => d.id == _selectedDepartment!.id)) {
          _resetSelection();
        } else {
          // Reload categories for the selected department
          _loadCategories(_selectedDepartment!.id!);
        }
      } else if (_departments.isNotEmpty) {
        // Default select first department
        _onDepartmentSelected(_departments.first);
      }
    });
  }

  void _resetSelection() {
    _selectedDepartment = null;
    _selectedCategory = null;
    _selectedSubCategory = null;
    _selectionLevel = 0;
    _categories = [];
    _subCategoryCache.clear();
  }

  Future<void> _loadCategories(int deptId) async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);
    final cats = await _repository.getCategoriesByDepartment(deptId);
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadSubCategories(int catId) async {
    if (_subCategoryCache.containsKey(catId)) return;

    final subs = await _repository.getSubCategoriesByCategory(catId);
    if (mounted) {
      setState(() {
        _subCategoryCache[catId] = subs;
      });
      _updateDetails();
    }
  }

  void _onDepartmentSelected(Department dept) {
    if (_selectedDepartment?.id == dept.id) return;

    setState(() {
      _selectedDepartment = dept;
      _selectedCategory = null;
      _selectedSubCategory = null;
      _selectionLevel = 1;
      _categories = [];
      _subCategoryCache.clear();
    });
    _loadCategories(dept.id!);
    _updateDetails();
  }

  Future<void> _updateDetails() async {
    int items = 0;
    int subs = 0;

    if (_selectionLevel == 1 && _selectedDepartment != null) {
      subs = await _repository.getCategoryCount(_selectedDepartment!.id!);
      items = await _repository
          .getProductCountByDepartment(_selectedDepartment!.id!);
    } else if (_selectionLevel == 2 && _selectedCategory != null) {
      subs = await _repository.getSubCategoryCount(_selectedCategory!.id!);
      items =
          await _repository.getProductCountByCategory(_selectedCategory!.id!);
    }
    // Subcategories (Level 3) don't have children or direct product links in this schema

    if (mounted) {
      setState(() {
        _detailsItemCount = items;
        _detailsSubCount = subs;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _repository.searchHierarchy(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  // --- CRUD Dialogs ---

  void _showErrorDialog(String message) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.error),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.ok)),
        ],
      ),
    );
  }

  void _showDepartmentDialog({Department? department}) {
    final loc = AppLocalizations.of(context)!;
    final nameEnController = TextEditingController(text: department?.nameEn);
    final nameUrController = TextEditingController(text: department?.nameUr);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(department == null ? loc.addDepartment : loc.editDepartment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: DesktopDimensions.spacingMedium),
              child: TextField(
                controller: nameEnController,
                decoration: InputDecoration(labelText: loc.nameEnglishLabel),
              ),
            ),
            TextField(
              controller: nameUrController,
              decoration: InputDecoration(labelText: loc.nameUrduLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameEnController.text.isEmpty) return;

              final exists = await _repository.departmentExists(
                  nameEnController.text.trim(),
                  excludeId: department?.id);
              if (exists) {
                if (context.mounted) {
                  _showErrorDialog(loc.departmentExistsError);
                }
                return;
              }

              final dept = Department(
                id: department?.id,
                nameEn: nameEnController.text.trim(),
                nameUr: nameUrController.text,
                isActive: department?.isActive ?? true,
                isVisibleInPOS: department?.isVisibleInPOS ?? true,
              );
              if (department == null) {
                await _repository.addDepartment(dept);
              } else {
                await _repository.updateDepartment(dept);
              }
              _loadData();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({Category? category, int? parentDeptId}) {
    final loc = AppLocalizations.of(context)!;
    final nameEnController = TextEditingController(text: category?.nameEn);
    final nameUrController = TextEditingController(text: category?.nameUr);
    int? selectedDeptId = category?.departmentId ?? parentDeptId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? loc.addCategory : loc.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDeptId,
                decoration: InputDecoration(labelText: loc.departmentLabel),
                items: _departments
                    .map((d) =>
                        DropdownMenuItem(value: d.id, child: Text(d.nameEn)))
                    .toList(),
                onChanged: (val) => setState(() => selectedDeptId = val),
              ),
              TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(labelText: loc.nameEnglishLabel)),
              TextField(
                  controller: nameUrController,
                  decoration: InputDecoration(labelText: loc.nameUrduLabel)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameEnController.text.isEmpty || selectedDeptId == null) {
                  return;
                }

                final exists = await _repository.categoryExists(
                    selectedDeptId!, nameEnController.text.trim(),
                    excludeId: category?.id);
                if (exists) {
                  if (context.mounted) {
                    _showErrorDialog(loc.categoryExistsError);
                  }
                  return;
                }

                final cat = Category(
                  id: category?.id,
                  departmentId: selectedDeptId,
                  nameEn: nameEnController.text.trim(),
                  nameUr: nameUrController.text,
                  isActive: category?.isActive ?? true,
                  isVisibleInPOS: category?.isVisibleInPOS ?? true,
                );
                if (category == null) {
                  await _repository.addCategory(cat);
                } else {
                  await _repository.updateCategory(cat);
                }
                _loadData();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryDialog({SubCategory? subCategory, int? parentCatId}) {
    final loc = AppLocalizations.of(context)!;
    final nameEnController = TextEditingController(text: subCategory?.nameEn);
    final nameUrController = TextEditingController(text: subCategory?.nameUr);
    int? selectedCatId = subCategory?.categoryId ?? parentCatId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              subCategory == null ? loc.addSubcategory : loc.editSubcategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCatId,
                decoration: InputDecoration(labelText: loc.category),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.nameEn)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCatId = val),
              ),
              TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(labelText: loc.nameEnglishLabel)),
              TextField(
                  controller: nameUrController,
                  decoration: InputDecoration(labelText: loc.nameUrduLabel)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameEnController.text.isEmpty || selectedCatId == null) {
                  return;
                }

                final exists = await _repository.subCategoryExists(
                    selectedCatId!, nameEnController.text.trim(),
                    excludeId: subCategory?.id);
                if (exists) {
                  if (context.mounted) {
                    _showErrorDialog(loc.subcategoryExistsError);
                  }
                  return;
                }

                final sub = SubCategory(
                  id: subCategory?.id,
                  categoryId: selectedCatId!,
                  nameEn: nameEnController.text.trim(),
                  nameUr: nameUrController.text,
                  isActive: subCategory?.isActive ?? true,
                  isVisibleInPOS: subCategory?.isVisibleInPOS ?? true,
                );
                if (subCategory == null) {
                  await _repository.addSubCategory(sub);
                } else {
                  await _repository.updateSubCategory(sub);
                }
                _loadData();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem() async {
    if (_selectionLevel == 0) return;
    final loc = AppLocalizations.of(context)!;

    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.confirmDeleteTitle),
            content: Text(loc.confirmDeleteMessage),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(loc.no)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.yesDelete,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    if (_selectionLevel == 1 && _selectedDepartment != null) {
      await _repository.deleteDepartment(_selectedDepartment!.id!);
      _selectedDepartment = null;
    } else if (_selectionLevel == 2 && _selectedCategory != null) {
      await _repository.deleteCategory(_selectedCategory!.id!);
      _selectedCategory = null;
    } else if (_selectionLevel == 3 && _selectedSubCategory != null) {
      await _repository.deleteSubCategory(_selectedSubCategory!.id!);
      _selectedSubCategory = null;
    }

    _selectionLevel = 0;
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Padding(
      padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
      child: Column(
        children: [
          Card(
            elevation: DesktopDimensions.cardElevation,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
            child: Padding(
              padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: loc.searchDepartmentsCategoriesHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius / 2),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesktopDimensions.spacingStandard,
                      vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesktopDimensions.spacingMedium),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: DesktopDimensions.sidebarWidthSmall,
                  child: Card(
                    elevation: DesktopDimensions.cardElevation,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius),
                        child: _buildDepartmentsPane(loc, colorScheme)),
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: DesktopDimensions.cardElevation,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius),
                        child: _buildTaxonomyPane(loc, colorScheme)),
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: DesktopDimensions.cardElevation,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.cardBorderRadius),
                        child: _buildDetailsPane(loc, colorScheme)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS: PANE 1 (DEPARTMENTS)
  // ==========================================

  Widget _buildDepartmentsPane(AppLocalizations loc, ColorScheme colorScheme) {
    final filteredDepts = _searchResults == null
        ? _departments
        : _departments
            .where((d) => _searchResults!['departments']!.contains(d.id))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DesktopDimensions.spacingStandard),
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.departmentsHeader,
                style: TextStyle(
                  fontSize: DesktopDimensions.captionSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    size: DesktopDimensions.iconSizeMedium),
                onPressed: () {
                  _showDepartmentDialog();
                },
                tooltip: loc.addDepartment,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredDepts.length,
            itemBuilder: (context, index) {
              final dept = filteredDepts[index];
              final isSelected = _selectedDepartment?.id == dept.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor:
                    colorScheme.primaryContainer.withOpacity(0.4),
                onTap: () => _onDepartmentSelected(dept),
                leading: Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colorScheme.primary : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(DesktopDimensions.spacingSmall),
                  ),
                ),
                title: _buildHighlightedText(
                  dept.nameEn,
                  TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                  colorScheme.primaryContainer,
                ),
                subtitle: _buildHighlightedText(
                  dept.nameUr,
                  TextStyle(
                      fontSize: DesktopDimensions.captionSize,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'NooriNastaleeq'),
                  colorScheme.primaryContainer,
                ),
                trailing: !dept.isActive
                    ? Icon(Icons.visibility_off,
                        size: 14, color: colorScheme.outline)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS: PANE 2 (TAXONOMY TREE)
  // ==========================================

  Widget _buildTaxonomyPane(AppLocalizations loc, ColorScheme colorScheme) {
    if (_selectedDepartment == null) {
      return Center(
          child: Text(loc.selectDepartmentInstruction,
              style: TextStyle(color: colorScheme.outline)));
    }

    final filteredCats = _searchResults == null
        ? _categories
        : _categories
            .where((c) => _searchResults!['categories']!.contains(c.id))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DesktopDimensions.spacingStandard),
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.categoriesSubcategoriesHeader,
                style: TextStyle(
                  fontSize: DesktopDimensions.captionSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add,
                    size: DesktopDimensions.iconSizeMedium),
                onPressed: () {
                  _showCategoryDialog(parentDeptId: _selectedDepartment!.id);
                },
                tooltip: loc.addCategoryToTooltip(_selectedDepartment!.nameEn),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (_isLoadingCategories)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
              itemCount: filteredCats.length,
              itemBuilder: (context, index) {
                final cat = filteredCats[index];
                final subCats = _subCategoryCache[cat.id] ?? [];
                final bool isLoaded = _subCategoryCache.containsKey(cat.id);
                final isCatSelected =
                    _selectedCategory?.id == cat.id && _selectionLevel == 2;

                final filteredSubs = _searchResults == null
                    ? subCats
                    : subCats
                        .where((s) =>
                            _searchResults!['subcategories']!.contains(s.id))
                        .toList();

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isCatSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isCatSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.cardBorderRadius),
                  ),
                  margin: const EdgeInsets.only(
                      bottom: DesktopDimensions.spacingStandard),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey('cat_${cat.id}'),
                      initiallyExpanded:
                          _searchResults != null, // Auto expand on search
                      onExpansionChanged: (expanded) {
                        if (expanded) _loadSubCategories(cat.id!);
                      },
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      leading: Icon(Icons.folder, color: colorScheme.secondary),
                      title: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedSubCategory = null;
                            _selectionLevel = 2;
                            _updateDetails();
                          });
                        },
                        child: Row(
                          children: [
                            _buildHighlightedText(
                                cat.nameEn,
                                const TextStyle(fontWeight: FontWeight.bold),
                                colorScheme.primaryContainer),
                            const SizedBox(
                                width: DesktopDimensions.spacingMedium),
                            _buildHighlightedText(
                                cat.nameUr,
                                TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'NooriNastaleeq'),
                                colorScheme.primaryContainer),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add,
                            size: DesktopDimensions.iconSizeMedium),
                        onPressed: () {
                          _showSubCategoryDialog(parentCatId: cat.id);
                        },
                        tooltip: loc.addSubcategoryTooltip,
                      ),
                      children: [
                        if (!isLoaded)
                          const Padding(
                            padding:
                                EdgeInsets.all(DesktopDimensions.spacingLarge),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          )
                        else if (filteredSubs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(
                                DesktopDimensions.spacingLarge),
                            child: Text(
                              loc.noSubcategories,
                              style: TextStyle(
                                  fontSize: DesktopDimensions.captionSize,
                                  color: colorScheme.outline),
                            ),
                          ),
                        if (isLoaded)
                          ...filteredSubs.map((sub) {
                            final isSubSelected =
                                _selectedSubCategory?.id == sub.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.only(
                                  left: DesktopDimensions.spacingXXLarge,
                                  right: DesktopDimensions.spacingLarge),
                              selected: isSubSelected,
                              selectedTileColor:
                                  colorScheme.primaryContainer.withOpacity(0.5),
                              onTap: () {
                                setState(() {
                                  _selectedCategory =
                                      cat; // Ensure parent is selected contextually
                                  _selectedSubCategory = sub;
                                  _selectionLevel = 3;
                                  _updateDetails();
                                });
                              },
                              leading: Icon(Icons.subdirectory_arrow_right,
                                  size: 16, color: colorScheme.outline),
                              title: _buildHighlightedText(
                                  sub.nameEn,
                                  const TextStyle(),
                                  colorScheme.primaryContainer),
                              subtitle: _buildHighlightedText(
                                  sub.nameUr,
                                  TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontFamily: 'NooriNastaleeq'),
                                  colorScheme.primaryContainer),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==========================================
  // WIDGETS: PANE 3 (DETAILS & MANAGEMENT)
  // ==========================================

  Widget _buildDetailsPane(AppLocalizations loc, ColorScheme colorScheme) {
    if (_selectionLevel == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 48, color: colorScheme.outlineVariant),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Text(loc.selectItemToManageInstruction,
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    String titleEn = '';
    String titleUr = '';
    String typeLabel = '';
    bool isActive = true;
    bool isVisibleInPOS = true;

    if (_selectionLevel == 1 && _selectedDepartment != null) {
      titleEn = _selectedDepartment!.nameEn;
      titleUr = _selectedDepartment!.nameUr;
      typeLabel = loc.typeDepartment;
      isActive = _selectedDepartment!.isActive;
      isVisibleInPOS = _selectedDepartment!.isVisibleInPOS;
    } else if (_selectionLevel == 2 && _selectedCategory != null) {
      titleEn = _selectedCategory!.nameEn;
      titleUr = _selectedCategory!.nameUr;
      typeLabel = loc.typeCategory;
      isActive = _selectedCategory!.isActive;
      isVisibleInPOS = _selectedCategory!.isVisibleInPOS;
    } else if (_selectionLevel == 3 && _selectedSubCategory != null) {
      titleEn = _selectedSubCategory!.nameEn;
      titleUr = _selectedSubCategory!.nameUr;
      typeLabel = loc.typeSubcategory;
      isActive = _selectedSubCategory!.isActive;
      isVisibleInPOS = _selectedSubCategory!.isVisibleInPOS;
    }

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesktopDimensions.spacingXXLarge,
              vertical: DesktopDimensions.spacingXLarge,
            ),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesktopDimensions.spacingMedium,
                          vertical: DesktopDimensions.spacingSmall),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                            DesktopDimensions.spacingSmall),
                      ),
                      child: Text(
                        typeLabel.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopDimensions.spacingLarge),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleEn,
                              style: const TextStyle(
                                  fontSize: DesktopDimensions.headingSize,
                                  fontWeight: FontWeight.bold)),
                          Text(titleUr,
                              style: const TextStyle(
                                  fontSize: DesktopDimensions.bodySize,
                                  fontFamily: 'NooriNastaleeq')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesktopDimensions.spacingMedium),
                // Breadcrumbs
                _buildBreadcrumbs(loc, colorScheme),

                const SizedBox(height: DesktopDimensions.spacingXXLarge),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (_selectionLevel == 1) {
                            _showDepartmentDialog(
                                department: _selectedDepartment);
                          }
                          if (_selectionLevel == 2) {
                            _showCategoryDialog(category: _selectedCategory);
                          }
                          if (_selectionLevel == 3) {
                            _showSubCategoryDialog(
                                subCategory: _selectedSubCategory);
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(loc.editDetails),
                      ),
                    ),
                    const SizedBox(width: DesktopDimensions.spacingStandard),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleteItem,
                        icon: const Icon(Icons.delete, size: 18),
                        label: Text(loc.delete),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Specific Content based on selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesktopDimensions.spacingXXLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Section
                  Text(
                    loc.statusVisibilityHeader,
                    style: TextStyle(
                      fontSize: DesktopDimensions.captionSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: DesktopDimensions.spacingMedium),
                  SwitchListTile(
                    title: Text(loc.active),
                    subtitle: Text(loc.activeSubtitle),
                    value: isActive,
                    onChanged: (val) async {
                      await _updateStatus(
                          isActive: val, isVisible: isVisibleInPOS);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingMedium,
                        vertical: DesktopDimensions.spacingSmall),
                  ),
                  SwitchListTile(
                    title: Text(loc.visibleInPOS),
                    subtitle: Text(loc.visibleInPOSSubtitle),
                    value: isVisibleInPOS,
                    onChanged: (val) async {
                      await _updateStatus(isActive: isActive, isVisible: val);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingMedium,
                        vertical: DesktopDimensions.spacingSmall),
                  ),
                  const Divider(height: DesktopDimensions.spacingXXLarge),

                  // Stats for all levels
                  _buildStats(loc, colorScheme, typeLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(AppLocalizations loc, ColorScheme colorScheme) {
    List<String> parts = [loc.home];
    if (_selectedDepartment != null) parts.add(_selectedDepartment!.nameEn);
    if (_selectionLevel >= 2 && _selectedCategory != null) {
      parts.add(_selectedCategory!.nameEn);
    }
    if (_selectionLevel >= 3 && _selectedSubCategory != null) {
      parts.add(_selectedSubCategory!.nameEn);
    }

    return Wrap(
      children: parts.asMap().entries.map((entry) {
        final isLast = entry.key == parts.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.value,
                style: TextStyle(
                    color: isLast ? colorScheme.onSurface : colorScheme.outline,
                    fontSize: DesktopDimensions.captionSize)),
            if (!isLast)
              Icon(Icons.chevron_right, size: 16, color: colorScheme.outline),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStats(
      AppLocalizations loc, ColorScheme colorScheme, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.statisticsHeader,
          style: TextStyle(
            fontSize: DesktopDimensions.captionSize,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: DesktopDimensions.spacingMedium),
        if (_selectionLevel == 1)
          _buildStatRow(loc.categories, _detailsSubCount.toString(),
              Icons.folder, colorScheme),
        if (_selectionLevel == 2)
          _buildStatRow(loc.subcategories, _detailsSubCount.toString(),
              Icons.subdirectory_arrow_right, colorScheme),

        // Items count (Products)
        _buildStatRow(loc.totalItems, _detailsItemCount.toString(),
            Icons.inventory_2, colorScheme),
      ],
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesktopDimensions.spacingStandard),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesktopDimensions.spacingSmall),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.cardBorderRadius / 2),
            ),
            child: Icon(icon,
                size: DesktopDimensions.kpiIconSize,
                color: colorScheme.primary),
          ),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Text(label, style: TextStyle(color: colorScheme.onSurface)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      {required bool isActive, required bool isVisible}) async {
    if (_selectionLevel == 1) {
      final updated = Department(
          id: _selectedDepartment!.id,
          nameEn: _selectedDepartment!.nameEn,
          nameUr: _selectedDepartment!.nameUr,
          isActive: isActive,
          isVisibleInPOS: isVisible);
      await _repository.updateDepartment(updated);
    } else if (_selectionLevel == 2) {
      final updated = Category(
          id: _selectedCategory!.id,
          departmentId: _selectedCategory!.departmentId,
          nameEn: _selectedCategory!.nameEn,
          nameUr: _selectedCategory!.nameUr,
          isActive: isActive,
          isVisibleInPOS: isVisible);
      await _repository.updateCategory(updated);
    } else if (_selectionLevel == 3) {
      final updated = SubCategory(
          id: _selectedSubCategory!.id,
          categoryId: _selectedSubCategory!.categoryId,
          nameEn: _selectedSubCategory!.nameEn,
          nameUr: _selectedSubCategory!.nameUr,
          isActive: isActive,
          isVisibleInPOS: isVisible);
      await _repository.updateSubCategory(updated);
    }
    _loadData();
  }

  Widget _buildHighlightedText(
      String text, TextStyle baseStyle, Color highlightColor) {
    final query = _searchController.text;
    if (query.isEmpty) return Text(text, style: baseStyle);

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) return Text(text, style: baseStyle);

    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: baseStyle.copyWith(
            backgroundColor: highlightColor, fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
