import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';

class SubCategoryDialog extends StatefulWidget {
  final SubCategory? subCategory;
  final int? parentCatId;
  final List<Category> categories;
  final Future<bool> Function(int, String, {int? excludeId}) onValidate;
  final Function(SubCategory) onSave;

  const SubCategoryDialog({
    super.key,
    this.subCategory,
    this.parentCatId,
    required this.categories,
    required this.onValidate,
    required this.onSave,
  });

  @override
  State<SubCategoryDialog> createState() => _SubCategoryDialogState();
}

class _SubCategoryDialogState extends State<SubCategoryDialog> {
  late TextEditingController _nameEnController;
  late TextEditingController _nameUrController;
  int? _selectedCatId;
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.subCategory?.nameEn);
    _nameUrController = TextEditingController(text: widget.subCategory?.nameUr);
    final candidateId = widget.subCategory?.categoryId ?? widget.parentCatId;
    final validIds = widget.categories.map((c) => c.id).toSet();
    _selectedCatId = (candidateId != null && validIds.contains(candidateId))
        ? candidateId
        : null;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCatId == null) return;

    setState(() => _isValidating = true);
    final loc = AppLocalizations.of(context)!;

    final nameEn = _nameEnController.text.trim();
    bool exists;
    try {
      exists = await widget.onValidate(_selectedCatId!, nameEn,
          excludeId: widget.subCategory?.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.unknownError),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }

    if (!mounted) return;

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.subcategoryExistsError),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final sub = SubCategory(
      id: widget.subCategory?.id,
      categoryId: _selectedCatId!,
      nameEn: nameEn,
      nameUr: _nameUrController.text.trim(),
      isActive: widget.subCategory?.isActive ?? true,
      isVisibleInPOS: widget.subCategory?.isVisibleInPOS ?? true,
    );

    widget.onSave(sub);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subCategory == null
                    ? loc.addSubcategory
                    : loc.editSubcategory,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              DropdownButtonFormField<int>(
                value: _selectedCatId,
                decoration: InputDecoration(
                  labelText: loc.category,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.nameEn)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCatId = val),
                validator: (val) => val == null ? loc.required : null,
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: loc.nameEnglishLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              TextFormField(
                controller: _nameUrController,
                decoration: InputDecoration(
                  labelText: loc.nameUrduLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style:
                    const TextStyle(fontFamily: 'NooriNastaleeq', height: 1.2),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  ElevatedButton(
                    onPressed: (_isValidating || _selectedCatId == null)
                        ? null
                        : _submit,
                    child: _isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
