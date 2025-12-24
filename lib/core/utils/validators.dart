class Validators {
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^\d{10,}$').hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
      return 'Invalid phone number';
    }
    return null;
  }
}