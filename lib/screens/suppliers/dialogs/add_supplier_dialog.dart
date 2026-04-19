import 'package:flutter/material.dart';
import '../../../../core/repositories/suppliers_repository.dart';
import '../../../../domain/entities/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/supplier_model.dart';
import '../../../../core/res/app_tokens.dart';

class AddSupplierDialog extends StatefulWidget {
  final Supplier? supplier;
  final SuppliersRepository repository;
  final VoidCallback onSaved;

  const AddSupplierDialog({
    super.key,
    this.supplier,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _nameEnCtrl = TextEditingController();
  final _nameUrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  bool _isSaving = false;
  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    if (s != null) {
      _nameEnCtrl.text = s.nameEnglish;
      _nameUrCtrl.text = s.nameUrdu ?? '';
      _phoneCtrl.text = s.contactPrimary ?? '';
      _addressCtrl.text = s.address ?? '';
      _typeCtrl.text = s.supplierType ?? '';
      _balanceCtrl.text = Money(s.outstandingBalance).toInputString();
    } else {
      _balanceCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameUrCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _typeCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_nameEnCtrl.text.trim().isEmpty) {
      _showSnack('${loc.nameEnglish} ${loc.requiredField}', colorScheme.error);
      return;
    }
    if (_nameUrCtrl.text.trim().isEmpty) {
      _showSnack('${loc.nameUrdu} ${loc.requiredField}', colorScheme.error);
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        final isUnique = !(await widget.repository.supplierContactExists(
          phone,
          excludeId: widget.supplier?.id,
        ));
        if (!isUnique) throw Exception(loc.phoneExistsError);
      }

      final balanceText = _balanceCtrl.text.trim();
      final normalizedBalance = balanceText
          .replaceAll(',', '')
          .replaceAll(RegExp(r'rs\.?', caseSensitive: false), '')
          .trim();
      if (normalizedBalance.isNotEmpty &&
          double.tryParse(normalizedBalance) == null) {
        throw Exception(loc.invalidAmount);
      }
      final parsedBalance = Money.fromRupeesString(normalizedBalance);

      final suppMap = {
        'name_english': _nameEnCtrl.text.trim(),
        'name_urdu': _nameUrCtrl.text.trim(),
        'contact_primary': phone,
        'address': _addressCtrl.text.trim(),
        'supplier_type': _typeCtrl.text.trim(),
        'outstanding_balance': parsedBalance.paisas,
      };

      if (_isEdit) {
        await widget.repository.updateSupplier(widget.supplier!.id!, suppMap);
      } else {
        suppMap['created_at'] = DateTime.now().toIso8601String();
        await widget.repository.addSupplier(suppMap);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  void _showSnack(String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 450, maxWidth: 550),
        padding: const EdgeInsets.all(AppTokens.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? loc.editSupplier : loc.addSupplier,
                  style: textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppTokens.spacingMedium),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Field(
                      controller: _nameEnCtrl,
                      label: '${loc.nameEnglish} *',
                      icon: Icons.person,
                      readOnly: _isEdit,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _nameUrCtrl,
                      label: '${loc.nameUrdu} *',
                      icon: Icons.translate,
                      fontFamily: 'NooriNastaleeq',
                      readOnly: _isEdit,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _phoneCtrl,
                      label: loc.phoneNum,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      readOnly: _isEdit,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _addressCtrl,
                      label: loc.address,
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _typeCtrl,
                      label: loc.supplierType,
                      icon: Icons.category,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _balanceCtrl,
                      label: loc.balance,
                      icon: Icons.account_balance_wallet,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? SizedBox(
                          width: AppTokens.iconSizeMedium,
                          height: AppTokens.iconSizeMedium,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(_isEdit ? loc.update : loc.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final String? fontFamily;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: !readOnly,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        height: fontFamily != null ? 1.2 : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: AppTokens.iconSizeMedium, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
        ),
        isDense: true,
      ),
    );
  }
}
