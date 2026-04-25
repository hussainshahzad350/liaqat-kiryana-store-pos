import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/settings/settings_cubit.dart';
import '../../../bloc/settings/settings_state.dart';
import '../widgets/setting_section.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/validators.dart';
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

  String _lastSyncedNameUrdu = '';
  String _lastSyncedNameEnglish = '';
  String _lastSyncedAddress = '';
  String _lastSyncedPrimaryPhone = '';
  String _lastSyncedSecondaryPhone = '';
  String? _primaryPhoneError;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SettingsCubit>().state.shopProfile;
    _lastSyncedNameUrdu = profile['name_urdu'] ?? '';
    _lastSyncedNameEnglish = profile['name_english'] ?? '';
    _lastSyncedAddress = profile['address'] ?? '';
    _lastSyncedPrimaryPhone = profile['phone_primary'] ?? '';
    _lastSyncedSecondaryPhone = profile['phone_secondary'] ?? '';

    _nameUrduController = TextEditingController(text: _lastSyncedNameUrdu);
    _nameEnglishController =
        TextEditingController(text: _lastSyncedNameEnglish);
    _addressController = TextEditingController(text: _lastSyncedAddress);
    _primaryPhoneController =
        TextEditingController(text: _lastSyncedPrimaryPhone);
    _secondaryPhoneController =
        TextEditingController(text: _lastSyncedSecondaryPhone);
  }

  void _syncControllersFromProfile(Map<String, dynamic> profile) {
    final nameUrdu = profile['name_urdu'] ?? '';
    final nameEnglish = profile['name_english'] ?? '';
    final address = profile['address'] ?? '';
    final primaryPhone = profile['phone_primary'] ?? '';
    final secondaryPhone = profile['phone_secondary'] ?? '';

    _syncIfPristine(_nameUrduController, nameUrdu,
        (v) => _lastSyncedNameUrdu = v, _lastSyncedNameUrdu);
    _syncIfPristine(_nameEnglishController, nameEnglish,
        (v) => _lastSyncedNameEnglish = v, _lastSyncedNameEnglish);
    _syncIfPristine(_addressController, address, (v) => _lastSyncedAddress = v,
        _lastSyncedAddress);
    _syncIfPristine(_primaryPhoneController, primaryPhone,
        (v) => _lastSyncedPrimaryPhone = v, _lastSyncedPrimaryPhone);
    _syncIfPristine(_secondaryPhoneController, secondaryPhone,
        (v) => _lastSyncedSecondaryPhone = v, _lastSyncedSecondaryPhone);
  }

  void _syncIfPristine(
    TextEditingController controller,
    String incomingValue,
    ValueChanged<String> updateLastSynced,
    String previousSynced,
  ) {
    if (controller.text == incomingValue) {
      updateLastSynced(incomingValue);
      return;
    }

    final isPristine =
        controller.text.isEmpty || controller.text == previousSynced;
    if (isPristine) {
      controller.text = incomingValue;
      updateLastSynced(incomingValue);
    }
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
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context)!;
    final nameUrdu = _nameUrduController.text.trim();
    final nameEnglish = _nameEnglishController.text.trim();
    final address = _addressController.text.trim();
    final primaryPhone = _primaryPhoneController.text.trim();
    final secondaryPhone = _secondaryPhoneController.text.trim();

    final phoneError = Validators.validatePhone(primaryPhone, loc) ??
        (primaryPhone.isEmpty ? loc.fieldRequired(loc.primaryPhone) : null);

    if (phoneError != null) {
      setState(() {
        _primaryPhoneError = phoneError;
      });
      return;
    }

    if (_primaryPhoneError != null) {
      setState(() {
        _primaryPhoneError = null;
      });
    }

    context.read<SettingsCubit>().updateShopProfile({
      'name_urdu': nameUrdu,
      'name_english': nameEnglish,
      'address': address,
      'phone_primary': primaryPhone,
      'phone_secondary': secondaryPhone,
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.shopProfile != current.shopProfile,
      listener: (context, state) {
        _syncControllersFromProfile(state.shopProfile);
      },
      child: SingleChildScrollView(
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
                            child: Icon(Icons.store,
                                size: 50, color: colorScheme.primary),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              radius: 18,
                              child: const IconButton(
                                icon: Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                                onPressed: null,
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
                            forceErrorText: _primaryPhoneError,
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .fieldRequired(loc.primaryPhone);
                              }
                              return Validators.validatePhone(trimmed, loc);
                            },
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
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacingMedium),
                  ),
                ),
              ),
            ],
          ),
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
    String? forceErrorText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      forceErrorText: forceErrorText,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                  ? AppLocalizations.of(context)!.fieldRequired(label)
                  : null
              : null),
    );
  }
}
