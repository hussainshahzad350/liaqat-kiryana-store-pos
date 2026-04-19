import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';
import '../utils/category_ui_utils.dart';

class DepartmentListWidget extends StatelessWidget {
  final List<Department> departments;
  final Department? selectedDepartment;
  final Map<String, Set<int>>? searchResults;
  final String searchQuery;
  final Function(Department) onSelect;
  final VoidCallback onAdd;

  const DepartmentListWidget({
    super.key,
    required this.departments,
    this.selectedDepartment,
    this.searchResults,
    required this.searchQuery,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredDepts = searchResults == null
        ? departments
        : departments.where((d) => searchResults!['departments']?.contains(d.id) ?? false).toList();

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
                loc.departmentsHeader,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: AppTokens.iconSizeMedium),
                onPressed: onAdd,
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
              final isSelected = selectedDepartment?.id == dept.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
                onTap: () => onSelect(dept),
                leading: Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTokens.radius8),
                  ),
                ),
                title: buildHighlightedText(
                  dept.nameEn,
                  searchQuery,
                  (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                  colorScheme.primaryContainer,
                ),
                subtitle: buildHighlightedText(
                  dept.nameUr,
                  searchQuery,
                  (textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'NooriNastaleeq',
                      height: 1.2,
                  ),
                  colorScheme.primaryContainer,
                ),
                trailing: !dept.isActive
                    ? Icon(Icons.visibility_off, size: 14, color: colorScheme.outline)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
