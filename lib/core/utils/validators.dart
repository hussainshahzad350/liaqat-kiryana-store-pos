import '../../../l10n/app_localizations.dart';

class Validators {
  Validators._();

  static String? validateNotEmpty(
      String? value, String fieldName, AppLocalizations loc) {
    if (value == null || value.trim().isEmpty) {
      return loc.fieldRequired(fieldName);
    }
    return null;
  }

  static String? validatePhone(String? value, AppLocalizations loc) {
    if (value == null || value.isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!RegExp(r'^\d{10,11}$').hasMatch(digits)) {
      return loc.invalidPhone;
    }
    return null;
  }
}
