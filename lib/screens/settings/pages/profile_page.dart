import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../widgets/setting_section.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameUrduController;
  late final TextEditingController _nameEnglishController;
  late final TextEditingController _addressController;
  late final TextEditingController _primaryPhoneController;
  late final TextEditingController _secondaryPhoneController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SettingsCubit>().state.shopProfile;
    _nameUrduController = TextEditingController(text: profile['name_urdu'] ?? '');
    _nameEnglishController = TextEditingController(text: profile['name_english'] ?? '');
    _addressController = TextEditingController(text: profile['address'] ?? '');
    _primaryPhoneController = TextEditingController(text: profile['phone_primary'] ?? '');
    _secondaryPhoneController = TextEditingController(text: profile['phone_secondary'] ?? '');
  }

  @override
  void dispose() {
    _nameUrduController.dispose();
    _nameEnglishController.dispose();
    _addressController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      context.read<SettingsCubit>().updateShopProfile({
        'name_urdu': _nameUrduController.text,
        'name_english': _nameEnglishController.text,
        'address': _addressController.text,
        'phone_primary': _primaryPhoneController.text,
        'phone_secondary': _secondaryPhoneController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SettingSection(
              title: loc.shopProfile,
              icon: Icons.store_outlined,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.store, size: 50, color: colorScheme.primary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Image picker placeholder")),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLarge),
                  _buildTextField(
                    controller: _nameUrduController,
                    label: loc.shopNameUrdu,
                    hint: 'لياقت کريانہ اسٹور',
                    isRTL: true,
                  ),
                  const SizedBox(height: AppTokens.spacingMedium),
                  _buildTextField(
                    controller: _nameEnglishController,
                    label: loc.shopNameEnglish,
                    hint: 'Liaqat Kiryana Store',
                  ),
                  const SizedBox(height: AppTokens.spacingMedium),
                  _buildTextField(
                    controller: _addressController,
                    label: loc.address,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppTokens.spacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _primaryPhoneController,
                          label: loc.primaryPhone,
                          hint: '0300-1234567',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingMedium),
                      Expanded(
                        child: _buildTextField(
                          controller: _secondaryPhoneController,
                          label: loc.secondaryPhone,
                          hint: '0300-7654321',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(loc.saveChanges),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
    bool isRTL = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.fieldRequired(label) : null
          : null,
    );
  }
}
