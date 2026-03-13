import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/utils/validators.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';

// Mock AppLocalizations for testing
class MockAppLocalizations implements AppLocalizations {
  @override
  String fieldRequired(String field) => '$field is required';

  @override
  String get invalidPhone => 'Invalid phone number';

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final mockLoc = MockAppLocalizations();

  group('Validators Tests', () {
    group('validateNotEmpty', () {
      test('should return error message when value is null', () {
        final result = Validators.validateNotEmpty(null, 'Field', mockLoc);
        expect(result, 'Field is required');
      });

      test('should return error message when value is empty', () {
        final result = Validators.validateNotEmpty('', 'Field', mockLoc);
        expect(result, 'Field is required');
      });

      test('should return error message when value is only whitespace', () {
        final result = Validators.validateNotEmpty('   ', 'Field', mockLoc);
        expect(result, 'Field is required');
      });

      test('should return null when value is valid', () {
        final result = Validators.validateNotEmpty('valid', 'Field', mockLoc);
        expect(result, null);
      });
    });

    group('validatePhone', () {
      test('should return null when value is null (optional)', () {
        final result = Validators.validatePhone(null, mockLoc);
        expect(result, null);
      });

      test('should return null when value is empty (optional)', () {
        final result = Validators.validatePhone('', mockLoc);
        expect(result, null);
      });

      test('should return error message when number is too short', () {
        final result =
            Validators.validatePhone('123456789', mockLoc); // 9 digits
        expect(result, 'Invalid phone number');
      });

      test('should return null when number is 10 digits', () {
        final result = Validators.validatePhone('1234567890', mockLoc);
        expect(result, null);
      });

      test('should return null when number is 11 digits', () {
        final result = Validators.validatePhone('12345678901', mockLoc);
        expect(result, null);
      });

      test('should return error message when number is more than 11 digits',
          () {
        final result = Validators.validatePhone('123456789012', mockLoc);
        expect(result, 'Invalid phone number');
      });

      test('should ignore non-digit characters in validation', () {
        final result = Validators.validatePhone('(123) 456-7890', mockLoc);
        expect(result, null);
      });

      test('should return error message when stripped value is too short', () {
        final result = Validators.validatePhone('(123) 456', mockLoc);
        expect(result, 'Invalid phone number');
      });
    });
  });
}
