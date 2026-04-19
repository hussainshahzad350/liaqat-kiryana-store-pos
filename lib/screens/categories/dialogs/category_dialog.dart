import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';

class CategoryDialog extends StatefulWidget {
  final Category? category;
  final int? parentDeptId;
  final List<Department> departments;
  final Future<bool> Function(int, String, {int? excludeId}) onValidate;
  final Function(Category) onSave;

  const CategoryDialog({
    super.key,
    this.category,
    this.parentDeptId,
    required this.departments,
    required this.onValidate,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameEnController;
  late TextEditingController _nameUrController;
  int? _selectedDeptId;
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.category?.nameEn);
    _nameUrController = TextEditingController(text: widget.category?.nameUr);
    _selectedDeptId = widget.category?.departmentId ?? widget.parentDeptId;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDeptId == null) return;

    setState(() => _isValidating = true);
    final loc = AppLocalizations.of(context)!;
    
    final nameEn = _nameEnController.text.trim();
    final exists = await widget.onValidate(_selectedDeptId!, nameEn, excludeId: widget.category?.id);
    
    if (!mounted) return;
    setState(() => _isValidating = false);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.categoryExistsError), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final cat = Category(
      id: widget.category?.id,
      departmentId: _selectedDeptId,
      nameEn: nameEn,
      nameUr: _nameUrController.text.trim(),
      isActive: widget.category?.isActive ?? true,
      isVisibleInPOS: widget.category?.isVisibleInPOS ?? true,
    );
    
    widget.onSave(cat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
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
                widget.category == null ? loc.addCategory : loc.editCategory,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              DropdownButtonFormField<int>(
                value: _selectedDeptId,
                decoration: InputDecoration(
                  labelText: loc.departmentLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.departments
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameEn)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDeptId = val),
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
                validator: (val) => (val == null || val.isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              TextFormField(
                controller: _nameUrController,
                decoration: InputDecoration(
                  labelText: loc.nameUrduLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'NooriNastaleeq', height: 1.2),
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
                    onPressed: (_isValidating || _selectedDeptId == null) ? null : _submit,
                    child: _isValidating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
