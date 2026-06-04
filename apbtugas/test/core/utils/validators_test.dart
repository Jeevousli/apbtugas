import 'package:flutter_test/flutter_test.dart';
import 'package:apbtugas/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    group('validateEmail', () {
      test('should return error if email is null', () {
        final result = AppValidators.validateEmail(null);
        expect(result, 'Email tidak boleh kosong');
      });

      test('should return error if email is empty', () {
        final result = AppValidators.validateEmail('');
        expect(result, 'Email tidak boleh kosong');
      });

      test('should return error if email format is invalid', () {
        final result = AppValidators.validateEmail('invalidemail');
        expect(result, 'Format email tidak valid');
      });

      test('should return null if email format is valid', () {
        final result = AppValidators.validateEmail('test@example.com');
        expect(result, isNull);
      });
    });

    group('validateNik', () {
      test('should return error if NIK is null', () {
        final result = AppValidators.validateNik(null);
        expect(result, 'NIK tidak boleh kosong');
      });

      test('should return error if NIK contains letters', () {
        final result = AppValidators.validateNik('1234567A');
        expect(result, 'NIK harus terdiri dari 8-16 digit angka');
      });

      test('should return error if NIK is too short', () {
        final result = AppValidators.validateNik('1234567');
        expect(result, 'NIK harus terdiri dari 8-16 digit angka');
      });

      test('should return null if NIK is valid', () {
        final result = AppValidators.validateNik('1234567890123456');
        expect(result, isNull);
      });
    });

    group('validatePassword', () {
      test('should return error if password is null', () {
        final result = AppValidators.validatePassword(null);
        expect(result, 'Password tidak boleh kosong');
      });

      test('should return error if password is too short', () {
        final result = AppValidators.validatePassword('12345');
        expect(result, 'Password minimal 6 karakter');
      });

      test('should return null if password is valid', () {
        final result = AppValidators.validatePassword('password123');
        expect(result, isNull);
      });
    });
  });
}
