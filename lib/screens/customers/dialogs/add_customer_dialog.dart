import 'package:flutter/material.dart';
import '../../../core/repositories/customers_repository.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../core/res/app_tokens.dart';

class AddCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final CustomersRepository repository;
  final VoidCallback onSaved;

  const AddCustomerDialog({
    super.key,
    this.customer,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _nameEnCtrl = TextEditingController();
  final _nameUrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();

  bool _isSaving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _nameEnCtrl.text = c.nameEnglish;
      _nameUrCtrl.text = c.nameUrdu ?? '';
      _phoneCtrl.text = c.contactPrimary ?? '';
      _addressCtrl.text = c.address ?? '';
      if (c.creditLimit > 0) {
        _limitCtrl.text = Money(c.creditLimit).toInputString();
      }
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameUrCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _limitCtrl.dispose();
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
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('${loc.phoneLabel} ${loc.requiredField}', colorScheme.error);
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final phone = _phoneCtrl.text.trim();
      final isUnique = await widget.repository.isPhoneUnique(
        phone,
        excludeId: widget.customer?.id,
      );
      if (!isUnique) throw Exception(loc.phoneExistsError);

      final customer = Customer(
        id: widget.customer?.id,
        nameEnglish: _nameEnCtrl.text.trim(),
        nameUrdu: _nameUrCtrl.text.trim(),
        contactPrimary: phone,
        address: _addressCtrl.text.trim(),
        creditLimit: Money.tryParse(_limitCtrl.text)?.paisas ?? 0,
        outstandingBalance: widget.customer?.outstandingBalance ?? 0,
        isActive: true,
      );

      if (_isEdit) {
        await widget.repository.updateCustomer(widget.customer!.id!, customer);
      } else {
        await widget.repository.addCustomer(customer);
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? loc.editCustomer : loc.addCustomer,
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

            // Fields
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
                      label: '${loc.phoneLabel} *',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      readOnly: _isEdit,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _addressCtrl,
                      label: loc.addressLabel,
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _Field(
                      controller: _limitCtrl,
                      label: loc.creditLimit,
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTokens.spacingLarge),

            // Actions
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
                      : Text(loc.save),
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
