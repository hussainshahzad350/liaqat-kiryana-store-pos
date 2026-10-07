import 'package:flutter/material.dart';

import '../../../core/repositories/categories_repository.dart';
import '../../../core/repositories/units_repository.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/category_models.dart';
import '../../../models/product_model.dart';
import '../../../models/unit_model.dart';
import '../../../core/utils/error_handler.dart';

class ItemFormDialog extends StatefulWidget {
  final Product? product;
  final CategoriesRepository categoriesRepository;
  final UnitsRepository unitsRepository;

  const ItemFormDialog({
    super.key,
    this.product,
    required this.categoriesRepository,
    required this.unitsRepository,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  String? _nameError;
  late final Future<List<dynamic>> _formData;
  late TextEditingController _nameEngCtrl;
  late TextEditingController _nameUrduCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _packingCtrl;
  late TextEditingController _tagsCtrl;

  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  List<SubCategory> _subCategories = [];
  int? _selectedUnitId;
  String? _selectedUnitType;

  @override
  void initState() {
    super.initState();
    _formData = Future.wait<dynamic>([
      widget.categoriesRepository.getAllCategories(),
      widget.unitsRepository.getUnits(),
    ]);
    _nameEngCtrl = TextEditingController(text: widget.product?.nameEnglish);
    _nameUrduCtrl = TextEditingController(text: widget.product?.nameUrdu);
    _brandCtrl = TextEditingController(text: widget.product?.brand);
    _packingCtrl = TextEditingController(text: widget.product?.packingType);
    _tagsCtrl = TextEditingController(text: widget.product?.searchTags);

    _selectedCategoryId = widget.product?.categoryId;
    _selectedSubCategoryId = widget.product?.subCategoryId;
    if (_selectedCategoryId != null) {
      _fetchSubCategories(_selectedCategoryId!);
    }
    _selectedUnitId = widget.product?.unitId;
    _selectedUnitType = widget.product?.unitType;
  }

  @override
  void dispose() {
    _nameEngCtrl.dispose();
    _nameUrduCtrl.dispose();
    _brandCtrl.dispose();
    _packingCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSubCategories(int categoryId) async {
    try {
      final subs = await widget.categoriesRepository
          .getSubCategoriesByCategory(categoryId);
      if (mounted) {
        setState(() {
          _subCategories = subs;
          // Ensure the selected subcategory exists in the fetched list
          if (subs.isNotEmpty &&
              _selectedSubCategoryId != null &&
              !subs.any((s) => s.id == _selectedSubCategoryId)) {
            _selectedSubCategoryId = null;
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle:
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.formFieldBorderRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.formFieldBorderRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.formFieldBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.product != null;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        isEdit ? localizations.editItem : localizations.addItem,
        style: textTheme.titleLarge,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.dialogWidth),
        child: FutureBuilder(
          future: _formData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: AppTokens.dialogHeight,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(
                  height: AppTokens.dialogHeight,
                  child: Center(
                      child: Text(ErrorHandler.getLocalizedMessage(
                          snapshot.error.toString(), localizations))));
            }

            final categories = snapshot.data?[0] as List<Category>? ?? [];
            final units = snapshot.data?[1] as List<Unit>? ?? [];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppTokens.spacingStandard),
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: _nameEngCtrl,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                      style: textTheme.bodyLarge,
                      decoration: _buildInputDecoration(
                              localizations.englishName,
                              Icons.inventory_2_outlined)
                          .copyWith(errorText: _nameError),
                    )),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                        child: TextField(
                      controller: _nameUrduCtrl,
                      decoration: _buildInputDecoration(
                          localizations.urduName, Icons.translate),
                      style: textTheme.bodyLarge
                          ?.copyWith(fontFamily: 'NooriNastaleeq'),
                    )),
                  ]),
                  const SizedBox(height: AppTokens.spacingMedium),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedCategoryId,
                      decoration: _buildInputDecoration(
                          localizations.category, Icons.category_outlined),
                      items: categories
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.nameEn)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedSubCategoryId = null;
                          _subCategories = [];
                        });
                        if (val != null) _fetchSubCategories(val);
                      },
                    )),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                        child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _subCategories
                              .any((s) => s.id == _selectedSubCategoryId)
                          ? _selectedSubCategoryId
                          : null,
                      decoration: _buildInputDecoration(
                          localizations.subCategory,
                          Icons.subdirectory_arrow_right),
                      items: _subCategories
                          .where((s) => s.id != null)
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.nameEn)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSubCategoryId = val),
                    )),
                  ]),
                  const SizedBox(height: AppTokens.spacingMedium),
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: _brandCtrl,
                      decoration: _buildInputDecoration(localizations.brand,
                          Icons.branding_watermark_outlined),
                    )),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                        child: TextField(
                            controller: _packingCtrl,
                            decoration: _buildInputDecoration(
                                localizations.packingType,
                                Icons.archive_outlined))),
                  ]),
                  const SizedBox(height: AppTokens.spacingMedium),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedUnitId,
                      decoration: _buildInputDecoration(
                          localizations.unit, Icons.straighten),
                      items: units
                          .map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} (${u.code})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedUnitId = val;
                        _selectedUnitType =
                            units.firstWhere((u) => u.id == val).code;
                      }),
                    )),
                    const SizedBox(width: AppTokens.spacingMedium),
                    Expanded(
                        child: TextField(
                            controller: _tagsCtrl,
                            decoration: _buildInputDecoration(
                                localizations.searchTags, Icons.tag))),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel)),
        ElevatedButton(
          onPressed: () {
            if (_nameEngCtrl.text.trim().isEmpty) {
              setState(() => _nameError =
                  localizations.fieldRequired(localizations.englishName));
              return;
            }
            final product =
                (widget.product ?? Product(nameEnglish: '')).copyWith(
              nameEnglish: _nameEngCtrl.text.trim(),
              nameUrdu: _nameUrduCtrl.text.trim(),
              categoryId: _selectedCategoryId,
              subCategoryId: _selectedSubCategoryId,
              brand: _brandCtrl.text.trim(),
              unitId: _selectedUnitId,
              unitType: _selectedUnitType,
              packingType: _packingCtrl.text,
              searchTags: _tagsCtrl.text,
            );
            Navigator.pop(context, product);
          },
          child: Text(isEdit ? localizations.update : localizations.save),
        ),
      ],
    );
  }
}
