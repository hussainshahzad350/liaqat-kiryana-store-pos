import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('validateNotEmpty', () {
      test('should return error message when value is null', () {
        final result = Validators.validateNotEmpty(null, 'Field');
        expect(result, 'Field is required');
      });

      test('should return error message when value is empty', () {
        final result = Validators.validateNotEmpty('', 'Field');
        expect(result, 'Field is required');
      });

      test('should return error message when value is only whitespace', () {
        final result = Validators.validateNotEmpty('   ', 'Field');
        expect(result, 'Field is required');
      });

      test('should return null when value is valid', () {
        final result = Validators.validateNotEmpty('valid', 'Field');
        expect(result, null);
      });
    });

    group('validatePhone', () {
      test('should return null when value is null (optional)', () {
        final result = Validators.validatePhone(null);
        expect(result, null);
      });

      test('should return null when value is empty (optional)', () {
        final result = Validators.validatePhone('');
        expect(result, null);
      });

      test('should return error message when number is too short', () {
        final result = Validators.validatePhone('123456789'); // 9 digits
        expect(result, 'Invalid phone number');
      });

      test('should return null when number is 10 digits', () {
        final result = Validators.validatePhone('1234567890');
        expect(result, null);
      });

      test('should return null when number is more than 10 digits', () {
        final result = Validators.validatePhone('12345678901');
        expect(result, null);
      });

      test('should ignore non-digit characters in validation', () {
        final result = Validators.validatePhone('(123) 456-7890');
        expect(result, null);
      });
      
      test('should return error message when stripped value is too short', () {
        final result = Validators.validatePhone('(123) 456');
        expect(result, 'Invalid phone number');
      });
    });
  });
}
