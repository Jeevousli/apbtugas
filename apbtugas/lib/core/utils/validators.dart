class AppValidators {
  AppValidators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validateNik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK tidak boleh kosong';
    }
    final nikRegex = RegExp(r'^\d{8,16}$');
    if (!nikRegex.hasMatch(value.trim())) {
      return 'NIK harus terdiri dari 8-16 digit angka';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? validateEmailOrNik(String? value, bool isEmailMode) {
    if (isEmailMode) {
      return validateEmail(value);
    } else {
      return validateNik(value);
    }
  }

  static bool isEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value.trim());
  }

  static bool isNik(String value) {
    final nikRegex = RegExp(r'^\d{8,16}$');
    return nikRegex.hasMatch(value.trim());
  }
}
