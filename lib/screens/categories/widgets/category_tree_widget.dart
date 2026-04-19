import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';
import '../utils/category_ui_utils.dart';

class CategoryTreeWidget extends StatefulWidget {
  final List<Category> categories;
  final Department? selectedDepartment;
  final Category? selectedCategory;
  final SubCategory? selectedSubCategory;
  final Map<int, List<SubCategory>> subCategoryCache;
  final Map<String, Set<int>>? searchResults;
  final String searchQuery;
  final bool isLoading;

  final Function(Category) onCategorySelect;
  final Function(int) onPreloadSubCategories;
  final Function(SubCategory) onSubCategorySelect;
  final Function(Category) onAddSubCategory;
  final VoidCallback onAddCategory;

  const CategoryTreeWidget({
    super.key,
    required this.categories,
    this.selectedDepartment,
    this.selectedCategory,
    this.selectedSubCategory,
    required this.subCategoryCache,
    this.searchResults,
    required this.searchQuery,
    this.isLoading = false,
    required this.onCategorySelect,
    required this.onPreloadSubCategories,
    required this.onSubCategorySelect,
    required this.onAddSubCategory,
    required this.onAddCategory,
  });

  @override
  State<CategoryTreeWidget> createState() => _CategoryTreeWidgetState();
}

class _CategoryTreeWidgetState extends State<CategoryTreeWidget> {
  final Set<int> _preloadRequestedCategoryIds = <int>{};

  @override
  void initState() {
    super.initState();
    _scheduleSearchSubCategoryPreload();
  }

  @override
  void didUpdateWidget(covariant CategoryTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSearchSubCategoryPreload();
  }

  void _scheduleSearchSubCategoryPreload() {
    final results = widget.searchResults;
    if (results == null) return;

    final matchedSubCategoryIds = results['subcategories'];
    if (matchedSubCategoryIds == null || matchedSubCategoryIds.isEmpty) return;

    final matchedCategoryIds = results['categories'];
    if (matchedCategoryIds == null || matchedCategoryIds.isEmpty) return;

    final idsToPreload = widget.categories
        .where((category) =>
            category.id != null && matchedCategoryIds.contains(category.id))
        .map((category) => category.id!)
        .where((categoryId) =>
            !widget.subCategoryCache.containsKey(categoryId) &&
            !_preloadRequestedCategoryIds.contains(categoryId))
        .toList();

    if (idsToPreload.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final categoryId in idsToPreload) {
        _preloadRequestedCategoryIds.add(categoryId);
        widget.onPreloadSubCategories(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.selectedDepartment == null) {
      return Center(
          child: Text(loc.selectDepartmentInstruction,
              style: TextStyle(color: colorScheme.outline)));
    }

    final filteredCats = widget.searchResults == null
        ? widget.categories
        : widget.categories
            .where((c) =>
                widget.searchResults!['categories']?.contains(c.id) ?? false)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.spacingStandard),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.categoriesSubcategoriesHeader,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: AppTokens.iconSizeMedium),
                onPressed: widget.onAddCategory,
                tooltip:
                    loc.addCategoryToTooltip(widget.selectedDepartment!.nameEn),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (widget.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTokens.spacingMedium),
              itemCount: filteredCats.length,
              itemBuilder: (context, index) {
                final cat = filteredCats[index];
                final subCats = widget.subCategoryCache[cat.id] ?? [];
                final bool isLoaded =
                    widget.subCategoryCache.containsKey(cat.id);
                final isCatSelected = widget.selectedCategory?.id == cat.id;

                final filteredSubs = widget.searchResults == null
                    ? subCats
                    : subCats
                        .where((s) =>
                            widget.searchResults!['subcategories']
                                ?.contains(s.id) ??
                            false)
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
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardBorderRadius),
                  ),
                  margin:
                      const EdgeInsets.only(bottom: AppTokens.spacingStandard),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey('cat_${cat.id}'),
                      initiallyExpanded:
                          widget.searchResults != null || isCatSelected,
                      onExpansionChanged: (expanded) {
                        if (expanded && !isLoaded) widget.onCategorySelect(cat);
                      },
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      leading: Icon(Icons.folder, color: colorScheme.secondary),
                      title: InkWell(
                        onTap: () => widget.onCategorySelect(cat),
                        child: Row(
                          children: [
                            buildHighlightedText(
                                cat.nameEn,
                                widget.searchQuery,
                                (textTheme.bodyMedium ?? const TextStyle())
                                    .copyWith(fontWeight: FontWeight.bold),
                                colorScheme.primaryContainer),
                            const SizedBox(width: AppTokens.spacingMedium),
                            buildHighlightedText(
                                cat.nameUr,
                                widget.searchQuery,
                                (textTheme.bodySmall ?? const TextStyle())
                                    .copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFamily: 'NooriNastaleeq',
                                  height: 1.2,
                                ),
                                colorScheme.primaryContainer),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add,
                            size: AppTokens.iconSizeMedium),
                        onPressed: () => widget.onAddSubCategory(cat),
                        tooltip: loc.addSubcategoryTooltip,
                      ),
                      children: [
                        if (!isLoaded && isCatSelected)
                          const Padding(
                            padding: EdgeInsets.all(AppTokens.spacingLarge),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          )
                        else if (isLoaded && filteredSubs.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.all(AppTokens.spacingLarge),
                            child: Text(
                              loc.noSubcategories,
                              style: TextStyle(
                                  fontSize:
                                      textTheme.bodySmall?.fontSize ?? 12.0,
                                  color: colorScheme.outline),
                            ),
                          ),
                        if (isLoaded)
                          ...filteredSubs.map((sub) {
                            final isSubSelected =
                                widget.selectedSubCategory?.id == sub.id;
                            return ListTile(
                              dense: true,
                              selected: isSubSelected,
                              selectedTileColor: colorScheme.secondaryContainer
                                  .withValues(alpha: 0.3),
                              leading: const Padding(
                                padding: EdgeInsets.only(
                                    left: AppTokens.spacingLarge),
                                child: Icon(Icons.subdirectory_arrow_right,
                                    size: 16),
                              ),
                              title: buildHighlightedText(
                                sub.nameEn,
                                widget.searchQuery,
                                (textTheme.bodySmall ?? const TextStyle())
                                    .copyWith(
                                  fontWeight: isSubSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                colorScheme.primaryContainer,
                              ),
                              subtitle: buildHighlightedText(
                                sub.nameUr,
                                widget.searchQuery,
                                (textTheme.bodySmall ?? const TextStyle())
                                    .copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFamily: 'NooriNastaleeq',
                                  height: 1.2,
                                ),
                                colorScheme.primaryContainer,
                              ),
                              onTap: () => widget.onSubCategorySelect(sub),
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
}
