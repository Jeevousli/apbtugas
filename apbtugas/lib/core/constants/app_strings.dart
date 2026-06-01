class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'APB Connect';
  static const String appTagline = 'Connecting People, Building Safety';
  static const String appVersion = '1.0.0';

  // Auth Screens
  static const String loginTitle = 'Selamat Datang';
  static const String loginSubtitle = 'Masuk ke akun APB Connect Anda';
  static const String loginWithEmail = 'Login dengan Email';
  static const String loginWithNik = 'Login dengan NIK';
  static const String emailOrNikLabel = 'Email / NIK';
  static const String emailLabel = 'Email';
  static const String nikLabel = 'NIK (Nomor Induk Karyawan)';
  static const String passwordLabel = 'Password';
  static const String rememberMe = 'Ingat Saya';
  static const String forgotPassword = 'Lupa Password?';
  static const String loginButton = 'Masuk';
  static const String loginLoading = 'Sedang Masuk...';

  // Forgot Password
  static const String forgotPasswordTitle = 'Reset Password';
  static const String forgotPasswordSubtitle =
      'Masukkan email Anda untuk menerima link reset password';
  static const String sendResetLink = 'Kirim Link Reset';
  static const String backToLogin = 'Kembali ke Login';
  static const String resetEmailSent = 'Email reset password telah dikirim!';
  static const String checkEmailHint =
      'Silakan cek inbox atau folder spam Anda';

  // Dashboard
  static const String dashboardTitle = 'Dashboard';
  static const String welcomeBack = 'Selamat datang kembali,';
  static const String adminRole = 'Administrator';
  static const String employeeRole = 'Karyawan';
  static const String logout = 'Keluar';
  static const String logoutConfirm = 'Apakah Anda yakin ingin keluar?';
  static const String logoutButton = 'Keluar';
  static const String cancelButton = 'Batal';

  // Admin Dashboard
  static const String totalEmployees = 'Total Karyawan';
  static const String activeToday = 'Aktif Hari Ini';
  static const String pendingApproval = 'Menunggu Persetujuan';
  static const String manageEmployees = 'Kelola Karyawan';
  static const String reports = 'Laporan';
  static const String addEmployee = 'Tambah Karyawan';
  static const String settings = 'Pengaturan';

  // Employee Dashboard
  static const String myProfile = 'Profil Saya';
  static const String attendance = 'Absensi';
  static const String notifications = 'Notifikasi';
  static const String announcements = 'Pengumuman';

  // Validation Messages
  static const String emailRequired = 'Email tidak boleh kosong';
  static const String emailInvalid = 'Format email tidak valid';
  static const String nikRequired = 'NIK tidak boleh kosong';
  static const String nikInvalid = 'NIK harus terdiri dari 8-16 digit angka';
  static const String passwordRequired = 'Password tidak boleh kosong';
  static const String passwordMinLength = 'Password minimal 6 karakter';

  // Error Messages
  static const String loginFailed = 'Login gagal';
  static const String userNotFound = 'Akun tidak ditemukan';
  static const String wrongPassword = 'Password salah';
  static const String nikNotFound = 'NIK tidak terdaftar dalam sistem';
  static const String networkError = 'Koneksi internet bermasalah';
  static const String unknownError = 'Terjadi kesalahan. Coba lagi.';
  static const String tooManyRequests =
      'Terlalu banyak percobaan. Coba beberapa saat lagi.';
  static const String sessionExpired = 'Sesi telah berakhir. Silakan login ulang.';
}
