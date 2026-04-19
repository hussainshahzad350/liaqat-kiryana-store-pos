import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/category_models.dart';
import '../../../../core/res/app_tokens.dart';

class DepartmentDialog extends StatefulWidget {
  final Department? department;
  final Future<bool> Function(String, {int? excludeId}) onValidate;
  final Function(Department) onSave;

  const DepartmentDialog({
    super.key,
    this.department,
    required this.onValidate,
    required this.onSave,
  });

  @override
  State<DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<DepartmentDialog> {
  late TextEditingController _nameEnController;
  late TextEditingController _nameUrController;
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.department?.nameEn);
    _nameUrController = TextEditingController(text: widget.department?.nameUr);
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isValidating = true);
    final loc = AppLocalizations.of(context)!;

    final nameEn = _nameEnController.text.trim();
    final exists =
        await widget.onValidate(nameEn, excludeId: widget.department?.id);

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.departmentExistsError),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final dept = Department(
      id: widget.department?.id,
      nameEn: nameEn,
      nameUr: _nameUrController.text.trim(),
      isActive: widget.department?.isActive ?? true,
      isVisibleInPOS: widget.department?.isVisibleInPOS ?? true,
    );

    widget.onSave(dept);
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
                widget.department == null
                    ? loc.addDepartment
                    : loc.editDepartment,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              TextFormField(
                controller: _nameEnController,
                autofocus: true,
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
                    onPressed: _isValidating ? null : _submit,
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
